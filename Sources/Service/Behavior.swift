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
import LED

public enum LightBehaviorUpdate {
    // Stop the controller
    case stop

    // Do a one-shot update at date
    case oneShot(Date)

    // Do repeating updates starting at date
    case repeating(Date, DispatchTimeInterval)
}

public struct LightBehaviorSegment {
    let startDate: Date
    let endDate: Date
    let nextUpdate: LightBehaviorUpdate

    init(segment: ChannelSegment, update: LightBehaviorUpdate) {
        self.startDate = segment.startDate
        self.endDate = segment.endDate
        self.nextUpdate = update
    }
}

public protocol BehaviorChannel {
    var channelGamma: Double { get }
    var rootController: BehaviorController? { get set }

    func set(layer: ChannelLayer, forType type: ChannelLayerType)
    func update(forDate date: Date)
    func segment(forDate date: Date) -> ChannelSegment
}

public protocol BehaviorControllerConfig {
    var gamma: Double { get }
}

public protocol BehaviorController {
    var channelControllers: [String: BehaviorChannel] { get }
    var configuration: BehaviorControllerConfig { get }

    func invalidateRefreshTimer()
}

public protocol Behavior {
    func refresh(controller: BehaviorController, forDate date: Date)
    func segment(forController controller: BehaviorController, date: Date) -> LightBehaviorSegment
    func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate
}

public struct PreviewLightBehavior: Behavior {
    // Makes 1 Minute act like 24 Hours
    private static let speedFactor: Double = 60.0 * 24.0

    private let startDate: Date
    private let midnight: Date

    public init(startDate: Date = Date()) {
        self.startDate = startDate
        self.midnight = Calendar.current.startOfDay(for: self.startDate)
    }

    public func refresh(controller: BehaviorController, forDate date: Date) {
        let secondsSinceStart = date.timeIntervalSince(self.startDate)
        let acceleratedInterval = secondsSinceStart * PreviewLightBehavior.speedFactor

        let now = self.midnight.addingTimeInterval(acceleratedInterval)
        for (_, channelController) in controller.channelControllers {
            channelController.update(forDate: now)
        }

        if secondsSinceStart >= 60.0 {
            controller.invalidateRefreshTimer()
        }
    }

    public func segment(forController controller: BehaviorController, date: Date) -> LightBehaviorSegment {
        let secondsSinceStart = date.timeIntervalSince(self.startDate)
        let acceleratedInterval = secondsSinceStart * PreviewLightBehavior.speedFactor

        let now = self.midnight.addingTimeInterval(acceleratedInterval)

        // Use 'now' to generate the merged segment
        var mergedSegment: ChannelControllerSegment = ChannelControllerSegment()
        for channelController in controller.channelControllers.values {
            let channelSegment = channelController.segment(forDate: now)
            mergedSegment.unionByChannel(withSegment: channelSegment)
        }

        return LightBehaviorSegment(segment: mergedSegment,
                                    update: self.nextUpdate(forController: controller, forDate: date))
    }

    public func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        let secondsSinceStart = date.timeIntervalSince(self.startDate)

        if secondsSinceStart >= 60.0 {
            return .stop
        }

        return .repeating(date, .milliseconds(10))
    }
}

public struct DefaultLightBehavior: Behavior {
    public init() {}

    public func refresh(controller: BehaviorController, forDate date: Date) {
        for (_, channelController) in controller.channelControllers {
            channelController.update(forDate: date)
        }
    }

    public func segment(forController controller: BehaviorController, date: Date) -> LightBehaviorSegment {
        let minChange: Double = 0.0001
        let targetChanges: Double = 4096

        var mergedSegment: ChannelControllerSegment = ChannelControllerSegment()
        for channelController in controller.channelControllers.values {
            let channelSegment = channelController.segment(forDate: date)
            mergedSegment.unionByChannel(withSegment: channelSegment)
        }

        let shouldSleep = mergedSegment.totalBrightnessChange < minChange
        if shouldSleep {
            return LightBehaviorSegment(segment: mergedSegment, update: .oneShot(mergedSegment.endDate))
        }

        let desiredChanges = (mergedSegment.totalBrightnessChange * targetChanges).rounded(.awayFromZero)
        let desiredInterval = mergedSegment.duration / max(1.0, desiredChanges)
        let interval = min(mergedSegment.duration, max(0.010, desiredInterval))
        let finalInterval = DispatchTimeInterval(lightBehaviorSeconds: interval)

        return LightBehaviorSegment(segment: mergedSegment, update: .repeating(mergedSegment.startDate, finalInterval))
    }

    public func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        let segment = self.segment(forController: controller, date: date)
        return segment.nextUpdate
    }
}

extension DispatchTimeInterval {
    init(lightBehaviorSeconds seconds: Double) {
        if seconds < 1000.0 {
            self = .microseconds(Int(seconds * 1_000_000.0))
        } else {
            self = .milliseconds(Int(seconds * 1_000.0))
        }
    }
}
