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

public enum LogLevel: Int, Comparable {
    case debug
    case info
    case warn
    case error

    public init(fromString levelString: String) {
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

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    public static func == (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public typealias LogClosure = () -> Void
public typealias LogStringClosure = () -> String

public struct Log {
    private static var stdOut: StdoutOutputStream = StdoutOutputStream()
    private static var stdErr: StderrOutputStream = StderrOutputStream()

    public private(set) static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM HH:mm:ss.SSS"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public private(set) static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    public static func debug(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .debug, file: file, line: line)
    }

    public static func info(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .info, file: file, line: line)
    }

    public static func warn(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .warn, file: file, line: line)
    }

    public static func error(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .error, file: file, line: line)
    }

    public static func debug(file: String = #file, line: Int = #line, _ closure: LogStringClosure) {
        Log.performStringClosure(closure, level: .debug, file: file, line: line)
    }

    public static func info(file: String = #file, line: Int = #line, _ closure: LogStringClosure) {
        Log.performStringClosure(closure, level: .info, file: file, line: line)
    }

    public static func warn(file: String = #file, line: Int = #line, _ closure: LogStringClosure) {
        Log.performStringClosure(closure, level: .warn, file: file, line: line)
    }

    public static func error(file: String = #file, line: Int = #line, _ closure: LogStringClosure) {
        Log.performStringClosure(closure, level: .error, file: file, line: line)
    }

    public static func withDebug(_ closure: LogClosure) {
        Log.performClosure(closure, level: .debug)
    }

    public static func withInfo(_ closure: LogClosure) {
        Log.performClosure(closure, level: .info)
    }

    public static func withWarn(_ closure: LogClosure) {
        Log.performClosure(closure, level: .warn)
    }

    public static func withError(_ closure: LogClosure) {
        Log.performClosure(closure, level: .error)
    }

    public static func setLoggingLevel(_ level: LogLevel) {
        Log.logLevel = level
    }

    public static func pushLevel(_ level: LogLevel) {
        Log.logLevelStack.append(level)
    }

    public static func popLevel() {
        let _ = Log.logLevelStack.popLast()
    }

    private static var logLevelStack: [LogLevel] = []

    private static var logLevel: LogLevel {
        get {
            return Log.logLevelStack.last ?? .info
        }
        set {
            let count = Log.logLevelStack.count
            if count > 0 {
                Log.logLevelStack[count - 1] = newValue
            } else {
                Log.logLevelStack.append(newValue)
            }
        }
    }

    private static func shouldLog(_ level: LogLevel) -> Bool {
        return level >= Log.logLevel
    }

    private static func performStringClosure(_ closure: LogStringClosure,
                                             level: LogLevel,
                                             file: String = #file,
                                             line: Int = #line) {
        guard level >= Log.logLevel else { return }

        let message = closure()
        self.log(message, level: level, file: file, line: line)
    }

    private static func performClosure(_ closure: LogClosure, level: LogLevel) {
        guard level >= Log.logLevel else { return }

        closure()
    }

    private static func log(_ item: Any, level: LogLevel, file: String, line: Int) {
        guard level >= Log.logLevel else { return }

        let nowString = Log.timeFormatter.string(from: Date())
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

private struct StderrOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stderr) }
}

private struct StdoutOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stdout) }
}
