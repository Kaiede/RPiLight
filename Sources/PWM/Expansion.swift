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

import PCA9685

//
// Expansion PWM Module (PCA 9685)
//

class ExpansionPWM: Module, CustomStringConvertible {
    private(set) lazy var availableChannels: [String] = {
        [unowned self] in
        return Array(self.availableChannelMap.keys)
        }()

    private(set) lazy var availableChannelMap: [String: UInt8] = {
        [unowned self] in
        return self.calculateAvailableChannels()
        }()

    func calculateAvailableChannels() -> [String: UInt8] {
        var channels: [String: UInt8] = [:]
        for i in 0..<self.channelCount {
            channels[String(format: "PWM%02d", i)] = UInt8(i)
        }

        return channels
    }

    private let channelCount: Int
    private let controller: PCA9685

    init(channelCount: Int, frequency: Int) throws {
        guard channelCount > 0 && channelCount <= 16 else {
            throw ModuleInitError.invalidChannelCount(min: 1, max: 16)
        }
        guard frequency % 480 == 0 && frequency <= 1440 else {
            throw ModuleInitError.invalidFrequency(min: 480, max: 1440)
        }

        self.channelCount = channelCount
        self.controller = PCA9685()
        self.controller.frequency = UInt(frequency)
    }

    func createChannel(with token: String) throws -> Channel {
        guard let channel = self.availableChannelMap[token] else {
            throw ChannelInitError.invalidToken
        }

        return ExpansionPWMChannel(token: token, channel: channel, controller: self.controller)
    }
}

//
// Simulated PWM Channel
//

class ExpansionPWMChannel: Channel {
    let token: String
    var luminance: Double {
        didSet { self.onLuminanceChanged() }
    }

    private let controller: PCA9685
    private let channel: UInt8

    init(token: String, channel: UInt8, controller: PCA9685) {
        self.token = token
        self.luminance = 0.0
        self.channel = channel
        self.controller = controller
    }

    func onLuminanceChanged() {
        let steps = UInt16(self.luminance * 4095)
        self.controller.setChannel(self.channel, onStep: 0, offStep: steps)
    }
}
