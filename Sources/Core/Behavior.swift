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

import Foundation

import Logging

public enum LightBehaviorUpdate {
    // Stop the controller
    case stop
    
    // Do a one-shot update at date
    case oneShot(Date)
    
    // Do repeating updates starting at date
    case repeating(Date, Int)
}

public protocol BehaviorChannel {
    var rootController: BehaviorController? { get set }
    
    func update(forDate date: Date)
    func rateOfChange(forDate date: Date) -> ChannelRateOfChange
}

public protocol BehaviorController {
    var channelControllers: [String: BehaviorChannel] { get }
    
    func invalidateRefreshTimer()
}

public protocol Behavior {
    func refresh(controller: BehaviorController, forDate date: Date)
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
    
    
    public func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        let secondsSinceStart = date.timeIntervalSince(self.startDate)
        
        if secondsSinceStart >= 60.0 {
            return .stop
        }
        
        return .repeating(date, 10)
    }
}

public struct DefaultLightBehavior: Behavior {
    public init() {}
    
    public func refresh(controller: BehaviorController, forDate date: Date) {
        for (_, channelController) in controller.channelControllers {
            channelController.update(forDate: date)
        }
    }
    
    public func nextUpdate(forController controller: BehaviorController, forDate date: Date) -> LightBehaviorUpdate {
        let minChangeRate: Double = 0.0001
        let targetChanges: Double = 4096
        
        var shouldSleep: Bool = true
        var brightnessRate: Double = 0.0
        var segmentStart: Date = Date.distantFuture
        var segmentEnd: Date = Date.distantFuture
        for channelController in controller.channelControllers.values {
            let (channelBrightnessRate, channelSegmentStart, channelSegmentEnd) = channelController.rateOfChange(forDate: date)
            shouldSleep = shouldSleep && (channelBrightnessRate < minChangeRate)
            brightnessRate = max(brightnessRate, channelBrightnessRate)
            segmentStart = min(segmentStart, channelSegmentStart)
            segmentEnd = min(segmentEnd, channelSegmentEnd)
        }
        
        let updatesPerSec = min(100.0, brightnessRate * targetChanges)
        
        if shouldSleep {
            return .oneShot(segmentEnd)
        }
        
        return .repeating(segmentStart, Int(1000.0 / updatesPerSec))
    }
}
