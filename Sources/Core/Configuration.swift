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
import PWM
import SwiftyGPIO
import SwiftyJSON

typealias JsonDict = [String: JSON]

public enum ConfigurationError: Error {
    case fileNotFound
    case nodeMissing(String, message: String)
    case invalidValue(String, value: String)
}

public struct Configuration {
    public let username: String
    public let logging: LogLevel
    public let hardware: HardwareConfig
    public let lunarCycle: LunarConfig?
    public let channels: [ChannelConfig]

    public init(withPath path: URL) throws {
        guard let configData = try? Data(contentsOf: path, options: []) else { throw ConfigurationError.fileNotFound }
        let json = JSON(data: configData)
        guard json.type == .dictionary else { throw ConfigurationError.nodeMissing("root", message: "Unable to read configuration, invalid format") }

        try self.init(json: json)
    }

    init(json: JSON) throws {
        guard let keys = json.dictionary?.keys else { throw ConfigurationError.nodeMissing("root", message: "Unable to read configuration, invalid format") }
        guard let username = json["user"].string else { throw ConfigurationError.nodeMissing("user", message: "Don't run as root!") }
        let hardware = try HardwareConfig(json: json["hardware"])

        if json["lunarCycle"].exists() {
            self.lunarCycle = try LunarConfig(json: json["lunarCycle"])
        } else {
            self.lunarCycle = nil
        }

        let loggingString = json["logging"].string ?? "info"


        let fixedKeys = Set(["hardware", "user", "lunarCycle", "logging"])
        let channelKeys = Set(keys).subtracting(fixedKeys)
        guard hardware.channelCount == channelKeys.count else {
            throw ConfigurationError.nodeMissing("channel", message: "Channel count mismatches channel configurations")
        }

        var channelArray: [ChannelConfig] = []
        for token in channelKeys {
            let channel = try ChannelConfig(token: token, json: json[token])
            channelArray.append(channel)
        }

        self.username = username
        self.logging = LogLevel(fromString: loggingString)
        self.hardware = hardware
        self.channels = channelArray
    }
}

public struct HardwareConfig {
    public let type: ModuleType
    public let board: BoardType
    public let channelCount: Int
    public let frequency: Int
    public let gamma: Double


    init(json: JSON) throws {
        guard let pwmMode = json["pwmMode"].string else { throw ConfigurationError.nodeMissing("pwmMode", message: "Hardware must have a pwmMode") }
        guard let moduleType = ModuleType(rawValue: pwmMode) else { throw ConfigurationError.invalidValue("pwmMode", value: pwmMode) }

        let boardType = try HardwareConfig.getBoardType(json: json["board"])
        
        let frequency = json["freq"].number?.intValue ?? 480
        let channelCount = json["channels"].number?.intValue ?? 1
        let gamma = json["gamma"].number?.doubleValue ?? 1.8

        self.init(type: moduleType, board: boardType, channelCount: channelCount, frequency: frequency, gamma: gamma)
    }

    init(type: ModuleType, board: BoardType, channelCount: Int, frequency: Int, gamma: Double) {
        self.type = type
        self.board = board
        self.channelCount = channelCount
        self.frequency = frequency
        self.gamma = gamma
    }

    public func createModule() throws -> Module {
        return try self.type.createModule(board: self.board, channelCount: Int(self.channelCount), frequency: Int(self.frequency), gamma: gamma)
    }

    private static func getBoardType(json: JSON) throws -> BoardType {
        if let board = json.string {
            guard let boardType = BoardType(rawValue: board) else {
                throw ConfigurationError.invalidValue("board", value: board)
            }
            return boardType
        }

        if let bestGuessBoard = BoardType.bestGuess() {
            return bestGuessBoard
        }

        throw ConfigurationError.nodeMissing("board",
                  message: "We tried to guess the hardware board and failed, it should be specified in 'hardware'")
    }
}

public struct LunarConfig {
    public let startTime: DateComponents
    public let endTime: DateComponents

    init(json: JSON) throws {
        guard let startString = json["start"].string else { throw ConfigurationError.nodeMissing("start", message: "Lunar cycle needs a start time") }
        guard let parsedStart = LunarConfig.dateFormatter.date(from: startString) else { throw ConfigurationError.invalidValue("start", value: startString) }

        guard let endString = json["end"].string else { throw ConfigurationError.nodeMissing("end", message: "Lunar cycle needs an end time") }
        guard let parsedEnd = LunarConfig.dateFormatter.date(from: endString) else { throw ConfigurationError.invalidValue("end", value: endString) }

        let startTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedStart)
        let endTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedEnd)

        self.init(startTime: startTime, endTime: endTime)
    }

    init(startTime: DateComponents, endTime: DateComponents) {
        self.startTime = startTime
        self.endTime = endTime
    }

    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()
}

public struct ChannelConfig {
    public let token: String
    public let minIntensity: Double
    public let schedule: [ChannelPointConfig]

    init(token: String, json: JSON) throws {
        // Load Schedule
        var schedule: [ChannelPointConfig] = []
        guard let jsonSchedule = json["schedule"].array else { throw ConfigurationError.nodeMissing("schedule", message: "Channels must have a schedule") }

        for jsonEvent in jsonSchedule {
            let event = try ChannelPointConfig(json: jsonEvent)
            schedule.append(event)
        }

        // Optional Configuration Settings
        let minIntensity = json["minIntensity"].number?.doubleValue ?? 0.0

        self.init(token: token, minIntensity: minIntensity, schedule: schedule)
    }

    init(token: String, minIntensity: Double, schedule: [ChannelPointConfig]) {
        self.token = token
        self.minIntensity = minIntensity
        self.schedule = schedule
    }
}

public struct ChannelPointConfig {
    public let time: DateComponents
    public let setting: ChannelSetting

    init(json: JSON) throws {
        guard let timeString = json["time"].string else { throw ConfigurationError.nodeMissing("time", message: "Events must have a time") }
        guard let parsedTime = ChannelPointConfig.dateFormatter.date(from: timeString) else { throw ConfigurationError.invalidValue("time", value: timeString) }

        let splitTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedTime)

        if let intensity = json["intensity"].number?.doubleValue {
            self.init(time: splitTime, setting: .intensity(intensity))
        } else if let brightness = json["brightness"].number?.doubleValue {
            self.init(time: splitTime, setting: .brightness(brightness))
        } else {
            throw ConfigurationError.nodeMissing("brightness or intensity", message: "All channels in schedule events must have a brightness or intensity")
        }
    }

    init(time: DateComponents, setting: ChannelSetting) {
        self.time = time
        self.setting = setting
    }

    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()
}
