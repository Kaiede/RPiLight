/*
 RPiLight

 Copyright (c) 2019 Adam Thayer
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

public protocol UnitType: RawRepresentable, Comparable, ExpressibleByFloatLiteral, SignedNumeric, Codable {
    var rawValue: Double { set get }
    init(rawValue: Double)
}

public extension UnitType {
    init?<T>(exactly source: T) where T : BinaryInteger {
        guard let value = Double(exactly: source) else { return nil }
        
        self.init(rawValue: value)
    }
    
    init(floatLiteral value: Double)  {
        self.init(rawValue: Double(value))
    }
    
    init(integerLiteral value: Int) {
        self.init(rawValue: Double(value))
    }
}

public extension UnitType {
    var magnitude: Self { return Self(rawValue: abs(self.rawValue)) }
}

public func + <T: UnitType> (lhs: T, rhs: T) -> T {
    return T(rawValue: lhs.rawValue + rhs.rawValue)
}

public func += <T: UnitType> (lhs: inout T, rhs: T) {
    lhs.rawValue += rhs.rawValue
}

public func - <T: UnitType> (lhs: T, rhs: T) -> T {
    return T(rawValue: lhs.rawValue - rhs.rawValue)
}

public func -= <T: UnitType> (lhs: inout T, rhs: T) {
    lhs.rawValue -= rhs.rawValue
}

public func * <T: UnitType> (lhs: T, rhs: T) -> T {
    return T(rawValue: lhs.rawValue * rhs.rawValue)
}

public func *= <T: UnitType> (lhs: inout T, rhs: T) {
    lhs.rawValue *= rhs.rawValue
}

public func == <T: UnitType> (lhs: T, rhs: T) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

public func < <T: UnitType> (lhs: T, rhs: T) -> Bool {
    return lhs.rawValue < rhs.rawValue
}


public struct Gamma: UnitType {
    public typealias Magnitude = Gamma
    public typealias IntegerLiteralType = Int
    public typealias FloatLiteralType = Double
    
    public var rawValue: Double
    public init(rawValue: Double) { self.rawValue = rawValue }
}

public struct Intensity: UnitType {
    public typealias Magnitude = Intensity
    public typealias IntegerLiteralType = Int
    public typealias FloatLiteralType = Double
    
    public var rawValue: Double
    public init(rawValue: Double) { self.rawValue = rawValue }
    public init(_ brightness: Brightness, gamma: Gamma) { self.rawValue = pow(brightness.rawValue, gamma.rawValue) }
    
    internal func toSteps(max: UInt) -> UInt {
        return UInt(self.rawValue * Double(max))
    }
    
    internal func toPercentage() -> Float {
        return Float(self.rawValue * 100.0)
    }
}

public struct Brightness: UnitType {
    public typealias Magnitude = Brightness
    public typealias IntegerLiteralType = Int
    public typealias FloatLiteralType = Double
    
    public var rawValue: Double
    public init(rawValue: Double) { self.rawValue = rawValue }
    public init(_ intensity: Intensity, gamma: Gamma) { self.rawValue = pow(intensity.rawValue, (1.0 / gamma.rawValue)) }
}
