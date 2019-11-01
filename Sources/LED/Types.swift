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

infix operator ** : MultiplicationPrecedence

fileprivate func ** (num: Double, power: Double) -> Double {
    return pow(num, power)
}

public struct Gamma: RawRepresentable, Comparable, Equatable, Codable {
    public private(set) var rawValue: Double

    public init(rawValue: Double) { self.rawValue = rawValue }
    public init(_ rawValue: Double) { self.rawValue = rawValue }
    public init(_ other: Gamma) { self.rawValue = other.rawValue }
    
    static public func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue.nextUp
    }
}

public struct Intensity: RawRepresentable, Comparable, Equatable, Codable {
    public private(set) var rawValue: Double

    public init(rawValue: Double) { self.rawValue = rawValue }
    public init(_ rawValue: Double) { self.rawValue = rawValue }
    public init(_ other: Intensity) { self.rawValue = other.rawValue }
    public init(_ brightness: Brightness, gamma: Gamma) { self.rawValue = brightness.rawValue ** gamma.rawValue }
    
    internal func toSteps(max: UInt) -> UInt {
        return UInt(self.rawValue * Double(max))
    }
    
    internal func toPercentage() -> Float {
        return Float(self.rawValue * 100.0)
    }
    
    static public func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue.nextUp
    }

    static public func + (lhs: Self, rhs: Double) -> Self {
        return Self(lhs.rawValue + rhs)
    }
    
    static public func += (lhs: inout Self, rhs: Double) {
        lhs.rawValue += rhs
    }
    
    static public func - (lhs: Self, rhs: Double) -> Self {
        return Self(lhs.rawValue + rhs)
    }
    
    static public func -= (lhs: inout Self, rhs: Double) {
        lhs.rawValue -= rhs
    }
    
    static public func * (lhs: Self, rhs: Double) -> Self {
        return Self(lhs.rawValue * rhs)
    }
    
    static public func * (lhs: Self, rhs: Self) -> Self {
        return Self(lhs.rawValue * rhs.rawValue)
    }
    
    static public func *= (lhs: inout Self, rhs: Double) {
        lhs.rawValue *= rhs
    }
    
    static public func *= (lhs: inout Self, rhs: Self) {
        lhs.rawValue *= rhs.rawValue
    }
}

public struct Brightness: RawRepresentable, Comparable, Equatable, Codable {
    public private(set) var rawValue: Double

    public init(rawValue: Double) { self.rawValue = rawValue }
    public init(_ rawValue: Double) { self.rawValue = rawValue }
    public init(_ other: Brightness) { self.rawValue = other.rawValue }
    public init(_ intensity: Intensity, gamma: Gamma) { self.rawValue = intensity.rawValue ** (1.0 / gamma.rawValue) }
    
    static public func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue.nextUp
    }

    static public func + (lhs: Self, rhs: Double) -> Self {
        return Self(lhs.rawValue + rhs)
    }
    
    static public func += (lhs: inout Self, rhs: Double) {
        lhs.rawValue += rhs
    }

    static public func - (lhs: Self, rhs: Double) -> Self {
        return Self(lhs.rawValue + rhs)
    }
    
    static public func -= (lhs: inout Self, rhs: Double) {
        lhs.rawValue -= rhs
    }
    
    static public func * (lhs: Self, rhs: Double) -> Self {
        return Self(lhs.rawValue * rhs)
    }
    
    static public func * (lhs: Self, rhs: Self) -> Self {
        return Self(lhs.rawValue * rhs.rawValue)
    }
    
    static public func *= (lhs: inout Self, rhs: Double) {
        lhs.rawValue *= rhs
    }
    
    static public func *= (lhs: inout Self, rhs: Self) {
        lhs.rawValue *= rhs.rawValue
    }
}

