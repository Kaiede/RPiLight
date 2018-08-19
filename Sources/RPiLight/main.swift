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
import Moderator

import Core
import Logging
import PWM

//
// MARK: Process Arguments
//
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

//
// MARK: Load Configuration
//
func loadConfiguration() -> Configuration {
    let configDir = FileManager.default.currentDirectoryUrl.appendingPathComponent("config")
    let configUrl = configDir.appendingPathComponent(configFile.value)
    Log.debug("Opening Configuration: \(configUrl.absoluteString)")

    do {
        let configuration = try Configuration(withPath: configUrl)
        
        return configuration
    } catch ConfigurationError.fileNotFound {
        fatalError("Unable to open configuration file: \(configUrl.absoluteString)")
    } catch ConfigurationError.nodeMissing(let node, message: let message) {
        let errorString = "'\(node)' was expected, but not found or invalid:\n\(message)"
        fatalError(errorString)
    } catch ConfigurationError.invalidValue(let value, value: let invalidValue) {
        fatalError("Unexpected value for '\(value)': \(invalidValue)")
    } catch {
        fatalError()
    }
}

let configuration = loadConfiguration()
Log.info("Configured Board: \(configuration.hardware.board.rawValue)")
Log.info("Configured PWM Module: \(configuration.hardware.type.rawValue)")
Log.info("Configured PWM Frequency: \(configuration.hardware.frequency) Hz")
Log.info("Configured Gamma: \(configuration.hardware.gamma)")

Log.withDebug {
    Log.debug("Configured Schedule Details for Today:")
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM HH:mm:ss Z"
    formatter.calendar = Calendar.current
    formatter.timeZone = TimeZone.current
    let now = Date()
    for channel in configuration.channels {
        Log.debug("==== Channel \(channel.token)")
        for event in channel.schedule {
            let prevDate = event.time.calcNextDate(after: now, direction: .backward)!
            let nextDate = event.time.calcNextDate(after: now, direction: .forward)!
            Log.debug("\t\(formatter.string(from: prevDate)) -> \(formatter.string(from: nextDate))")
        }
    }
}

//
// MARK: Create Module
//
var moduleMaybe: Module?
do {
    moduleMaybe = try configuration.hardware.createModule()
} catch ModuleInitError.noHardwareAccess {
    Log.error("Unable to Access Hardware")
    exit(-1)
} catch ModuleInitError.invalidBoardType(let board){
    Log.error("PWM Module Doesn't Support Board: \(board)")
    exit(-1)
} catch ModuleInitError.invalidChannelCount(let min, let max, let actual) {
    Log.error("Channel Count \(actual) must be between \(min) and \(max)")
    exit(-1)
} catch ModuleInitError.invalidFrequency(let min, let max, let actual) {
    Log.error("PWM Module expects frequency \(actual) to be between \(min) and \(max)")
    exit(-1)
} catch {
    Log.error(error)
    exit(-1)
}

guard let module = moduleMaybe else {
    Log.error("Unexpected erorr, expected Hardware Module to be created, but it wasn't, and no error was reported")
    exit(-1)
}

//
// MARK: Process Channels
//
let activeChannels = module.availableChannels.map { (token : String) -> Channel in
    do {
        return try module.createChannel(with: token)
    } catch {
        Log.error("Unable to create channel \(token)")
        exit(-1)
    }
}

let activeChannelDict = activeChannels.reduce([String: Channel]()) { (dict, channel) -> [String: Channel] in
    var dict = dict
    dict[channel.token] = channel
    return dict
}

//
// MARK: Configure Channels
//
for channelInfo in configuration.channels {
    guard var channel = activeChannelDict[channelInfo.token] else {
        fatalError("Attempted to configure unknown channel '\(channelInfo.token)")
    }
    
    Log.info("\(channelInfo.token) Minimum Intensity: \(channelInfo.minIntensity)")
    channel.minIntensity = channelInfo.minIntensity
}

//
// MARK: Initialize Light Controller and Run
//
if previewMode.value {
    // Preview
    let controller = try! LightController(channels: activeChannels, withConfig: configuration.channels, behavior: PreviewLightBehavior())
    controller.setStopHandler { (controller) in
        Log.info("Simulation Complete")
        exit(0)
    }

    controller.start()
    dispatchMain()
} else {
    // Normal Schedule
    let controller = try! LightController(channels: activeChannels, withConfig: configuration.channels)
    controller.setStopHandler { (controller) in
        Log.error("Controller unexpectedly stopped.")
        exit(1)
    }
    controller.start()
    dispatchMain()
}
