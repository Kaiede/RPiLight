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

typealias JsonDict = [String: Any]

struct Configuration {
    let hardware: Hardware
    let schedule: [Event]

    init?(withPath path: URL) {
        guard let configData = try? Data(contentsOf: path, options: []) else { return nil }
        let jsonAny = try? JSONSerialization.jsonObject(with: configData, options: [])
        guard let json = jsonAny as? JsonDict else { return nil }

        self.init(json: json)
    }

    init?(json: JsonDict) {
        guard let hardwareConfig = json["hardware"] as? JsonDict else { return nil }
        guard let hardware = Hardware(json: hardwareConfig) else { return nil }

        // TODO: Currently Optional. Shouldn't Be Going Forward
        var scheduleArray: [Event] = []
        if let jsonSchedule = json["schedule"] as? [JsonDict] {
            for jsonEvent in jsonSchedule {
                guard let event = Event(json: jsonEvent, hardware: hardware) else { return nil }
                scheduleArray.append(event)
            }
        }

        self.hardware = hardware
        self.schedule = scheduleArray
    }
}

struct Hardware {
    let type: ModuleType
    let channelCount: Int
    let frequency: Int
    let gamma: Double

    init?(json: JsonDict) {
        guard let pwmMode = json["pwmMode"] as? String else { return nil }
        guard let moduleType = ModuleType(rawValue: pwmMode) else { return nil }
        let frequency = json["freq"] as? Int ?? 480
        let channelCount = json["channels"] as? Int ?? 1
        let gamma = json[""] as? Double ?? 1.8

        self.init(type: moduleType, channelCount: channelCount, frequency: frequency, gamma: gamma)
    }

    init(type: ModuleType, channelCount: Int, frequency: Int, gamma: Double) {
        self.type = type
        self.channelCount = channelCount
        self.frequency = frequency
        self.gamma = gamma
    }

    func createModule() throws -> Module {
        return try self.type.createModule(channelCount: Int(self.channelCount), frequency: Int(self.frequency), gamma: gamma)
    }
}

struct Event {
    let time: DateComponents
    let channelValues: [ChannelValue]

    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()

    init?(json: JsonDict, hardware: Hardware) {
        guard let timeString = json["time"] as? String else { return nil }
        guard let channelArray = json["channels"] as? [JsonDict] else { return nil }

        guard let parsedTime = Event.dateFormatter.date(from: timeString) else { return nil }

        let splitTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedTime)
        var channelValueArray: [ChannelValue] = []
        for jsonChannelValue in channelArray {
            guard let channelValue = ChannelValue(json: jsonChannelValue, hardware: hardware) else { return nil }
            channelValueArray.append(channelValue)
        }

        self.init(time: splitTime, channelValues: channelValueArray)
    }

    init(time: DateComponents, channelValues: [ChannelValue]) {
        self.time = time
        self.channelValues = channelValues
    }
}


struct ChannelValue {
    let token: String
    let setting: ChannelSetting

    init?(json: JsonDict, hardware: Hardware) {
        guard let token = json["token"] as? String else { return nil }
        if let intensity = json["intensity"] as? Double {
            self.init(token: token, setting: .intensity(intensity))
        } else if let brightness = json["brightness"] as? Double {
            self.init(token: token, setting: .brightness(brightness))
        } else {
            return nil
        }
    }

    init(token: String, setting: ChannelSetting) {
        self.token = token
        self.setting = setting
    }
}
