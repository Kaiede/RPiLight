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
        get {
            switch(self) {
            case .pca9685: fallthrough
            case .mcp4725:
                return true
            default:
                return false
            }
        }
    }

    var hasFrequency: Bool {
        get {
            switch(self) {
            case .raspberryPwm: fallthrough
            case .pca9685:
                return true
            default:
                return false
            }
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

    // MQTT Broker Config
    public let broker: ServiceBrokerConfiguration?

    enum CodingKeys: String, CodingKey {
        case username = "user"
        case logLevel = "logging"

        case boardType = "board"
        case gamma = "gamma"
        
        case broker = "broker"
        
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
        broker = try container.decodeIfPresent(ServiceBrokerConfiguration.self, forKey: .broker)
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
// Service Broker Configuration
//
// Configuration on what MQTT Broker to Connect to
//

public struct ServiceBrokerConfiguration {
    public let host: String
    public let port: Int32
    
    public let keepAlive: Int32
    public let useTLS: Bool
    
    public let username: String?
    public let password: String?
    
    enum CodingKeys: String, CodingKey {
        case host
        case port
        case keepAlive
        case useTLS
        
        case username
        case password
    }
}

extension ServiceBrokerConfiguration: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.host = try container.decodeIfPresent(String.self, forKey: .host) ?? "localhost"
        self.port = try container.decodeIfPresent(Int32.self, forKey: .port) ?? 1883
        self.keepAlive = try container.decodeIfPresent(Int32.self, forKey: .keepAlive) ?? 60
        self.useTLS = try container.decodeIfPresent(Bool.self, forKey: .useTLS) ?? false
        
        self.username = try container.decodeIfPresent(String.self, forKey: .username)
        self.password = try container.decodeIfPresent(String.self, forKey: .password)
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
    public let channels: [String : Int]

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
        var decodedChannels: [String:Int] = [:]
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
            let minimumFrequency = 120
            let defaultFrequency = 480
            let maximumFrequency = 2000
            if container.contains(.frequency) {
                let decodedFrequency = try container.decode(Int.self, forKey: .frequency)
                frequency = decodedFrequency <= 0 ? defaultFrequency : max(min(decodedFrequency, maximumFrequency), minimumFrequency)
            } else {
                frequency = defaultFrequency
            }
        } else {
            frequency = nil
        }
    }
}
