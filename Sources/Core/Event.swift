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

enum EventId: Equatable {
    case lunar
}

protocol EventController {
    var time: DateComponents { get }
    var token: EventId { get }

    func fire(forController controller: BehaviorController, date: Date)
}

//
// MARK: Lunar Cycle Events
//
class LunarCycleController: EventController {
    let token: EventId = .lunar

    let time: DateComponents
    let endTime: DateComponents

    init(startTime: DateComponents, endTime: DateComponents) {
        self.time = startTime
        self.endTime = endTime
    }

    func fire(forController controller: BehaviorController, date: Date) {
        let calendar = Calendar.current
        guard let nightStart = calendar.date(byAdding: self.time, to: calendar.startOfDay(for: date)) else {
            Log.error("Unable to calculate when lunar night begins")
            return
        }
        guard let nightEnd = endTime.calcNextDate(after: nightStart) else {
            Log.error("Unable to calculate when lunar night ends")
            return
        }

        let illumination = Moon.fastIllumination(forDate: nightStart.halfway(to: nightEnd).toJ2000Date())
        let intensityFactor: ChannelSetting = .intensity(illumination.fraction)

        for channelController in controller.channelControllers.values {
            let gamma = channelController.channelGamma
            let layer = Layer(nightStart: nightStart, end: nightEnd, brightnessFactor: intensityFactor.asBrightness(withGamma: gamma))

            channelController.set(layer: layer, forType: .lunar)
        }
    }
}

struct LunarPoint: LayerPoint {
    let time: DateComponents
    let brightness: Double
}

extension Date {
    func halfway(to date: Date) -> Date {
        let interval = date.timeIntervalSince(self)
        return self.addingTimeInterval(interval / 2)
    }
}

extension Layer {
    convenience init(nightStart: Date, end nightEnd: Date, brightnessFactor: Double) {
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
        layerPoints.append(LunarPoint(time: nightFullStartPoint, brightness: brightnessFactor))
        layerPoints.append(LunarPoint(time: nightFullEndPoint, brightness: brightnessFactor))
        layerPoints.append(LunarPoint(time: nightEndPoint, brightness: 1.0))
        self.init(points: layerPoints, startTime: nightStart)
    }
}
