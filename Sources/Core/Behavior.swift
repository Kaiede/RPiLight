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
    var gamma: Double { get }
    var setting: ChannelSetting { get set }
    var rootController: BehaviorController? { get set }

    func set(layer: ChannelLayer, forType type: ChannelLayerType)
    func update(forDate date: Date)
    func segment(forDate date: Date) -> ChannelSegment
}

public protocol BehaviorController {
    var channelControllers: [String: BehaviorChannel] { get }
    
    func invalidateRefreshTimer()
}

public protocol Behavior {
    mutating func refresh(controller: BehaviorController, forDate date: Date)
    func segment(forController controller: BehaviorController, date: Date) -> LightBehaviorSegment
    func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate
}

extension Behavior {
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
        let finalInterval: DispatchTimeInterval = interval < 1000.0 ? .microseconds(Int(interval * 1_000_000.0)) : .milliseconds(Int(interval * 1_000.0))

        return LightBehaviorSegment(segment: mergedSegment, update: .repeating(mergedSegment.startDate, finalInterval))
    }

    public func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        let segment = self.segment(forController: controller, date: date)
        return segment.nextUpdate
    }
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
    
    public mutating func refresh(controller: BehaviorController, forDate date: Date) {
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

        return LightBehaviorSegment(segment: mergedSegment, update: self.nextUpdate(forController: controller, forDate: date))
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
    
    public mutating func refresh(controller: BehaviorController, forDate date: Date) {
        for (_, channelController) in controller.channelControllers {
            channelController.update(forDate: date)
        }
    }
}

public struct StormLightBehavior: Behavior {
    private let fadeTime: UInt32 = 100 // ms
    private var lastStrike: Date
    private var nextStrike: Date
    private let strength: Double


    public init(strength: Double, stormStart: Date) {
        self.strength = strength
        self.lastStrike = stormStart
        self.nextStrike = stormStart
        calcNextStrike()
    }

    public mutating func refresh(controller: BehaviorController, forDate date: Date) {
        for (_, channelController) in controller.channelControllers {
            channelController.update(forDate: date)
        }

        // TODO: Calculate If We Flash
        if date >= nextStrike {
            let flashes = UInt32.random(in: 3...6)
            Log.info("Starting Flash: \(flashes) flashes")
            doFlashesWithFade(controller: controller, count: flashes)

            lastStrike = date
            calcNextStrike()
        }
    }

    private mutating func calcNextStrike() {
        // Strikes happen anywhere between 15 - 60 seconds at full strength.
        // Strikes happen anywhere between 2.5 - 10 minutes at minimum strength.
        let strikeFactor: Double = 1.0 + 9.0*(1.0 - strength)
        let minStrikeInterval: Double = 15.0 * strikeFactor
        let maxStrikeInterval: Double = 60.0 * strikeFactor
        let nextStrikeInterval: TimeInterval = Double.random(in: minStrikeInterval...maxStrikeInterval)

        self.nextStrike = self.lastStrike.addingTimeInterval(nextStrikeInterval)
    }

    private func doFlashesWithFade(controller: BehaviorController, count: UInt32) {
        let channelIntensities = controller.channelControllers.mapValues({ $0.setting.asIntensity(withGamma: $0.gamma) })
        guard let minIntensity = channelIntensities.values.max() else {
            Log.error("Unable to calculate storm intensity")
            return
        }

        let burstIntensity = Double.random(in: minIntensity...1.0)
        Log.debug("Burst Intensity: \(burstIntensity)")
        for index in 1...count {
            // Start Flash
            for var channel in controller.channelControllers.values {
                channel.setting = .intensity(burstIntensity)
            }

            // Wait for burst to finish
            let burstTime = UInt32.random(in: 5...20)
            usleep(burstTime * 1000)

            // Fade
            let steps = index == count ? fadeTime : UInt32.random(in: 40...125)
            for step in 1...steps {
                let currentBrightness = max(0.0, burstIntensity - (Double(step) / Double(fadeTime)))
                let currentBrightnessSetting = ChannelSetting.brightness(currentBrightness)

                for (token, var channel) in controller.channelControllers {
                    guard let baseIntensity = channelIntensities[token] else {
                        Log.error("Channel not found: \(token)")
                        continue
                    }
                    channel.setting = .intensity(max(currentBrightnessSetting.asIntensity(withGamma: 2.5), baseIntensity))
                }
                usleep(1000)
            }
        }
    }
}
