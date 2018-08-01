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

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import SwiftyGPIO

// Default Address
let PCA9685_ADDRESS    = 0x40

// Registers
let MODE1 : UInt8              = 0x00
let MODE2 : UInt8              = 0x01
let SUBADR1 : UInt8            = 0x02
let SUBADR2 : UInt8            = 0x03
let SUBADR3 : UInt8            = 0x04
let PRESCALE : UInt8           = 0xFE
let LED0_ON_L : UInt8          = 0x06
let LED0_ON_H : UInt8          = 0x07
let LED0_OFF_L : UInt8         = 0x08
let LED0_OFF_H : UInt8         = 0x09
let ALL_LED_ON_L : UInt8       = 0xFA
let ALL_LED_ON_H : UInt8       = 0xFB
let ALL_LED_OFF_L : UInt8      = 0xFC
let ALL_LED_OFF_H : UInt8      = 0xFD


let RESTART : UInt8            = 0x80
let SLEEP : UInt8              = 0x10
let ALLCALL : UInt8            = 0x01
let INVRT : UInt8              = 0x10
let OUTDRV : UInt8             = 0x04

public class PCA9685 {
    public var frequency : UInt {
        didSet {
            self.onFrequencyChanged()
        }
    }

    private let address : Int
    private let i2c : I2CInterface
    
    public init(address: Int = PCA9685_ADDRESS) {
        self.frequency = 0
        self.address = address
        
        let i2cs = SwiftyGPIO.hardwareI2Cs(for:.RaspberryPiPlusZero)!
        self.i2c = i2cs[1]
        
        // Now, Configure the PCA9685
        self.setAllChannels(on: 0, off: 0)
        self.i2c.writeByte(self.address, command: MODE2, value: OUTDRV)
        self.i2c.writeByte(self.address, command: MODE1, value: ALLCALL)

        // Wait for Oscillator
        usleep(5)
        
        // Reset Sleep
        var mode1 = self.i2c.readByte(self.address, command: MODE1)
        mode1 = mode1 & ~SLEEP
        self.i2c.writeByte(self.address, command: MODE1, value: mode1)

        // Wait for Oscillator
        usleep(5)
    }
    
    public func setChannel(_ channel: UInt8, on: UInt16, off: UInt16) {
        guard channel < 16 else { fatalError("channel must be 0-15") }

        let commandOn = LED0_ON_L + (4 * channel)
        let commandOff = LED0_OFF_L + (4 * channel)
        
        self.i2c.writeWord(self.address, command: commandOn, value: on)
        self.i2c.writeWord(self.address, command: commandOff, value: off)
    }
    
    public func setAllChannels(on: UInt16, off: UInt16) {
        self.i2c.writeWord(self.address, command: ALL_LED_ON_L, value: on)
        self.i2c.writeWord(self.address, command: ALL_LED_OFF_L, value: off)
    }
    
    func onFrequencyChanged() {
        // Calculate Prescale
        var prescaleFlt : Float = 25000000.0    // 25MHz
        prescaleFlt /= 4096.0           // 12-Bit
        prescaleFlt /= Float(self.frequency)
        prescaleFlt -= 1.0
        
        let prescale = UInt8(prescaleFlt + 0.5)
        
        // Go To Sleep
        let mode1 = self.i2c.readByte(self.address, command: MODE1)
        let sleepMode = mode1 & ~RESTART | SLEEP
        self.i2c.writeByte(self.address, command: MODE1, value: sleepMode)
        self.i2c.writeByte(self.address, command: PRESCALE, value: prescale)
        self.i2c.writeByte(self.address, command: MODE1, value: mode1)
        
        // Restart
        let restartMode = mode1 | RESTART
        self.i2c.writeByte(self.address, command: MODE1, value: restartMode)
    }
}
