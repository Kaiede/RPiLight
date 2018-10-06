/*
 RPiLight

 Copyright (c) 2018 Adam Thayer
 Licensed under the MIT license, as follows:

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.)
 */

import Dispatch
import Foundation
import Logging
import PWM

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public typealias StopClosure = (LightController) -> Void

public enum LightControllerError: Error {
    case missingToken(String)
}

//
// Wrapper for Configuration that's compatible with Layers
//
struct ChannelPoint: LayerPoint {
    var time: DateComponents {
        return self.event.time
    }
    
    var brightness: Double {
        return self.event.setting.asBrightness(withGamma: self.channel.gamma)
    }
    
    private let channel: Channel
    private let event: ChannelPointConfig
    
    init(channel: Channel, event: ChannelPointConfig) {
        self.channel = channel
        self.event = event
    }
}

//
// The Light Controller
//
public class LightController: BehaviorController {
    typealias LightControllerTimer = Timer<TimerID>
    enum TimerID {
        case refresh
        case watchdog
        case event
    }

    public let channelControllers: [String: BehaviorChannel]

    private var eventControllers: [EventId: EventController]
    private var nextEvent: EventId?

    private let queue: DispatchQueue
    private var refreshTimer: LightControllerTimer
    private var eventTimer: LightControllerTimer

    private var watchdogTimer: LightControllerTimer
    private var watchdogInterval: TimeInterval
    private var watchdogLastRefresh: Date

    private var behavior: [Behavior]
    private var isRunning: Bool
    private var isRefreshOneShot: Bool
    private var stopClosure: StopClosure?

    init(channelControllers: [String: BehaviorChannel], behavior: Behavior) {
        // Set the initial behavior
        self.behavior = [behavior]
        self.stopClosure = nil

        // Configure Dispatch Queue
        self.queue = DispatchQueue(label: "rpilight.controller",
                                   qos: .userInitiated,
                                   attributes: [],
                                   autoreleaseFrequency: .inherit,
                                   target: nil)
        self.isRunning = false
        self.isRefreshOneShot = false
        self.refreshTimer = LightControllerTimer(identifier: .refresh, queue: self.queue)

        self.watchdogTimer = LightControllerTimer(identifier: .watchdog, queue: self.queue)
        self.watchdogInterval = TimeInterval.infinity
        self.watchdogLastRefresh = Date.distantPast

        self.eventTimer = LightControllerTimer(identifier: .event, queue: self.queue)
        self.nextEvent = nil

        self.eventControllers = [:]

        // Copy the channel controllers
        self.channelControllers = channelControllers
        
        // Attach the channel controllers to self
        for var channelController in self.channelControllers.values {
            channelController.rootController = self
        }

        // Configure the handlers now that self is initialized.
        self.refreshTimer.setHandler { self.fireRefresh() }
        self.watchdogTimer.setHandler { self.fireWatchdog() }
        self.eventTimer.setHandler { self.fireEvent() }
    }
    
    public convenience init(channels: [Channel],
                            withConfig config: [ChannelConfig],
                            behavior: Behavior = DefaultLightBehavior()) throws {
        
        // Convert the array into a lookup
        let channelDict = channels.reduce([String: Channel]()) { (dict, channel) -> [String: Channel] in
            var dict = dict
            dict[channel.token] = channel
            return dict
        }
        
        // Configure each channel
        let now = Date()
        var channelControllers: [String: ChannelController] = [:]
        for channelConfig in config {
            guard let channel = channelDict[channelConfig.token] else {
                throw LightControllerError.missingToken(channelConfig.token)
            }
            
            let controller = ChannelController(channel: channel)
            channelControllers[channelConfig.token] = controller
            
            let points = channelConfig.schedule.map({ ChannelPoint(channel: channel, event: $0 ) })
            let layer = Layer(identifier: "Schedule", points: points, startTime: now)
            controller.set(layer: layer)
        }
        
        self.init(channelControllers: channelControllers, behavior: behavior)
    }
    
    deinit {
        self.stopInternal()
    }

    public func push(behavior: Behavior) {
        // TODO: We should add something to avoid multiple pushes
        self.behavior.append(behavior)
        self.invalidateRefreshTimer()
    }

    public func pop(behavior: Behavior) {
        // TODO: This should be a bit better about popping unexpected behaviors
        guard self.behavior.count > 1 else {
            Log.warn("Attempted to remove the primary behavior from the Light Controller")
            return
        }

        self.behavior.removeLast()
        self.invalidateRefreshTimer()
    }

    public func setEvent(controller: EventController) {
        self.queue.async {
            self.eventControllers[controller.token] = controller

            if self.isRunning {
                let now = Date()
                if (controller.firesOnStart) {
                    controller.fire(forController: self, date: now)
                }
                self.scheduleEvent(forDate: now)
            }
        }
    }
    
    public func start() {
        self.queue.async {
            Log.info("Starting Light Controller")
            self.isRunning = true
            self.isRefreshOneShot = true
            self.fireRefresh()
            let now = Date()
            self.fireStartupEvents(forDate: now)
            self.scheduleEvent(forDate: now)
        }
    }
    
    public func setStopHandler(_ closure: StopClosure?) {
        self.queue.async {
            self.stopClosure = closure
        }
    }
    
    public func stop() {
        self.queue.async {
            self.stopInternal()
        }
    }
    
    public func invalidateRefreshTimer() {
        self.queue.async {
            if self.isRunning {
                let now = Date()
                self.scheduleRefresh(forDate: now)
            }
        }
    }

    private func fireStartupEvents(forDate date: Date) {
        for controller in self.eventControllers.values where controller.firesOnStart {
            controller.fire(forController: self, date: date)
        }
    }

    private func fireWatchdog() {
        let now = Date()
        Log.info("Watchdog Timer Fired: \(Log.dateFormatter.string(from: now))")

        let interval = now.timeIntervalSince(self.watchdogLastRefresh)
        if interval > self.watchdogInterval {
            let expectedRefresh = self.watchdogLastRefresh.addingTimeInterval(self.watchdogInterval)
            Log.warn("Late Refresh Detected. Expected Refresh @ \(Log.dateFormatter.string(from: expectedRefresh))")
        }

        self.invalidateRefreshTimer()
    }

    private func fireEvent() {
        guard let eventToken = self.nextEvent else {
            Log.warn("Event handler fired without an event token")
            return
        }

        if let event = self.eventControllers[eventToken] {
            let now = Date()
            Log.info("Firing Event: \(eventToken)")
            event.fire(forController: self, date: now)
            self.scheduleEvent(forDate: now)
        } else {
            Log.error("Event \"\(eventToken)\" not found.")
        }
    }

    private func fireRefresh() {
        Log.debug("Light Controller Refresh")
        let now = Date()
        guard var currentBehavior = self.behavior.last else {
            Log.error("There must be at least one active behavior in the Light Controller")
            return
        }
        currentBehavior.refresh(controller: self, forDate: now)
        
        if self.isRefreshOneShot {
            Log.debug("Light Controller One Shot Rescheduling")
            self.scheduleRefresh(forDate: now)
        }
    }
    
    private func stopInternal() {
        Log.info("Stopping Light Controller")
        if self.isRunning {
            self.isRunning = false
            self.refreshTimer.pause()
            self.stopEventInternal()
            DispatchQueue.main.async { [weak self] in
                if let controller = self {
                    controller.stopClosure?(controller)
                }
            }
        } else {
            Log.warn("Light Controller Stopped While Not Running")
        }
    }

    private func stopEventInternal() {
        self.eventTimer.pause()
    }
    
    private func scheduleRefresh(forDate now: Date) {
        guard let currentBehavior = self.behavior.last else {
            Log.error("There must be at least one active behavior in the Light Controller")
            return
        }

        let segment = currentBehavior.segment(forController: self, date: now)
        switch segment.nextUpdate {
        case .stop:
            Log.info("Stopping Light Controller")
            self.stopInternal()
        case .oneShot(let restartDate):
            self.isRefreshOneShot = true
            self.refreshTimer.schedule(at: restartDate)
            Log.debug("Scheduling Behavior: \(Log.dateFormatter.string(from: restartDate))")

            self.watchdogInterval = restartDate.timeIntervalSince(now)
            self.watchdogLastRefresh = now
        case .repeating(let restartDate, let updateInterval):
            self.isRefreshOneShot = false
            self.refreshTimer.schedule(startingAt: restartDate, repeating: updateInterval)
            Log.withDebug {
                let intervalMs = updateInterval.toTimeInterval() * 1_000.0
                Log.debug("Scheduling Behavior: \(Log.dateFormatter.string(from: restartDate)) : \(intervalMs) ms")
            }

            self.watchdogInterval = updateInterval.toTimeInterval()
            self.watchdogLastRefresh = now
        }

        if segment.endDate != Date.distantFuture {
            self.watchdogTimer.schedule(at: segment.endDate)
            Log.info("New Watchdog Timer: \(Log.dateFormatter.string(from: segment.endDate))")
        } else {
            self.watchdogTimer.pause()
        }
    }

    private func scheduleEvent(forDate now: Date) {
        guard !self.eventControllers.isEmpty else {
            Log.info("Scheduling no event")
            self.stopEventInternal()
            return
        }

        let calcDates = self.eventControllers.map { (key, value) -> (EventId, Date) in
            guard let calculatedDate = value.time.calcNextDate(after: now) else {
                fatalError("Could not calculate next time \(value.time), after date \(now)")
            }
            return (key, calculatedDate)
        }
        if let result = calcDates.min(by: { $0.1 < $1.1 }) {
            let token = result.0
            let eventDate = result.1

            self.nextEvent = token
            self.eventTimer.schedule(at: eventDate)
            Log.info("Next Event: \(token) (\(Log.dateFormatter.string(from: eventDate)))")
        } else {
            Log.error("Unable to schedule next event")
        }
    }
}
