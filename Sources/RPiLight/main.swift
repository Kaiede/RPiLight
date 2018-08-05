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
import Moderator
import PWM

var moderator = Moderator(description: "Aquarium Light Controller for Raspberry Pi")
let verbose = moderator.add(.option("v","verbose", description: "Provide Additional Logging"))
let previewMode = moderator.add(.option("preview", description: "Run in Preview Mode"))
let configFile = moderator.add(Argument<String>
                    .singleArgument(name: "config file", description: "Configuration file to load")
                    .default("config.json"))

do {
    try moderator.parse()
} catch {
    print(error)
    exit(-1)
}

if verbose.value {
    Log.setLoggingLevel(.debug)
}

let configDir = FileManager.default.currentDirectoryUrl.appendingPathComponent("config")
let configUrl = configDir.appendingPathComponent(configFile.value)
Log.debug("Opening Configuration: \(configUrl.absoluteString)")
guard let configuration = Configuration(withPath: configUrl) else {
    fatalError("Unable to load configuration at \(configUrl.absoluteString)")
}

Log.withDebug {
    let formatter = DateFormatter()
    formatter.dateFormat = "d MMM HH:mm:ss Z"
    formatter.calendar = Calendar.current
    formatter.timeZone = TimeZone.current
    let now = Date()
    for event in configuration.schedule {
        let prevDate = event.time.calcNextDate(after: now, direction: .backward)!
        let nextDate = event.time.calcNextDate(after: now, direction: .forward)!
        Log.debug("\(formatter.string(from: prevDate)) -> \(formatter.string(from: nextDate))")
    }
}

let module = try! configuration.hardware.createModule()
Log.debug(module)

let activeChannels = module.availableChannels.map {
    return try! module.createChannel(with: $0)
}

var controller = LightController(channels: activeChannels)

if previewMode.value {
    let previewer = Previewer(usingController: controller)
    previewer.runSchedule(configuration.schedule)
} else {
    // Ruin the Schedule Normally
    controller.applySchedule(schedule: configuration.schedule)
    dispatchMain()
}
