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
import LED

public protocol ChannelSegment {
    var startBrightness: Brightness { get }
    var endBrightness: Brightness { get }
    var startDate: Date { get }
    var endDate: Date { get }
}

extension ChannelSegment {
    var deltaBrightnessChange: Double {
        return self.endBrightness.rawValue - self.startBrightness.rawValue
    }

    var totalBrightnessChange: Double {
        return abs(self.deltaBrightnessChange)
    }

    var duration: TimeInterval {
        return self.endDate.timeIntervalSince(self.startDate)
    }

    public func interpolateBrightness(forDate date: Date) -> Brightness {
        if date <= self.startDate {
            return self.startBrightness
        } else if date >= self.endDate {
            return self.endBrightness
        } else {
            let spentInterval = date.timeIntervalSince(self.startDate)
            let factor = spentInterval / self.duration

            return self.startBrightness + Brightness(rawValue: factor * self.deltaBrightnessChange)
        }
    }
}

public protocol ChannelLayer {
    var activeIndex: Int { get }

    func segment(forDate date: Date) -> ChannelSegment
    func lightLevel(forDate now: Date) -> Brightness
}

// Wrapper that allows for merging multiple ChannelSegments
struct ChannelControllerSegment: ChannelSegment {
    var startBrightness: Brightness = 1.0
    var endBrightness: Brightness = 1.0

    var startDate: Date = Date.distantPast
    var endDate: Date = Date.distantFuture

    mutating func unionByLayer(withSegment segment: ChannelSegment) {
        // Get the segment time that represents the union of the two.
        let newStartDate = max(self.startDate, segment.startDate)
        let newEndDate = min(self.endDate, segment.endDate)

        let startBrightness = self.interpolateBrightness(forDate: newStartDate)
        let endBrightness = self.interpolateBrightness(forDate: newEndDate)

        let segmentStartBrightness = segment.interpolateBrightness(forDate: newStartDate)
        let segmentEndBrightness = segment.interpolateBrightness(forDate: newEndDate)

        self.startDate = newStartDate
        self.endDate = newEndDate
        self.startBrightness = startBrightness * segmentStartBrightness
        self.endBrightness = endBrightness * segmentEndBrightness
    }

    mutating func unionByChannel(withSegment segment: ChannelSegment) {
        let newStartDate = max(self.startDate, segment.startDate)
        let newEndDate = min(self.endDate, segment.endDate)

        let startBrightness = self.interpolateBrightness(forDate: newStartDate)
        let endBrightness = self.interpolateBrightness(forDate: newEndDate)

        let segmentStartBrightness = segment.interpolateBrightness(forDate: newStartDate)
        let segmentEndBrightness = segment.interpolateBrightness(forDate: newEndDate)

        self.startDate = newStartDate
        self.endDate = newEndDate
        let myTotalDelta = abs(endBrightness.rawValue - startBrightness.rawValue)
        let otherTotalDelta = abs(segmentEndBrightness.rawValue - segmentStartBrightness.rawValue)
        if myTotalDelta > otherTotalDelta {
            self.startBrightness = startBrightness
            self.endBrightness = endBrightness
        } else {
            self.startBrightness = segmentStartBrightness
            self.endBrightness = segmentEndBrightness
        }
    }
}

public enum ChannelLayerType: Int {
    case schedule
    case lunar
}

public protocol Channel {
    var token: String { get }
    var minIntensity: Intensity { get set }
    var intensity: Intensity { get set }
}

public class ChannelController: BehaviorChannel {
    public var rootController: BehaviorController?
    var channel: Channel
    var layers: [ChannelLayer?]

    public var channelGamma: Gamma {
        return rootController?.configuration.gamma ?? 1.8
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
            channelSegment.unionByLayer(withSegment: layerSegment)
        }

        return channelSegment
    }

    public func update(forDate date: Date) {
        let activeLayers = self.activeLayers
        guard activeLayers.count > 0 else {
            Log.warn("No Active Layers in Channel")
            self.channel.intensity = 0.0
            return
        }

        var shouldInvalidate: Bool = false
        var channelBrightness: Brightness = 1.0
        for layer in activeLayers {
            let oldIndex = layer.activeIndex
            let layerBrightness = layer.lightLevel(forDate: date)
            channelBrightness *= layerBrightness

            shouldInvalidate = shouldInvalidate || (oldIndex != layer.activeIndex)
        }

        self.channel.intensity = Intensity(channelBrightness, gamma: self.channelGamma)
        if shouldInvalidate {
            Log.debug("Invalidating Refresh Because of Channel: \(self.channel.token)")
            self.rootController?.invalidateRefreshTimer()
        }
    }
}
