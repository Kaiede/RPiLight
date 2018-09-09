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

//
// Simulated PWM Module
//

class SimulatedPWM: Module, CustomStringConvertible {
    private let gamma: Double

    private(set) lazy var availableChannels: [String] = {
        [unowned self] in
        return self.calculateAvailableChannels()
        }()

    func calculateAvailableChannels() -> [String] {
        var channels: [String] = []

        for index in 0...15 {
            channels.append(String(format: "SIM%02d", index))
        }

        return channels
    }

    init(frequency: Int, gamma: Double) throws {
        guard frequency % 480 == 0 && frequency <= 480 else {
            throw ModuleInitError.invalidFrequency(min: 480, max: 480, actual: frequency)
        }

        self.gamma = gamma
    }

    func createChannel(with token: String) throws -> Channel {
        guard self.channelTokenIsValid(token) else {
            throw ChannelInitError.invalidToken
        }

        return SimulatedPWMChannel(token: token, gamma: self.gamma)
    }
}

//
// Simulated PWM Channel
//

class SimulatedPWMChannel: Channel {
    let token: String
    let gamma: Double
    var minIntensity: Double
    var setting: ChannelSetting {
        didSet { self.onSettingChanged() }
    }

    init(token: String, gamma: Double) {
        self.token = token
        self.gamma = gamma
        self.minIntensity = 0.0
        self.setting = .intensity(0.0)
    }

    func onSettingChanged() {
        var intensity = self.setting.asIntensity(withGamma: self.gamma)
        if intensity < self.minIntensity.nextUp {
            intensity = 0.0
        }
        
        Log.debug("\(self.token): Intensity Now \(intensity * 100)")
    }

}
