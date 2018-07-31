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


//
// ModuleType
//
// Wrapper around the different module types. Provides access to the different
// modes in a safe way.
// 

public enum ModuleType {
	case simulated
	case hardware

	public func createModule(channelCount: Int, frequency: Int) throws -> Module {
		switch(self) {
		case .simulated:
			return try SimulatedPWM(channelCount: channelCount, frequency: frequency)
		case .hardware:
			return try HardwarePWM(channelCount: channelCount, frequency: frequency)
		}
	}
}

//
// ModuleInitError
//

public enum ModuleInitError: Error {
	case noHardwareAccess
	case invalidChannelCount(min: Int, max: Int)
	case invalidFrequency(min: Int, max: Int)
}


//
// Module Protocol
//
// Public protocol for interacting with a PWM module
//

public protocol Module {
	var availableChannels: [String] { get }

	func createChannel(with token: String) throws -> Channel
}


public extension Module {
	func channelTokenIsValid(_ token: String) -> Bool {
		return self.availableChannels.contains(token)
	}
}


public extension Module where Self : CustomStringConvertible {
	var description: String {
		return "\(self.availableChannels)"
	}
}


//
// Channel Protocol
//
// Protocol for interacting with a single PWM channel. 
// Includes convenience handlers for interacting with gamma correction
//

public enum ChannelInitError: Error {
	case invalidToken
}


public protocol Channel {
	var token: String { get }
	var luminance: Float { get set }
}


let GAMMA: Float = 1.8
public extension Channel {
	var brightness: Float {
		get {
			return self.luminance ** (1.0 / GAMMA)
		}
		set(newBrightness) {
			
			let brightness = min(max(newBrightness, 0.0), 1.0)
			let luminance = brightness ** GAMMA
			self.luminance = luminance
		}
	}
}










