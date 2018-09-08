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

import Ephemeris
import Logging
import PWM

public enum EventId: Equatable {
    case lunar
    case storm
}

public protocol EventController {
    var time: DateComponents { get }
    var token: EventId { get }

    var firesOnStart: Bool { get }
    func fire(forController controller: BehaviorController, date: Date)
}

//
// MARK: Lunar Cycle Events
//
public class LunarCycleController: EventController {
    public let token: EventId = .lunar
    public let firesOnStart: Bool = true

    public let time: DateComponents
    let endTime: DateComponents

    public convenience init(config: LunarConfig) {
        self.init(startTime: config.startTime, endTime: config.endTime)
    }

    init(startTime: DateComponents, endTime: DateComponents) {
        self.time = startTime
        self.endTime = endTime
    }

    public func fire(forController controller: BehaviorController, date: Date) {
        guard let nightStart = time.calcNextDate(after: date, direction: .backward) else {
            Log.error("Unable to calculate when lunar night begins")
            return
        }
        guard let nightEnd = endTime.calcNextDate(after: nightStart) else {
            Log.error("Unable to calculate when lunar night ends")
            return
        }

        let illuminationStart = Moon.fastIllumination(forDate: nightStart.toJ2000Date())
        let illuminationEnd = Moon.fastIllumination(forDate: nightEnd.toJ2000Date())
        let intensityFactorStart: ChannelSetting = .intensity(illuminationStart.fraction)
        let intensityFactorEnd: ChannelSetting = .intensity(illuminationEnd.fraction)

        Log.info("Lunar Night Period: \(Log.timeFormatter.string(from: nightStart)) -> \(Log.timeFormatter.string(from: nightEnd))")
        Log.info("Calculated Lunar Light: \(illuminationStart.fraction) -> \(illuminationEnd.fraction)")

        for channelController in controller.channelControllers.values {
            let gamma = channelController.channelGamma
            let layer = Layer(nightStart: nightStart,
                              end: nightEnd,
                              brightnessFactorStart: intensityFactorStart.asBrightness(withGamma: gamma),
                              end: intensityFactorEnd.asBrightness(withGamma: gamma))

            channelController.set(layer: layer, forType: .lunar)
        }
    }
}

struct LunarPoint: LayerPoint {
    let time: DateComponents
    let brightness: Double
}

extension Layer {
    convenience init(nightStart: Date, end nightEnd: Date, brightnessFactorStart brightnessStart: Double, end brightnessEnd: Double) {
        let desiredTransitionTime: TimeInterval = 60.0 * 5.0
        let nightInterval = nightEnd.timeIntervalSince(nightStart)
        let transitionInterval: TimeInterval = nightInterval > desiredTransitionTime * 2 ? desiredTransitionTime : nightInterval / 2.0

        let nightFullStart = nightStart.addingTimeInterval(transitionInterval)
        let nightFullEnd = nightEnd.addingTimeInterval(-transitionInterval)

        let calendar = Calendar.current
        let nightStartPoint = calendar.dateComponents([.hour, .minute, .second], from: nightStart)
        let nightFullStartPoint = calendar.dateComponents([.hour, .minute, .second], from: nightFullStart)
        let nightFullEndPoint = calendar.dateComponents([.hour, .minute, .second], from: nightFullEnd)
        let nightEndPoint = calendar.dateComponents([.hour, .minute, .second], from: nightEnd)

        var layerPoints: [LunarPoint] = []
        layerPoints.append(LunarPoint(time: nightStartPoint, brightness: 1.0))
        layerPoints.append(LunarPoint(time: nightFullStartPoint, brightness: brightnessStart))
        layerPoints.append(LunarPoint(time: nightFullEndPoint, brightness: brightnessEnd))
        layerPoints.append(LunarPoint(time: nightEndPoint, brightness: 1.0))
        self.init(identifier: "Lunar", points: layerPoints, startTime: nightStart)
    }
}

//
// MARK: Storm Events
//
public class StormEventController: EventController {
    private static let randomRange: UInt32 = 1_000_000
    
    public let token: EventId = .storm
    public let firesOnStart: Bool = false

    public var time: DateComponents
    private let endTime: DateComponents
    private let lightningStrength: Double
    private let chance: UInt32
    
    public static func loadMultiple(events: [StormEventConfig]) -> [StormEventController] {
        return events.map({ return StormEventController(config: $0) })
    }
    
    public convenience init(config: StormEventConfig) {
        self.init(start: config.startTime, end: config.endTime, strength: config.lightningStrength, chance: config.chance)
    }
    
    init(start: DateComponents, end: DateComponents, strength: Double, chance: Double) {
        self.time = start
        self.endTime = end
        self.lightningStrength = strength
        self.chance = UInt32(Double(StormEventController.randomRange) * chance)
    }
    
    public func fire(forController controller: BehaviorController, date: Date) {
        let stormCheck = UInt32.random(in: 0...StormEventController.randomRange)
        guard stormCheck < self.chance else {
            Log.info("Skies are clear. No Storm Now.")
            return
        }
        
        Log.warn("Skies are dark. But Not Yet Currently Implemented.")
    }
}
