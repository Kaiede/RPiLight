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

//
// Errors
//

public enum LEDModuleError: Error {
    case noImplementationAvailable
    case noHardwareAccess
    case invalidBoardType(actual: String)
    case invalidFrequency(min: Int, max: Int, actual: Int)
    case missingFrequency
}

public enum LEDChannelError: Error {
    case invalidToken(actual: String)
    case tokenReused
}

//
// BoardType
//
// Wrapper around SwiftyGPIO's boards
//
public enum LEDBoardType: String {
    case desktop = "Desktop Linux / Mac (x86)"
    case raspberryPi = "Raspberry Pi (ARM)"
}

//
// Module Configuration Protocol
//
// Public protocol for configuring an LED Module.
// It is expected that this comes from some sort of deserialization,
// so to avoid specifying any specific schema (JSON/XML/etc.), just
// make your type conform to this.
//

public protocol LEDModuleConfig {
    var channels: [String : Int] { get }

    // Conditional LED Controller Settings
    var frequency: Int? { get }
    var address: Int? { get }
}

//
// Module Type Enumeration
//
// Wrapper around the different module types. Provides access to the different
// modes in a safe way.
//

public enum LEDModuleType: String {
    case simulated = "Simulated Output"
    case hardware = "Hardware GPIO"
    case pca9685 = "PCA9685 Bonnet"
    case mcp4725 = "MCP4725 0-10V DAC"
}

extension LEDModuleType {
    public func createModule(board: LEDBoardType, configuration: LEDModuleConfig) throws -> LEDModule {
        guard let impl = try self.implForModule(board: board, configuration: configuration) else {
            throw LEDModuleError.noImplementationAvailable
        }

        return LEDModule(impl: impl)
    }

    private func implForModule(board: LEDBoardType, configuration: LEDModuleConfig) throws -> LEDModuleImpl? {
        switch self {
        case .simulated:
            return SimulatedImpl(configuration: configuration)
        case .hardware:
            return try PwmViaRaspberryPi(configuration: configuration, board: board)
        case .pca9685:
            return try PwmViaPCA9685(configuration: configuration, board: board)
        case .mcp4725:
            return try DacViaMCP4725(configuration: configuration, board: board)
        }
    }
}

//
// Module
//
// Public class for interacting with LED modules.
// Most interaction will be done via LEDChannelSets, most likely.
//

public class LEDModule: CustomStringConvertible {
    public var availableChannels: [String] {
        get { return Array(impl.channelMap.keys) }
    }

    public var description: String {
        return "\(self.availableChannels)"
    }

    public subscript(token: String) -> LEDChannel? {
        guard let channelId = impl.channelMap[token] else {
            return nil
        }

        return LEDChannel(impl: impl, token: token, id: channelId)
    }

    private let impl: LEDModuleImpl
    internal init(impl: LEDModuleImpl) {
        self.impl = impl
    }
}

//
// Channel
//
// Public type for interacting with a single channel associated with an LED Module
//

public class LEDChannel {
    private let impl: LEDModuleImpl
    private let id: Int

    public let token: String
    public var minIntensity: Double
    public var intensity: Double {
        didSet { self.onSettingChanged() }
    }

    internal init(impl: LEDModuleImpl, token: String, id: Int) {
        self.minIntensity = 0.0
        self.intensity = 0.0

        self.impl = impl
        self.token = token
        self.id = id
    }

    private func onSettingChanged() {
        var clampedIntensity = self.intensity
        if clampedIntensity < self.minIntensity.nextUp {
            clampedIntensity = 0.0
        }

        impl.applyIntensity(clampedIntensity, toChannel: self.id)
        Log.debug("\(self.token): Intensity Now \(clampedIntensity * 100)")
    }
}

//
// Channel Set
//
// Combines multiple modules into a single interface.
// Makes it possible to use multiple back-end pieces of hardware to control different channels.
//

public class LEDChannelSet {
    private var channels: [String: LEDChannel]
    private(set) public var modules: [LEDModule]

    public init() {
        self.channels = [:]
        self.modules = []
    }

    public subscript(channel: String) -> LEDChannel? {
        return self.channels[channel]
    }

    public func add(module: LEDModule) throws {
        self.modules.append(module)
        for token in module.availableChannels {
            guard let channel = module[token] else {
                throw LEDChannelError.invalidToken(actual: token)
            }
            if self.channels.keys.contains(token) {
                throw LEDChannelError.tokenReused
            }

            self.channels[token] = channel
        }
    }

    public func asArray() -> [LEDChannel] {
        return Array(self.channels.values)
    }
}
