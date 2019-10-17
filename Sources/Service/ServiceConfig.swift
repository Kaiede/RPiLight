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

public enum ServiceLoggingLevel: String, Codable {
    case debug
    case info
    case warn
    case error
}

public enum ServiceControllerType: String, Codable {
    case simulated
    case raspberryPwm
    case pca9685
    case mcp4725
}

extension ServiceControllerType {
    var hasAddress: Bool {
        switch self {
        case .pca9685: return true
        case .mcp4725: return true
        default: return false
        }
    }

    var hasFrequency: Bool {
        switch self {
        case .raspberryPwm: return true
        case .pca9685: return true
        default: return false
        }
    }
}

public enum ServiceBoardType: String, Codable {
    case raspberryPi
}

public struct ServiceConfiguration {
    // Service Properties
    public let username: String
    public let logLevel: ServiceLoggingLevel

    // LED Controller Settings
    public let board: ServiceBoardType
    public let gamma: Double
    public let controllers: [ServiceControllerConfiguration]

    // FUTURE: MQTT Broker Config

    enum CodingKeys: String, CodingKey {
        case username = "user"
        case logLevel = "logging"

        case boardType = "board"
        case gamma = "gamma"
        case controllers = "controllers"
    }
}

extension ServiceConfiguration: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        username = try container.decode(String.self, forKey: .username)

        if container.contains(.logLevel) {
            logLevel = try container.decode(ServiceLoggingLevel.self, forKey: .logLevel)
        } else {
            logLevel = .info
        }

        board = try container.decode(ServiceBoardType.self, forKey: .boardType)
        controllers = try container.decode([ServiceControllerConfiguration].self, forKey: .controllers)

        // Controller Gamma
        let minimumGamma = 1.0
        let defaultGamma = 1.8
        let maximumGamma = 3.0
        if container.contains(.gamma) {
            let decodedGamma = try container.decode(Double.self, forKey: .gamma)
            gamma = decodedGamma <= 0 ? defaultGamma : max(min(decodedGamma, maximumGamma), minimumGamma)
        } else {
            gamma = 1.8
        }
    }
}

//
// Service Controller Configuration
//
// Configuration for a single LED controller
//

public struct ServiceControllerConfiguration {
    // Required Controller Settings
    public let type: ServiceControllerType
    public let channels: [String: Int]

    // Conditional Controller Settings
    public let frequency: Int?
    public let address: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case channels

        case frequency
        case address
    }
}

extension ServiceControllerConfiguration: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Controller Type
        type = try container.decode(ServiceControllerType.self, forKey: .type)

        let channelContainer = try container.nestedContainer(keyedBy: AnyCodingKey.self, forKey: .channels)
        var decodedChannels: [String: Int] = [:]
        for codingKey in channelContainer.allKeys {
            decodedChannels[codingKey.stringValue] = try channelContainer.decode(Int.self, forKey: codingKey)
        }
        channels = decodedChannels

        // Conditional: Address
        if type.hasAddress {
            address = try container.decode(Int.self, forKey: .address)
        } else {
            address = nil
        }

        // Conditional: Frequency
        if type.hasFrequency {
            let defaultFrequency = 480
            if container.contains(.frequency) {
                let decodedFrequency = try container.decode(Int.self, forKey: .frequency)
                frequency = Int(decodedFrequency: decodedFrequency, default: defaultFrequency)
            } else {
                frequency = defaultFrequency
            }
        } else {
            frequency = nil
        }
    }
}

fileprivate extension Int {
    init(decodedFrequency: Int, default defaultFrequency: Int) {
        let minimumFrequency = 120
        let maximumFrequency = 2000

        if decodedFrequency <= 0 {
            self = defaultFrequency
        } else if decodedFrequency <= minimumFrequency {
            self = minimumFrequency
        } else if decodedFrequency >= maximumFrequency {
            self = maximumFrequency
        } else {
            self = decodedFrequency
        }
    }
}
