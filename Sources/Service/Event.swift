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

public enum EventId: Equatable {
    case lunar
}

public protocol EventController {
    var time: DayTime { get }
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

    public let time: DayTime
    let endTime: DayTime

    public convenience init(schedule: LunarCycleDescription) {
        self.init(startTime: schedule.start, endTime: schedule.end)
    }

    init(startTime: DayTime, endTime: DayTime) {
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
        let intensityFactorStart = Intensity(rawValue: illuminationStart.fraction)
        let intensityFactorEnd = Intensity(rawValue: illuminationEnd.fraction)

        Log.info( {
            let startString = Log.timeFormatter.string(from: nightStart)
            let endString = Log.timeFormatter.string(from: nightEnd)
            return "Lunar Night Period: \(startString) -> \(endString)"
        }() )
        Log.info("Calculated Lunar Light: \(illuminationStart.fraction) -> \(illuminationEnd.fraction)")

        for channelController in controller.channelControllers.values {
            let gamma = channelController.channelGamma
            let layer = Layer(nightStart: nightStart,
                              end: nightEnd,
                              brightnessFactorStart: Brightness(intensityFactorStart, gamma: gamma),
                              end: Brightness(intensityFactorEnd, gamma: gamma))

            channelController.set(layer: layer, forType: .lunar)
        }
    }
}

struct LunarPoint: LayerPoint {
    let time: DayTime
    let brightness: Brightness
}

extension Layer {
    convenience init(nightStart: Date,
                     end nightEnd: Date,
                     brightnessFactorStart brightnessStart: Brightness,
                     end brightnessEnd: Brightness) {
        let desiredTransitionTime: TimeInterval = 60.0 * 5.0
        let nightInterval = nightEnd.timeIntervalSince(nightStart)
        let transitionInterval: TimeInterval = nightInterval > desiredTransitionTime * 2 ?
                                               desiredTransitionTime : nightInterval / 2.0

        let nightFullStart = nightStart.addingTimeInterval(transitionInterval)
        let nightFullEnd = nightEnd.addingTimeInterval(-transitionInterval)

        let nightStartPoint = DayTime(from: nightStart)
        let nightFullStartPoint = DayTime(from: nightFullStart)
        let nightFullEndPoint = DayTime(from: nightFullEnd)
        let nightEndPoint = DayTime(from: nightEnd)

        var layerPoints: [LunarPoint] = []
        layerPoints.append(LunarPoint(time: nightStartPoint, brightness: 1.0))
        layerPoints.append(LunarPoint(time: nightFullStartPoint, brightness: brightnessStart))
        layerPoints.append(LunarPoint(time: nightFullEndPoint, brightness: brightnessEnd))
        layerPoints.append(LunarPoint(time: nightEndPoint, brightness: 1.0))
        self.init(identifier: "Lunar", points: layerPoints, startTime: nightStart)
    }
}
