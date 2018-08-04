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

class Previewer {
    // Compress a 24-hour day into 1 minute of preview
    private static let compressionFactor: Double = 24.0 * 60.0
    private static let oneMinute: Double = 60.0

    private let controller: LightController
    
    init(usingController controller: LightController) {
        self.controller = controller
    }
    
    public func runSchedule(_ schedule: [Event]) {
        let behaviors = self.calculateRamps(forSchedule: schedule)
        for (index, behavior) in behaviors.enumerated() {
            Log.info("Starting Segment \(index)")
            self.controller.setCurrentBehavior(behavior: behavior, startDate: behavior.startDate, endDate: behavior.endDate)
            behavior.wait()
        }
    }
    
    private func calculateRamps(forSchedule schedule: [Event]) -> [LightLevelChangeBehavior] {
        // Delay a little to allow for calculation time.
        let now = Date().addingTimeInterval(0.5)
        var currentEnd = now
        var timeRemaining = Previewer.oneMinute
        
        var behaviors: [LightLevelChangeBehavior] = []
        for (index, event) in schedule.enumerated() {
            let nextIndex = (index + 1) % schedule.count
            let nextEvent = schedule[nextIndex]
            let lightRanges = event.lightRangesToEvent(event: nextEvent)
            let rampBehavior = LightLevelChangeBehavior(lightRanges: lightRanges)

            Log.debug(lightRanges)
            
            guard var timeDelta = Calendar.current.intervalBetweenDateComponents(nextEvent.time, since: event.time) else {
                fatalError("Schedule contains incalculable event times. That's bad.")
            }
            
            // Convert duration to seconds, and then cap it.
            // The last event will have some overlap into the next "day", so trim it off.
            timeDelta /= Previewer.compressionFactor
            timeDelta = min(timeDelta, timeRemaining)
            
            rampBehavior.startDate = currentEnd
            rampBehavior.endDate = currentEnd.addingTimeInterval(timeDelta)
            behaviors.append(rampBehavior)
            
            currentEnd = rampBehavior.endDate
            timeRemaining -= timeDelta
        }
        
        return behaviors
    }
}
