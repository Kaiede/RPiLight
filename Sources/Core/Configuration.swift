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

typealias JsonDict = [String: Any]

public enum ConfigurationError: Error {
    case fileNotFound
    case nodeMissing(String, message: String)
    case invalidValue(String, value: String)
}

public struct Configuration {
    public let hardware: Hardware
    public let channels: [ChannelInfo]
    public let schedule: [Event]

    public init(withPath path: URL) throws {
        guard let configData = try? Data(contentsOf: path, options: []) else { throw ConfigurationError.fileNotFound }
        let jsonAny = try? JSONSerialization.jsonObject(with: configData, options: [])
        guard let json = jsonAny as? JsonDict else { throw ConfigurationError.nodeMissing("root", message: "Unable to read configuration, invalid format") }

        try self.init(json: json)
    }

    init(json: JsonDict) throws {
        guard let hardwareConfig = json["hardware"] as? JsonDict else { throw ConfigurationError.nodeMissing("hardware", message: "Configuration must include a hardware entry") }
        let hardware = try Hardware(json: hardwareConfig)

        var channelArray: [ChannelInfo] = []
        if let jsonChannels = json["channels"] as? [JsonDict] {
            for jsonChannel in jsonChannels {
                let channel = try ChannelInfo(json: jsonChannel)
                channelArray.append(channel)
            }
        }
        
        // TODO: Currently Optional. Shouldn't Be Going Forward
        var scheduleArray: [Event] = []
        if let jsonSchedule = json["schedule"] as? [JsonDict] {
            for jsonEvent in jsonSchedule {
                let event = try Event(json: jsonEvent)
                scheduleArray.append(event)
            }
        }

        self.hardware = hardware
        self.channels = channelArray
        self.schedule = scheduleArray
    }
}

public struct Hardware {
    public let type: ModuleType
    public let board: BoardType
    public let channelCount: Int
    public let frequency: Int
    public let gamma: Double


    init(json: JsonDict) throws {
        guard let pwmMode = json["pwmMode"] as? String else { throw ConfigurationError.nodeMissing("pwmMode", message: "Hardware must have a pwmMode") }
        guard let moduleType = ModuleType(rawValue: pwmMode) else { throw ConfigurationError.invalidValue("pwmMode", value: pwmMode) }

        let boardType = try Hardware.getBoardType(json: json)
        
        let frequency = json["freq"] as? Int ?? 480
        let channelCount = json["channels"] as? Int ?? 1
        let gamma = json["gamma"] as? Double ?? 1.8

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

    private static func getBoardType(json: JsonDict) throws -> BoardType {
        if let board = json["board"] as? String {
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

public struct ChannelInfo {
    public let token: String
    public let minIntensity: Double
    
    init(json: JsonDict) throws {
        guard let token = json["token"] as? String else { throw ConfigurationError.nodeMissing("token", message: "All channels in configuration must have a token") }
        let minIntensity = json["minIntensity"] as? Double ?? 0.0
        
        self.init(token: token, minIntensity: minIntensity)
    }
    
    init(token: String, minIntensity: Double) {
        self.token = token
        self.minIntensity = minIntensity
    }
}

public struct Event {
    public let time: DateComponents
    public let channelValues: [ChannelValue]

    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()

    init(json: JsonDict) throws {
        guard let timeString = json["time"] as? String else { throw ConfigurationError.nodeMissing("time", message: "Events must have a time") }
        guard let channelArray = json["channels"] as? [JsonDict] else { throw ConfigurationError.nodeMissing("channelArray", message: "Events in schedule must have a channels array") }

        guard let parsedTime = Event.dateFormatter.date(from: timeString) else { throw ConfigurationError.invalidValue("time", value: timeString) }

        let splitTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedTime)
        var channelValueArray: [ChannelValue] = []
        for jsonChannelValue in channelArray {
            let channelValue = try ChannelValue(json: jsonChannelValue)
            channelValueArray.append(channelValue)
        }

        self.init(time: splitTime, channelValues: channelValueArray)
    }

    init(time: DateComponents, channelValues: [ChannelValue]) {
        self.time = time
        self.channelValues = channelValues
    }
}


public struct ChannelValue {
    public let token: String
    public let setting: ChannelSetting

    init(json: JsonDict) throws {
        guard let token = json["token"] as? String else { throw ConfigurationError.nodeMissing("token", message: "All channels in schedule events must have a token") }
        if let intensity = json["intensity"] as? Double {
            self.init(token: token, setting: .intensity(intensity))
        } else if let brightness = json["brightness"] as? Double {
            self.init(token: token, setting: .brightness(brightness))
        } else {
            throw ConfigurationError.nodeMissing("brightness or intensity", message: "All channels in schedule events must have a brightness or intensity")
        }
    }

    init(token: String, setting: ChannelSetting) {
        self.token = token
        self.setting = setting
    }
}
