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

public protocol ChannelSegment {
    var startBrightness: Double { get }
    var endBrightness: Double { get }
    var startDate: Date { get }
    var endDate: Date { get }
}

extension ChannelSegment {
    var totalBrightnessChange: Double {
        return abs(self.endBrightness - self.startBrightness)
    }
    
    var duration: TimeInterval {
        return self.endDate.timeIntervalSince(self.startDate)
    }
}

public protocol ChannelLayer {
    var activeIndex: Int { get }

    func segment(forDate date: Date) -> ChannelSegment
    func lightLevel(forDate now: Date) -> Double
}

// Wrapper that allows for merging multiple ChannelSegments
struct ChannelControllerSegment: ChannelSegment {
    var startBrightness: Double = 0.0
    var endBrightness: Double = 0.0
    
    var startDate: Date = Date.distantFuture
    var endDate: Date = Date.distantFuture
    
    mutating func union(withSegment segment: ChannelSegment) {
        self.startBrightness = max(self.startBrightness, segment.startBrightness)
        self.endBrightness = max(self.endBrightness, segment.endBrightness)
        self.startDate = min(self.startDate, segment.startDate)
        self.endDate = min(self.endDate, segment.endDate)
    }
}

public enum ChannelLayerType: Int {
    case schedule
    case lunar
}

public class ChannelController: BehaviorChannel {
    public var rootController: BehaviorController?
    var channel: Channel
    var layers: [ChannelLayer?]

    public var channelGamma: Double {
        return channel.gamma
    }

    var activeLayers: [ChannelLayer] {
        return self.layers.compactMap { $0 }
    }

    init(channel: Channel) {
        self.rootController = nil
        self.channel = channel
        self.layers = [nil, nil]
    }

    public func set(layer: ChannelLayer, forType type: ChannelLayerType = .schedule) {
        self.layers[type.rawValue] = layer
        self.rootController?.invalidateRefreshTimer()
    }
    
    public func segment(forDate date: Date) -> ChannelSegment {
        var channelSegment = ChannelControllerSegment()
        for layer in self.activeLayers {
            let layerSegment = layer.segment(forDate: date)
            channelSegment.union(withSegment: layerSegment)
        }

        return channelSegment
    }

    public func update(forDate date: Date) {
        let activeLayers = self.activeLayers
        guard activeLayers.count > 0 else {
            self.channel.setting = .intensity(0.0)
            return
        }
        
        var shouldInvalidate: Bool = false
        var channelBrightness: Double = 1.0
        for layer in activeLayers {
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
