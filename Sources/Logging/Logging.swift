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

public enum LogLevel: Int, Comparable {
    case debug
    case info
    case warn
    case error
    
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public static func == (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

public typealias LogClosure = () -> Void

public struct Log {
    public static func debug(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .debug, file: file, line: line)
    }
    
    public static func debug(_ closure: LogClosure) {
        Log.performClosure(closure, level: .debug)
    }
    
    public static func info(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .info, file: file, line: line)
    }
    
    public static func info(_ closure: LogClosure) {
        Log.performClosure(closure, level: .info)
    }
    
    public static func warn(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .warn, file: file, line: line)
    }
    
    public static func warn(_ closure: LogClosure) {
        Log.performClosure(closure, level: .warn)
    }
    
    public static func error(_ item: Any, file: String = #file, line: Int = #line) {
        Log.log(item, level: .error, file: file, line: line)
    }
    
    public static func error(_ closure: LogClosure) {
        Log.performClosure(closure, level: .error)
    }
    
    public static func setLoggingLevel(_ level: LogLevel) {
        Log.logLevel = level
    }
    
    private static var logLevel : LogLevel = .info
    private static func shouldLog(_ level: LogLevel) -> Bool {
        return level >= Log.logLevel
    }
    
    private static func performClosure(_ closure: LogClosure, level: LogLevel) {
        guard level >= Log.logLevel else { return }
        
        closure()
    }
    
    private static func log(_ item: Any, level: LogLevel, file: String, line: Int) {
        guard level >= Log.logLevel else { return }
        
        print(level, "\(file):\(line)", item, separator: " ")
    }
}