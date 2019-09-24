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
import LED

public enum EventId: Hashable, Equatable {
    case lunar
    case storm(Int)
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

    public convenience init(schedule: LunarSchedule) {
        self.init(startTime: schedule.startTime, endTime: schedule.endTime)
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
            let desiredTransitionTime: TimeInterval = 60.0 * 5.0
            let gamma = channelController.gamma
            let layer = Layer(identifier: "Lunar",
                              dimmingStart: nightStart,
                              end: nightEnd,
                              brightnessFactorStart: intensityFactorStart.asBrightness(withGamma: gamma),
                              end: intensityFactorEnd.asBrightness(withGamma: gamma),
                              transitionTime: desiredTransitionTime)

            channelController.set(layer: layer, forType: .lunar)
        }
    }
}

//
// MARK: Storm Events
//
public class StormEventController: EventController {
    private static let randomRange: UInt32 = 1_000_000
    
    public let token: EventId
    public let firesOnStart: Bool = false

    public var time: DateComponents
    private let endTime: DateComponents
    private let lightningStrength: Double
    private let chance: UInt32
    
    public static func loadMultiple(events: [StormEvent]) -> [StormEventController] {
        return events.enumerated().map({ return StormEventController(index: $0.offset, config: $0.element) })
    }
    
    public convenience init(index: Int, config: StormEvent) {
        self.init(index: index, start: config.startTime, end: config.endTime, strength: config.lightningStrength, chance: config.chance)
    }
    
    init(index: Int, start: DateComponents, end: DateComponents, strength: Double, chance: Double) {
        self.token = .storm(index)
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
        
        Log.info("Skies are dark. Incoming Storm.")
        Log.warn("Implementation Not Complete.")

        // Provide dimming, similar to lunar cycle
        guard let stormStart = time.calcNextDate(after: date, direction: .backward) else {
            Log.error("Unable to calculate when lunar night begins")
            return
        }
        guard let stormEnd = endTime.calcNextDate(after: stormStart) else {
            Log.error("Unable to calculate when lunar night ends")
            return
        }

        let intensityFactor: ChannelSetting = .intensity(0.5)
        for channelController in controller.channelControllers.values {
            let desiredTransitionTime: TimeInterval = 60.0 * 1.5
            let brightnessFactor = intensityFactor.asBrightness(withGamma: channelController.gamma)
            let stormLayer = Layer(identifier: "Storm",
                                   dimmingStart: stormStart,
                                   end: stormEnd,
                                   brightnessFactor: brightnessFactor,
                                   transitionTime: desiredTransitionTime)

            channelController.set(layer: stormLayer, forType: .storm)
        }

        // Configure the behavior that provides the lightning.
        let behavior = StormLightBehavior(strength: self.lightningStrength, stormStart: stormStart, end: stormEnd)
        controller.push(behavior: behavior)
    }
}

//
// MARK: Dimming Layer Creation
//

struct SimpleLayerPoint: LayerPoint {
    let time: DateComponents
    let brightness: Double
}

extension Layer {
    convenience init(identifier: String, dimmingStart: Date, end dimmingEnd: Date, brightnessFactorStart brightnessStart: Double, end brightnessEnd: Double, transitionTime: TimeInterval) {
        let dimmingInterval = dimmingEnd.timeIntervalSince(dimmingStart)
        let transitionInterval: TimeInterval = dimmingInterval > transitionTime * 2 ? transitionTime : dimmingInterval / 2.0

        let dimmingFullStart = dimmingStart.addingTimeInterval(transitionInterval)
        let dimmingFullEnd = dimmingEnd.addingTimeInterval(-transitionInterval)

        let calendar = Calendar.current
        let dimStartPoint = calendar.dateComponents([.hour, .minute, .second], from: dimmingStart)
        let dimFullStartPoint = calendar.dateComponents([.hour, .minute, .second], from: dimmingFullStart)
        let dimFullEndPoint = calendar.dateComponents([.hour, .minute, .second], from: dimmingFullEnd)
        let dimEndPoint = calendar.dateComponents([.hour, .minute, .second], from: dimmingEnd)

        var layerPoints: [SimpleLayerPoint] = []
        layerPoints.append(SimpleLayerPoint(time: dimStartPoint, brightness: 1.0))
        layerPoints.append(SimpleLayerPoint(time: dimFullStartPoint, brightness: brightnessStart))
        layerPoints.append(SimpleLayerPoint(time: dimFullEndPoint, brightness: brightnessEnd))
        layerPoints.append(SimpleLayerPoint(time: dimEndPoint, brightness: 1.0))
        self.init(identifier: identifier, points: layerPoints, startTime: dimmingStart)
    }

    convenience init(identifier: String, dimmingStart: Date, end dimmingEnd: Date, brightnessFactor: Double, transitionTime: TimeInterval) {
        self.init(identifier: identifier, dimmingStart: dimmingStart, end: dimmingEnd, brightnessFactorStart: brightnessFactor, end: brightnessFactor, transitionTime: transitionTime)
    }
}
