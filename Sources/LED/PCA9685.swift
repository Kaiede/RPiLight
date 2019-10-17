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
import PCA9685
import SingleBoard

//
// PWM via PCA9685
//

class PwmViaPCA9685: LEDModuleImpl {
    private let controller: PCA9685
    internal let channelMap: [String: Int]

    init(configuration: LEDModuleConfig, board: LEDBoardType) throws {
        guard board == .raspberryPi else {
            throw LEDModuleError.invalidBoardType(actual: board.rawValue)
        }
        guard let frequency = configuration.frequency else {
            throw LEDModuleError.missingFrequency
        }
        guard frequency >= 480 && frequency <= 1500 else {
            throw LEDModuleError.invalidFrequency(min: 480, max: 1500, actual: frequency)
        }

        let address: UInt8 = configuration.addressAsI2C ?? PCA9685.defaultAdafruitAddress

        self.controller = PCA9685(i2cBus: SingleBoard.raspberryPi.i2cMainBus, address: address)
        self.controller.frequency = UInt(frequency)

        var channelMap: [String: Int] = [:]
        for (token, index) in configuration.channels where index < 16 {
            channelMap[token] = index
        }

        self.channelMap = channelMap
    }

    internal func applyIntensity(_ intensity: Double, toChannel channel: Int) {
        guard channel < 16 else {
            Log.error("Attempted to apply intensity to unknown channel index: \(channel)")
            return
        }

        let controllerChannel = UInt8(channel)
        let maxIntensity: Double = 4095
        let steps = UInt16(intensity * maxIntensity)

        self.controller.setChannel(controllerChannel, onStep: 0, offStep: steps)
    }
}
