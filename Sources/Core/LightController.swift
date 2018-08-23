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
    public let channelControllers: [String: BehaviorChannel]

    private var eventControllers: [EventId: EventController]
    private var nextEvent: EventId?

    private let queue: DispatchQueue
    private var refreshTimer: DispatchSourceTimer?
    private var eventTimer: DispatchSourceTimer?

    private var behavior: Behavior
    private var isRunning: Bool
    private var isRefreshOneShot: Bool
    private var stopClosure: StopClosure?

    init(channelControllers: [String: BehaviorChannel], behavior: Behavior) {
        // Set the initial behavior
        self.behavior = behavior
        self.stopClosure = nil

        // Configure Dispatch Queue
        self.queue = DispatchQueue(label: "rpilight.controller",
                                   qos: .userInitiated,
                                   attributes: [],
                                   autoreleaseFrequency: .inherit,
                                   target: nil)
        self.isRunning = false
        self.isRefreshOneShot = false
        self.refreshTimer = nil

        self.eventTimer = nil
        self.nextEvent = nil

        self.eventControllers = [:]

        // Copy the channel controllers
        self.channelControllers = channelControllers
        
        // Attach the channel controllers to self
        for var channelController in self.channelControllers.values {
            channelController.rootController = self
        }
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
            
            let points = channelConfig.schedule.map({ ChannelPoint(channel: channel, event: $0 )})
            let layer = Layer(identifier: "Schedule", points: points, startTime: now)
            controller.set(layer: layer)
        }
        
        self.init(channelControllers: channelControllers, behavior: behavior)
    }
    
    deinit {
        self.stopInternal()
    }

    public func setEvent(controller: EventController) {
        self.queue.async {
            self.eventControllers[controller.token] = controller
            self.scheduleEvent(forDate: Date())
        }
    }
    
    public func start() {
        self.queue.async {
            self.isRunning = true
            self.isRefreshOneShot = true
            self.refresh()
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

    private func refresh() {
        let now = Date()
        self.behavior.refresh(controller: self, forDate: now)
        
        if self.isRefreshOneShot {
            self.scheduleRefresh(forDate: now)
        }
    }
    
    private func stopInternal() {
        if self.isRunning {
            self.isRunning = false
            if let oldTimer = self.refreshTimer {
                self.refreshTimer = nil
                oldTimer.cancel()
            }
            DispatchQueue.main.async { [weak self] in
                if let controller = self {
                    controller.stopClosure?(controller)
                }
            }
        }

        if let eventTimer = self.eventTimer {
            self.eventTimer = nil
            eventTimer.cancel()
        }
    }
    
    private func scheduleRefresh(forDate now: Date) {
        if let oldTimer = self.refreshTimer {
            oldTimer.cancel()
        }
        
        let update = self.behavior.nextUpdate(forController: self, forDate: now)
        switch update {
        case .stop:
            Log.info("Stopping Light Controller")
            self.stopInternal()
            return
        case .oneShot(let restartDate):
            let refreshTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
            refreshTimer.schedulePrecise(forDate: restartDate)
            self.refreshTimer = refreshTimer
            self.isRefreshOneShot = true
            Log.debug("Scheduling Behavior: \(Log.dateFormatter.string(from: restartDate))")
        case .repeating(let restartDate, let updateInterval):
            let refreshTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
            refreshTimer.schedulePrecise(forDate: restartDate, everyMilliseconds: updateInterval)
            self.refreshTimer = refreshTimer
            self.isRefreshOneShot = false
            Log.debug("Scheduling Behavior: \(Log.dateFormatter.string(from: restartDate)) : \(updateInterval) ms")
        }
        
        self.refreshTimer?.setEventHandler {
            [weak self] in
            self?.refresh()
        }
        self.refreshTimer?.resume()
    }

    private func scheduleEvent(forDate now: Date) {
        guard !self.eventControllers.isEmpty else {
            Log.info("Scheduling no event")
            self.stopEventInternal()
            return
        }

        let calcDates = self.eventControllers.map { (key, value) -> (EventId, Date) in
            return (key, value.time.calcNextDate(after: now)!)
        }
        if let result = calcDates.min(by: { $0.1 < $1.1 }) {
            let token = result.0
            let eventDate = result.1

            let eventTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
            eventTimer.schedulePrecise(forDate: eventDate)
            eventTimer.setEventHandler {
                [weak self] in
                self?.fireEvent()
            }

            Log.info("Next Event: \(token) (\(Log.dateFormatter.string(from: eventDate)))")
            self.eventTimer = eventTimer
            self.nextEvent = token
        } else {
            Log.error("Unable to schedule next event")
        }
    }
}
