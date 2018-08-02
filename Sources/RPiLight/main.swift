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
import PWM

guard let configuration = Configuration(withPath: "config/testConfig.json") else {
	fatalError()
}

let formatter = DateFormatter()
formatter.dateFormat = "d MMM yyyy HH:mm:ss Z"
formatter.calendar = Calendar.current
formatter.timeZone = TimeZone.current
for event in configuration.schedule {
	let nextDate = event.calcNextDate(direction: .backward)
	print(formatter.string(from: nextDate))
}

let module = try! configuration.hardware.createModule()
print(module)

let activeChannels = module.availableChannels.map {
    return try! module.createChannel(with: $0)
}

var controller = LightController(channels: activeChannels)

controller.applySchedule(schedule: configuration.schedule)

dispatchMain()

