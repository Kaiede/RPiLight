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

//
// ModuleType
//
// Wrapper around the different module types. Provides access to the different
// modes in a safe way.
//

public enum ModuleType: String {
    case simulated
    case hardware
    case pca9685

    public func createModule(channelCount: Int, frequency: Int, gamma: Double) throws -> Module {
        switch self {
        case .simulated:
            return try SimulatedPWM(channelCount: channelCount, frequency: frequency, gamma: gamma)
        case .hardware:
            return try HardwarePWM(channelCount: channelCount, frequency: frequency, gamma: gamma)
        case .pca9685:
            return try ExpansionPWM(channelCount: channelCount, frequency: frequency, gamma: gamma)
        }
    }
}

extension ModuleType: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        let lowercaseString = rawValue.lowercased()
        switch lowercaseString {
        case "simulated": self = .simulated
        case "hardware": self = .hardware
        case "pigpio": self = .hardware
        case "pca9685": self = .pca9685
        case "adafruit": self = .pca9685
        default: return nil
        }
    }
}

//
// ModuleInitError
//

public enum ModuleInitError: Error {
    case noHardwareAccess
    case invalidChannelCount(min: Int, max: Int, actual: Int)
    case invalidFrequency(min: Int, max: Int, actual: Int)
}

//
// Module Protocol
//
// Public protocol for interacting with a PWM module
//

public protocol Module {
    var availableChannels: [String] { get }

    func createChannel(with token: String) throws -> Channel
}

public extension Module {
    func channelTokenIsValid(_ token: String) -> Bool {
        return self.availableChannels.contains(token)
    }
}

public extension Module where Self: CustomStringConvertible {
    var description: String {
        return "\(self.availableChannels)"
    }
}

//
// Channel Protocol
//
// Protocol for interacting with a single PWM channel.
// Includes convenience handlers for interacting with gamma correction
//



public enum ChannelInitError: Error {
    case invalidToken
}

public enum ChannelSetting {
    case brightness(Double)
    case intensity(Double)

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

let IntensityPrecision: Double = 0.0001

public protocol Channel {
    var token: String { get }
    var gamma: Double { get }
    var minIntensity: Double { get set }
    var setting: ChannelSetting { get set }
}
