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

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation

//
// MARK: Log Level Type
//

public enum LogLevel: Int, Comparable {
    case debug
    case info
    case warn
    case error
}

public extension LogLevel {
    init(fromString levelString: String) {
        switch levelString.lowercased() {
        case "debug":
            self = .debug
        case "info":
            self = .info
        case "warn":
            self = .warn
        case "error":
            self = .error
        default:
            self = .info
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    static func == (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

//
// MARK: Log Interface
//
// Known Issues:
// - Prior to Swift 5.1, autoclosures are not allowed to use typealiases.

public struct Log {
    private static var stdOut: StdoutOutputStream = StdoutOutputStream()
    private static var stdErr: StderrOutputStream = StderrOutputStream()

    public private(set) static var date = DateFormatter(currentWithFormat: "dd MMM HH:mm:ss.SSS")
    public private(set) static var time = DateFormatter(currentWithFormat: "HH:mm:ss.SSS")

    public static func debug(_ closure: @autoclosure () -> Any, file: String = #file, line: Int = #line) {
        Log.logAnyClosure(closure, level: .debug, file: file, line: line)
    }

    public static func info(_ closure: @autoclosure () -> Any, file: String = #file, line: Int = #line) {
        Log.logAnyClosure(closure, level: .info, file: file, line: line)
    }

    public static func warn(_ closure: @autoclosure () -> Any, file: String = #file, line: Int = #line) {
        Log.logAnyClosure(closure, level: .warn, file: file, line: line)
    }

    public static func error(_ closure: @autoclosure () -> Any, file: String = #file, line: Int = #line) {
        Log.logAnyClosure(closure, level: .error, file: file, line: line)
    }

    public static func setLevel(default level: LogLevel) {
        Log.defaultLogLevel = level
    }

    public static func pushLevel(_ level: LogLevel) {
        Log.logLevelStack.append(level)
    }

    public static func popLevel() {
        _ = Log.logLevelStack.popLast()
    }

    private static var defaultLogLevel: LogLevel = .info
    private static var logLevelStack: [LogLevel] = []

    private static var logLevel: LogLevel {
        return Log.logLevelStack.last ?? Log.defaultLogLevel
    }

    private static func logAnyClosure(
        _ closure: () -> Any,
        level: LogLevel,
        file: String = #file,
        line: Int = #line
    ) {
        guard level >= Log.logLevel else { return }

        let message = closure()
        self.logItem(message, level: level, file: file, line: line)
    }

    private static func logItem(_ item: Any, level: LogLevel, file: String, line: Int) {
        guard level >= Log.logLevel else { return }

        let nowString = Log.time.string(from: Date())
        if Log.logLevel == .debug {
            let shortFileName = URL(fileURLWithPath: file).lastPathComponent
            print("[\(level)][\(nowString)][\(shortFileName):\(line)]",
                    item,
                    separator: " ",
                    terminator: "\n",
                    to: &Log.stdErr)
        } else {
            print("[\(level)][\(nowString)]",
                    item,
                    separator: " ",
                    terminator: "\n",
                    to: &Log.stdErr)
        }
    }
}

//
// MARK: Internal Types
//

private struct StderrOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stderr) }
}

private struct StdoutOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stdout) }
}

//
// MARK: Internal Extensions
//

extension DateFormatter {
    convenience init(currentWithFormat format: String) {
        self.init()
        self.dateFormat = format
        self.calendar = Calendar.current
        self.timeZone = TimeZone.current
    }
}
