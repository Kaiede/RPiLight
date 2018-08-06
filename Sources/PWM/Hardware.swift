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

import Logging
import SwiftyGPIO

class HardwarePWM: Module, CustomStringConvertible {
    private(set) var isDisposed: Bool = false
    private(set) lazy var availableChannels: [String] = {
        [unowned self] in
        return Array(self.availableChannelMap.keys)
        }()

    let pwms: [Int: [GPIOName: PWMOutput]]
    private(set) lazy var availableChannelMap: [String: PWMOutput] = {
        [unowned self] in
        return self.calculateAvailableChannels()
        }()

    func calculateAvailableChannels() -> [String: PWMOutput] {
        var channels: [String: PWMOutput] = [:]
        channels["PWM0-IO18"] = (self.pwms[0]?[.P18])!
        channels["PWM1-IO19"] = (self.pwms[1]?[.P19])!

        return channels
    }

    let frequency: Int

    init(channelCount: Int, frequency: Int) throws {
        guard let pwms = SwiftyGPIO.hardwarePWMs(for: .RaspberryPiPlusZero) else {
            throw ModuleInitError.noHardwareAccess
        }
        guard channelCount > 0 && channelCount <= pwms.count else {
            throw ModuleInitError.invalidChannelCount(min: 1, max: 2, actual: channelCount)
        }
        guard frequency % 480 == 0 && frequency <= 2880 else {
            throw ModuleInitError.invalidFrequency(min: 480, max: 480, actual: frequency)
        }

        self.pwms = pwms
        self.frequency = frequency
    }

    func createChannel(with token: String) throws -> Channel {
        guard let output = self.availableChannelMap[token] else {
            throw ChannelInitError.invalidToken
        }

        let NANOSECONDS = 1_000_000_000
        let period = NANOSECONDS / self.frequency
        Log.debug("Channel \(token) created with period of \(period) ns")
        return HardwarePWMChannel(token: token, output: output, period: period)
    }
}

class HardwarePWMChannel: Channel {
    let token: String
    var intensity: Double {
        didSet { self.onIntensityChanged() }
    }

    let period: Int         // nanoseconds
    let output: PWMOutput

    init(token: String, output: PWMOutput, period: Int) {
        self.token = token
        self.period = period
        self.intensity = 0.0
        self.output = output

        self.output.initPWM()
    }

    func onIntensityChanged() {
        let maxValue = 100.0
        let targetIntensity = Float(self.intensity * maxValue)
        Log.debug("\(self.token): Intensity Now \(targetIntensity)")
        
        output.startPWM(period: self.period, duty: targetIntensity)
    }
}
