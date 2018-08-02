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
// Simulated PWM Module
//

class SimulatedPWM : Module, CustomStringConvertible {
	private(set) var isDisposed: Bool = false

	private let channelCount: Int
	private(set) lazy var availableChannels: [String] = {
		[unowned self] in
		return self.calculateAvailableChannels() 
	}()


	func calculateAvailableChannels() -> [String] {
		var channels : [String] = []

		for i in 0..<self.channelCount {
			channels.append(String(format: "SIM%02d", i))
		}

		return channels
	}


	init(channelCount: Int, frequency: Int) throws {
		guard channelCount > 0 && channelCount < 16 else {
			throw ModuleInitError.invalidChannelCount(min: 1, max: 16)
		}
		guard frequency % 480 == 0 && frequency <= 480 else {
			throw ModuleInitError.invalidFrequency(min: 480, max: 480)
		}

		self.channelCount = channelCount
	}


	func createChannel(with token: String) throws -> Channel  {
		guard self.channelTokenIsValid(token) else {
			throw ChannelInitError.invalidToken
		}

		return SimulatedPWMChannel(token: token)
	}
}


//
// Simulated PWM Channel
//

class SimulatedPWMChannel : Channel {
	let token: String
	var luminance: Double {
		didSet { self.onLuminanceChanged() }
	}


	init(token: String) {
		self.token = token
		self.luminance = 0.0
	}


	func onLuminanceChanged() {
		print("\(self.token): Luminance Now \(self.luminance * 100)")
	}	
}
