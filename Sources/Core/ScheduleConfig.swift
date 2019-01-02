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

fileprivate struct ScheduleFormatters {
    static let timeOfDay: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.calendar = Calendar.current
        return dateFormatter
    }()
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

        guard let parsedStart = ScheduleFormatters.timeOfDay.date(from: try container.decode(String.self, forKey: .startTime)) else {
            throw DecodingError.dataCorruptedError(forKey: .startTime, in: container, debugDescription: "Invalid Start Time provided")
        }
        startTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedStart)

        guard let parsedEnd = ScheduleFormatters.timeOfDay.date(from: try container.decode(String.self, forKey: .endTime)) else {
            throw DecodingError.dataCorruptedError(forKey: .endTime, in: container, debugDescription: "Invalid End Time provided")
        }
        endTime = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedEnd)
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

        guard let parsedTime = ScheduleFormatters.timeOfDay.date(from: try container.decode(String.self, forKey: .time)) else {
            throw DecodingError.dataCorruptedError(forKey: .time, in: container, debugDescription: "Invalid Time provided")
        }
        time = Calendar.current.dateComponents([.hour, .minute, .second], from: parsedTime)

        guard !container.contains(.brightness) || !container.contains(.intensity) else { 
            throw DecodingError.dataCorruptedError(forKey: .brightness, in: container, debugDescription: "Only brightness *or* intensity allowed")
        }

        if container.contains(.brightness) {
            setting = .brightness(try container.decode(Double.self, forKey: .brightness))
        } else if container.contains(.intensity) {
            setting = .intensity(try container.decode(Double.self, forKey: .intensity))
        } else { 
            throw DecodingError.dataCorruptedError(forKey: .brightness, in: container, debugDescription: "brightness *or* intensity required")
        }
    }
}

public enum ChannelSetting {
    case brightness(Double)
    case intensity(Double)

    public static func max(_ lhs: ChannelSetting, _ rhs: ChannelSetting, withGamma gamma: Double) -> ChannelSetting {
        switch lhs {
        case .brightness(let brightness):
            return .brightness(Swift.max(brightness, rhs.asBrightness(withGamma: gamma)))
        case .intensity(let intensity):
            return .intensity(Swift.max(intensity, rhs.asIntensity(withGamma: gamma)))
        }
    }
    
    public func asBrightness(withGamma gamma: Double) -> Double {
        switch self {
        case .brightness(let brightness):
            return brightness
        case .intensity(let intensity):
            return intensity ** (1.0 / gamma)
        }
    }
    
    public func asIntensity(withGamma gamma: Double) -> Double {
        switch self {
        case .brightness(let brightness):
            return brightness ** gamma
        case .intensity(let intensity):
            return intensity
        }
    }
}

