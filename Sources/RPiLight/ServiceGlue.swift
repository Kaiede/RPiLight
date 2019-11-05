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

// MARK: Decoupling Types for Configuration / Description
//
// 

// ServiceInfo (Wrapper)
struct ServiceInfo {
    // Service Properties
    public let username: String
    public let logLevel: ServiceLoggingLevel

    // LED Controller Settings
    public let board: ServiceBoardType
    public let gamma: Gamma
    public let controllers: [ServiceControllerInfo]
}

extension ServiceInfo {
    init(_ other: ServiceConfiguration) {
        self.username = other.username
        self.logLevel = other.logLevel
        self.board = other.board
        self.gamma = other.gamma
        self.controllers = other.controllers
    }

    init(_ other: ServiceDescription) {
        self.username = other.username
        self.logLevel = other.logLevel ?? .info
        self.board = other.board
        self.gamma = other.gamma ?? 1.8
        self.controllers = other.controllers
    }
}

// ServiceControllerInfo
protocol ServiceControllerInfo: LEDModuleConfig {
    var type: ServiceControllerType { get }
}

extension ServiceControllerConfiguration: ServiceControllerInfo {}
extension ServiceControllerDescription: ServiceControllerInfo {}

// MARK: Casting Support between Logging and Service types
//
//
extension LogLevel {
    init(_ serviceLevel: ServiceLoggingLevel) {
        self.init(fromString: serviceLevel.rawValue)
    }
}
