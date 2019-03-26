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
import SingleBoard

class RaspberryPWM: LEDModuleImpl {
    internal let channelMap: [String : Int]

    private var arePinsEnabled: [Bool]
    private let pwm: BoardPWM
    private let period: UInt

    init(configuration: LEDModuleConfig, board: LEDBoardType) throws {
        guard board == .raspberryPi else {
            throw LEDModuleError.invalidBoardType(actual: board.rawValue)
        }

        let pwm = SingleBoard.raspberryPi.pwm
        self.arePinsEnabled = Array(repeating: false, count: pwm.count)

        // Configure Channels
        var channelMap: [String: Int] = [:]
        for (token, index) in configuration.channels where index >= 0 && index < pwm.count {
            channelMap[token] = index
        }

        self.channelMap = channelMap
        self.pwm = pwm

        // Calculate Period
        let frequency = configuration.frequency ?? 480
        let NANOSECONDS = 1_000_000_000
        self.period = UInt(NANOSECONDS / frequency)
    }

    func applyIntensity(_ intensity: Double, toChannel channel: Int) {
        guard channel < self.pwm.count else {
            Log.error("Attempted to apply intensity to unknown channel index: \(channel)")
            return
        }

        let output = self.pwm[channel]
        if !self.arePinsEnabled[channel] {
            output.enable(pins: output.pins)
            self.arePinsEnabled[channel] = true
        }

        let maxValue = 100.0
        let targetIntensity = Float(intensity * maxValue)

        output.start(period: self.period, dutyCycle: targetIntensity)
    }
}
