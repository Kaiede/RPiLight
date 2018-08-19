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

import Foundation

import Logging
import PWM

public typealias ChannelRateOfChange = (rate: Double, segmentStart: Date, segmentEnd: Date)

protocol ChannelLayer {
    var activeIndex: Int { get }

    func rateOfChange(forDate date: Date) -> ChannelRateOfChange
    func lightLevel(forDate now: Date) -> Double
}

public class ChannelController: BehaviorChannel {
    public var rootController: BehaviorController?
    var channel: Channel
    var layers: [ChannelLayer]

    init(channel: Channel) {
        self.rootController = nil
        self.channel = channel
        self.layers = []
    }

    func setBase(layer: ChannelLayer) {
        if self.layers.count == 0 {
            self.layers.append(layer)
        } else {
            self.layers[0] = layer
        }
        
        self.rootController?.invalidateRefreshTimer()
    }
    
    public func rateOfChange(forDate date: Date) -> ChannelRateOfChange {
        // brightnessRate is Units of Brightness (0-1) per Second
        var brightnessRate: Double = 0.0
        var segmentEnd: Date = Date.distantFuture
        var segmentStart: Date = Date.distantFuture
        for layer in self.layers {
            let (layerBrightnessRate, layerSegmentStart, layerSegmentEnd) = layer.rateOfChange(forDate: date)
            brightnessRate = max(brightnessRate, layerBrightnessRate)
            segmentStart = min(segmentStart, layerSegmentStart)
            segmentEnd = min(segmentEnd, layerSegmentEnd)
        }
        
        return (rate: brightnessRate, segmentStart: segmentStart, segmentEnd: segmentEnd)
    }

    public func update(forDate date: Date) {
        guard self.layers.count > 0 else {
            self.channel.setting = .intensity(0.0)
            return
        }
        
        var shouldInvalidate: Bool = false
        var channelBrightness: Double = 1.0
        for layer in self.layers {
            let oldIndex = layer.activeIndex
            let layerBrightness = layer.lightLevel(forDate: date)
            channelBrightness *= layerBrightness
            
            shouldInvalidate = shouldInvalidate || (oldIndex != layer.activeIndex)
        }

        self.channel.setting = .brightness(channelBrightness)
        if shouldInvalidate {
            self.rootController?.invalidateRefreshTimer()
        }
    }
}