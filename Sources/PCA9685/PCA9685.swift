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

public enum Address: Int {
    case pca9685     = 0x40
}

enum Register: UInt8 {
    case mode1       = 0x00
    case mode2       = 0x01
    case subAdr1     = 0x02
    case subAdr2     = 0x03
    case subAdr3     = 0x04
    case prescale    = 0xFE
    case ledOnBase   = 0x06 // Word
    case ledOffBase  = 0x08 // Word
    case allLedOn    = 0xFA // Word
    case allLedOff   = 0xFC // Word

    func offsetBy(_ offset: Int) -> UInt8 {
        return UInt8(Int(self.rawValue) + offset)
    }
}

struct Mode1: OptionSet {
    let rawValue: UInt8

    static let allCall     = Mode1(rawValue: 0x01)
    static let sleep       = Mode1(rawValue: 0x10)
    static let autoInc     = Mode1(rawValue: 0x20)
    static let restart     = Mode1(rawValue: 0x80)
}

struct Mode2: OptionSet {
    let rawValue: UInt8

    static let outDrv      = Mode2(rawValue: 0x04)
    static let invert      = Mode2(rawValue: 0x10)
}

extension I2CInterface {
    func writeMode1(_ address: Address, value: Mode1) {
        self.writeByte(address, command: .mode1, value: value.rawValue)
    }

    func writeMode2(_ address: Address, value: Mode2) {
        self.writeByte(address, command: .mode2, value: value.rawValue)
    }

    func writeByte(_ address: Address, command: Register, value: UInt8) {
        self.writeByte(address.rawValue, command: command.rawValue, value: value)
    }

    func writeWord(_ address: Address, command: Register, value: UInt16) {
        self.writeWord(address.rawValue, command: command.rawValue, value: value)
    }

    func readMode1(_ address: Address) -> Mode1 {
        return Mode1(rawValue: self.readByte(address, command: .mode1))
    }

    func readMode2(_ address: Address) -> Mode2 {
        return Mode2(rawValue: self.readByte(address, command: .mode2))
    }

    func readByte(_ address: Address, command: Register) -> UInt8 {
        return self.readByte(address.rawValue, command: command.rawValue)
    }

    func readWord(_ address: Address, command: Register) -> UInt16 {
        return self.readWord(address.rawValue, command: command.rawValue)
    }

}

public class PCA9685 {
    public var frequency: UInt {
        didSet {
            self.onFrequencyChanged()
        }
    }

    private let address: Address
    private let i2c: I2CInterface

    public init(supportedBoard: SupportedBoard, address: Address = .pca9685) {
        self.frequency = 0
        self.address = address

        let i2cs = SwiftyGPIO.hardwareI2Cs(for: supportedBoard)!
        self.i2c = i2cs[1]

        guard self.i2c.isReachable(self.address.rawValue) else {
            fatalError("I2C Address is Unreachable")
        }

        // Now, Configure the PCA9685
        self.setAllChannels(onStep: 0, offStep: 0)
        self.i2c.writeMode2(self.address, value: [.outDrv])
        self.i2c.writeMode1(self.address, value: [.allCall])

        // Wait for Oscillator
        usleep(5)

        // Reset Sleep, Set Auto Increment (for writeWord)
        let mode1 = self.i2c.readMode1(self.address)
        let setupMode1 = mode1.subtracting([.sleep]).union([.autoInc])
        self.i2c.writeMode1(self.address, value: setupMode1)

        // Wait for Oscillator
        usleep(5)
    }

    public func setChannel(_ channel: UInt8, onStep: UInt16, offStep: UInt16) {
        guard channel < 16 else { fatalError("channel must be 0-15") }

        let commandOn = Register.ledOnBase.offsetBy(4 * Int(channel))
        let commandOff = Register.ledOffBase.offsetBy(4 * Int(channel))

        self.i2c.writeWord(self.address.rawValue, command: commandOn, value: onStep)
        self.i2c.writeWord(self.address.rawValue, command: commandOff, value: offStep)
    }

    public func setAllChannels(onStep: UInt16, offStep: UInt16) {
        self.i2c.writeWord(self.address, command: .allLedOn, value: onStep)
        self.i2c.writeWord(self.address, command: .allLedOff, value: offStep)
    }

    func onFrequencyChanged() {
        // Calculate Prescale
        var prescaleFlt = 25000000.0    // 25MHz
        prescaleFlt /= 4096.0           // 12-Bit
        prescaleFlt /= Double(self.frequency)
        prescaleFlt -= 1.0

        let prescale = UInt8(prescaleFlt + 0.5)

        // Go To Sleep & Set Prescale
        let mode1 = self.i2c.readMode1(self.address)
        let sleepMode = mode1.subtracting([.restart]).union([.sleep])
        self.i2c.writeMode1(self.address, value: sleepMode)
        self.i2c.writeByte(self.address, command: .prescale, value: prescale)
        self.i2c.writeMode1(self.address, value: mode1)

        usleep(5)

        // Restart
        let restartMode = mode1.union([.restart])
        self.i2c.writeMode1(self.address, value: restartMode)
    }
}
