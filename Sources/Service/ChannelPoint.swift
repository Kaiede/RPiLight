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
import LED

//
// Wrapper for Channel Settings
//
public enum ChannelSetting {
    case brightness(Brightness)
    case intensity(Intensity)
}

extension Brightness {
    public init(setting: ChannelSetting, gamma: Gamma) {
        switch setting {
        case .brightness(let brightness):
            self = brightness
        case .intensity(let intensity):
            self.init(intensity, gamma: gamma)
        }
    }
}

extension Intensity {
    public init(setting: ChannelSetting, gamma: Gamma) {
        switch setting {
        case .brightness(let brightness):
            self.init(brightness, gamma: gamma)
        case .intensity(let intensity):
            self = intensity
        }
    }
}

//
// Wrapper for Configuration that's compatible with Layers
//
protocol ChannelPoint {
    var time: DayTime { get }
    var setting: ChannelSetting { get }
}

extension ScheduleStepDescription: ChannelPoint {
    var setting: ChannelSetting {
        if let intensity = self.intensity {
            return .intensity(intensity)
        } else if let brightness = self.brightness {
            return .brightness(brightness)
        } else {
            return .intensity(0.0)
        }
    }
}
