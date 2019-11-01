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
import MCP4725
import SingleBoard

//
// DAC (0-10V) Output via MCP4725
//

class DacViaMCP4725: LEDModuleImpl {
    private let controller: MCP4725
    internal let channelMap: [String: Int]

    init(configuration: LEDModuleConfig, board: LEDBoardType) throws {
        guard board == .raspberryPi else {
            throw LEDModuleError.invalidBoardType(actual: board.rawValue)
        }

        let address: UInt8 = configuration.addressAsI2C ?? MCP4725.defaultAddress

        self.controller = MCP4725(i2cBus: SingleBoard.raspberryPi.i2cMainBus, address: address)

        // Since we are taking this controller over, we can get away with updating the EEPROM default
        // to off for now like other modules. In the future, this can probably be made a little more 
        // configurable. 
        self.controller.setDefault(voltage: 0, mode: .normal)

        // This is unusual for single-channel configurations. Is there some sugar we can use here?
        var channelMap: [String: Int] = [:]
        for (token, index) in configuration.channels where index < 1 {
            channelMap[token] = index
        }

        self.channelMap = channelMap
    }

    internal func applyIntensity(_ intensity: Intensity, toChannel channel: Int) {
        guard channel < 1 else {
            Log.error("Attempted to apply intensity to unknown channel index: \(channel)")
            return
        }

        let step = UInt16(intensity.toSteps(max: 4095))
        self.controller.set(voltage: step)
    }
}
