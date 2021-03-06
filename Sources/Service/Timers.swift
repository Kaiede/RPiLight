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

import Dispatch
import Foundation
import Logging

typealias TimerHandler = () -> Void

class Timer<IDType> {
    public private(set) var timerId: IDType
    private var source: DispatchSourceTimer
    private var handler: TimerHandler?
    public private(set) var isSuspended: Bool

    public init(identifier: IDType, queue: DispatchQueue) {
        self.timerId = identifier
        self.handler = nil
        self.isSuspended = true

        // Initialize, and ensure we are in the cancelled state
        self.source = DispatchSource.makeTimerSource(flags: [], queue: queue)

        self.source.setRegistrationHandler { self.onRegistration() }
        self.source.setCancelHandler { self.onCancel() }
        self.source.setEventHandler { self.onEvent() }
    }

    public func setHandler(handler: @escaping TimerHandler) {
        self.handler = handler
    }

    public func schedule(at date: Date) {
        pause()
        self.source.schedulePrecise(forDate: date)
        start()

        log.debug("[\(timerId)] Scheduled For \(logDate.string(from: date))")
    }

    public func schedule(startingAt date: Date, repeating interval: DispatchTimeInterval) {
        pause()
        self.source.schedulePrecise(forDate: date, repeating: interval)
        start()

        log.debug({
            let intervalMs = interval.toTimeInterval() * 1_000.0
            return "[\(timerId)] Scheduled For \(logDate.string(from: date)), Repeating \(intervalMs) ms"
        }())
    }

    public func pause() {
        if !self.isSuspended {
            self.source.suspend()
            self.isSuspended = true
        }
    }

    private func start() {
        if self.isSuspended {
            self.source.resume()
            self.isSuspended = false
        }
    }

    private func onRegistration() {
        log.debug("[\(timerId)] Registered")
    }

    private func onCancel() {
        log.debug("[\(timerId)] Cancelled")
    }

    private func onEvent() {
        log.debug({
            let hasHandler = self.handler != nil
            return "[\(timerId)] Event Fired. Valid Handler: \(hasHandler)"
        }())
        self.handler?()
    }
}
