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
    private let gamma: Double

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

    init(channelCount: Int, frequency: Int, gamma: Double) throws {
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
        self.gamma = gamma
    }

    func createChannel(with token: String) throws -> Channel {
        guard let output = self.availableChannelMap[token] else {
            throw ChannelInitError.invalidToken
        }

        let NANOSECONDS = 1_000_000_000
        let period = NANOSECONDS / self.frequency
        Log.debug("Channel \(token) created with period of \(period) ns")
        return HardwarePWMChannel(token: token, gamma: self.gamma, output: output, period: period)
    }
}

class HardwarePWMChannel: Channel {
    let token: String
    let gamma: Double
    var minIntensity: Double
    var setting: ChannelSetting {
        didSet { self.onSettingChanged() }
    }

    let period: Int         // nanoseconds
    let output: PWMOutput

    init(token: String, gamma: Double, output: PWMOutput, period: Int) {
        self.token = token
        self.gamma = gamma
        self.minIntensity = 0.0
        self.setting = .intensity(0.0)
        self.period = period
        self.output = output

        self.output.initPWM()
    }

    func onSettingChanged() {
        var intensity = self.setting.asIntensity(withGamma: self.gamma)
        if intensity < IntensityPrecision {
            intensity = 0.0
        } else {
            intensity = self.minIntensity + (intensity * (1.0 - self.minIntensity))
        }
        
        let maxValue = 100.0
        let targetIntensity = Float(intensity * maxValue)
        Log.debug("\(self.token): Intensity Now \(targetIntensity)")
        
        output.startPWM(period: self.period, duty: targetIntensity)
    }
}
