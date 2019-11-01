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

import LED

// Originally Written by "Hamish Knight"
// https://bugs.swift.org/browse/SR-7498
struct AnyCodingKey: CodingKey {
  var stringValue: String
  var intValue: Int?

  init(_ codingKey: CodingKey) {
    self.stringValue = codingKey.stringValue
    self.intValue = codingKey.intValue
  }

  init(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }

  init(intValue: Int) {
    self.stringValue = String(intValue)
    self.intValue = intValue
  }
}

private struct ScheduleFormatters {
    static let timeOfDay: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()
}

public struct Schedule {
    public let lunarCycle: LunarSchedule?
    public let channels: [String: ChannelSchedule]
}

extension Schedule: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)

        lunarCycle = try container.decodeIfPresent(LunarSchedule.self, forKey: AnyCodingKey(stringValue: "lunarCycle"))

        var decodedChannels: [String: ChannelSchedule] = [:]
        for codingKey in container.allKeys {
            guard codingKey.stringValue != "lunarCycle" else { continue }

            decodedChannels[codingKey.stringValue] = try container.decode(ChannelSchedule.self, forKey: codingKey)
        }
        channels = decodedChannels
    }
}

public struct LunarSchedule {
    public let startTime: DateComponents
    public let endTime: DateComponents

    enum CodingKeys: String, CodingKey {
        case startTime = "start"
        case endTime = "end"
    }
}

extension LunarSchedule: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedStart = try container.decode(String.self, forKey: .startTime)
        guard let parsedStart = ScheduleFormatters.timeOfDay.date(from: decodedStart) else {
            throw DecodingError.dataCorruptedError(forKey: .startTime,
                                                   in: container,
                                                   debugDescription: "Invalid Start Time provided")
        }
        startTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedStart)

        let decodedEnd = try container.decode(String.self, forKey: .endTime)
        guard let parsedEnd = ScheduleFormatters.timeOfDay.date(from: decodedEnd) else {
            throw DecodingError.dataCorruptedError(forKey: .endTime,
                                                   in: container,
                                                   debugDescription: "Invalid End Time provided")
        }
        endTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedEnd)
    }
}

public struct ChannelSchedule {
    public let minIntensity: Double
    public let schedule: [SchedulePoint]

    enum CodingKeys: String, CodingKey {
        case minIntensity
        case schedule
    }
}

extension ChannelSchedule: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        minIntensity = try container.decodeIfPresent(Double.self, forKey: .minIntensity) ?? 0.0
        schedule = try container.decode([SchedulePoint].self, forKey: .schedule)
    }
}

public struct SchedulePoint {
    public let time: DateComponents
    public let setting: ChannelSetting

    enum CodingKeys: String, CodingKey {
        case time

        case brightness
        case intensity
    }
}

extension SchedulePoint: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedTime = try container.decode(String.self, forKey: .time)
        guard let parsedTime = ScheduleFormatters.timeOfDay.date(from: decodedTime) else {
            throw DecodingError.dataCorruptedError(forKey: .time,
                                                   in: container,
                                                   debugDescription: "Invalid Time provided")
        }
        time = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedTime)

        guard !container.contains(.brightness) || !container.contains(.intensity) else {
            throw DecodingError.dataCorruptedError(forKey: .brightness,
                                                   in: container,
                                                   debugDescription: "Only brightness *or* intensity allowed")
        }

        if container.contains(.brightness) {
            setting = .brightness(try container.decode(Brightness.self, forKey: .brightness))
        } else if container.contains(.intensity) {
            setting = .intensity(try container.decode(Intensity.self, forKey: .intensity))
        } else {
            throw DecodingError.dataCorruptedError(forKey: .brightness,
                                                   in: container,
                                                   debugDescription: "brightness *or* intensity required")
        }
    }
}

public enum ChannelSetting {
    case brightness(Brightness)
    case intensity(Intensity)
}

extension Brightness {
    public init(setting: ChannelSetting, gamma: Gamma) {
        switch setting {
        case .brightness(let brightness):
            self = brightness
        case .intensity(let intensity):
            self.init(intensity, gamma: gamma)
        }
    }
}

extension Intensity {
    public init(setting: ChannelSetting, gamma: Gamma) {
        switch setting {
        case .brightness(let brightness):
            self.init(brightness, gamma: gamma)
        case .intensity(let intensity):
            self = intensity
        }
    }
}
