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
import Logging
import Service

// MARK: Casting Support between LED and Service types
//
//
extension LEDBoardType {
    init(configType: ServiceBoardType) {
        switch configType {
        case .raspberryPi: self = .raspberryPi
        }
    }
}

extension LEDModuleType {
    init(configType: ServiceControllerType) {
        switch configType {
        case .simulated: self = .simulated
        case .pca9685: self = .pca9685
        case .raspberryPwm: self = .hardware
        case .mcp4725: self = .mcp4725
        }
    }
}

extension LEDChannel: Channel {}

extension ServiceControllerDescription: LEDModuleConfig {}

// MARK: Casting Support between Logging and Service types
//
//
extension Logger.Level {
    init(_ serviceLevel: ServiceLoggingLevel) {
        switch serviceLevel {
        case .trace:
            self = .trace
        case .debug:
            self = .debug
        case .info:
            self = .info
        case .warn:
            self = .warning
        case .error:
            self = .error
        }
    }
}
