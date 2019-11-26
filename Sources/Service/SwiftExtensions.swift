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

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

//
// MARK: Foundation Extensions
//
public extension FileManager {
    var currentDirectoryUrl: URL {
        return URL(fileURLWithPath: self.currentDirectoryPath)
    }
}

public extension DateFormatter {
    convenience init(currentWithFormat format: String) {
        self.init()
        self.dateFormat = format
        self.calendar = Calendar.current
        self.timeZone = TimeZone.current
    }
}

//
// MARK: Dispatch Extensions
//
extension DispatchTimeInterval {
    func toTimeInterval() -> TimeInterval {
        switch self {
        case .seconds(let seconds):
            return TimeInterval(seconds)
        case .milliseconds(let milliseconds):
            return TimeInterval(milliseconds) * 1_000.0
        case .microseconds(let microseconds):
            return TimeInterval(microseconds) * 1_000_000.0
        case .nanoseconds(let nanoseconds):
            return TimeInterval(nanoseconds) * 1_000_000_000.0
        case .never:
            return TimeInterval.infinity
        @unknown default:
            fatalError("Unknown DispatchTimeInterval in toTimeInterval()")
        }
    }
}

extension DispatchWallTime {
    init(date: Date) {
        let nsecInSec: UInt64 = 1_000_000_000
        let interval = date.timeIntervalSince1970
        let spec = timespec(tv_sec: Int(interval), tv_nsec: Int(UInt64(interval * Double(nsecInSec)) % nsecInSec))
        self.init(timespec: spec)
    }
}

extension DispatchSourceTimer {
    public func schedulePrecise(forDate date: Date) {
        self.schedule(wallDeadline: DispatchWallTime(date: date), leeway: .milliseconds(1))
    }

    public func schedulePrecise(forDate date: Date, repeating interval: DispatchTimeInterval) {
        self.schedule(wallDeadline: DispatchWallTime(date: date), repeating: interval, leeway: .milliseconds(1))
    }
}

// MARK: User Functions
public func getUid(username: String) -> uid_t? {
    let user = getpwnam(username)?.pointee
    return user?.pw_uid
}

public func getUsername(uid: uid_t) -> String? {
    let user = getpwuid(uid)?.pointee
    guard let name = user?.pw_name else { return nil }
    return String(cString: name)
}

//
// MARK: Shorthand for pow() function
//
infix operator ** : MultiplicationPrecedence

func ** (num: Double, power: Double) -> Double {
    return pow(num, power)
}
