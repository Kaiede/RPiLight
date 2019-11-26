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
import Logging

// swiftlint:disable function_parameter_count

class ServiceLogHandler: LogHandler {
    private static var stdOut: StdoutOutputStream = StdoutOutputStream()
    private static var stdErr: StderrOutputStream = StderrOutputStream()

    private static var time = DateFormatter(currentWithFormat: "HH:mm:ss.SSS")

    init(label: String) {
        self.label = label
    }

    private var label: String
    var metadata: Logger.Metadata = [:]
    subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { return metadata[key] }
        set(newValue) { metadata[key] = newValue }
    }

    static var logLevelOverride: Logger.Level?
    private var handlerLogLevel: Logger.Level = .info
    var logLevel: Logger.Level {
        get { return ServiceLogHandler.logLevelOverride ?? self.handlerLogLevel }
        set { self.handlerLogLevel = newValue }
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        file: String,
        function: String,
        line: UInt
    ) {
        let nowString = ServiceLogHandler.time.string(from: Date())
        if self.logLevel <= .trace {
            let shortFileName = URL(fileURLWithPath: file).lastPathComponent
            print("[\(level)][\(nowString)][\(shortFileName):\(line)]",
                    message,
                    separator: " ",
                    terminator: "\n",
                    to: &ServiceLogHandler.stdErr)
        } else {
            print("[\(level)][\(nowString)]",
                    message,
                    separator: " ",
                    terminator: "\n",
                    to: &ServiceLogHandler.stdErr)
        }
    }
}

private struct StderrOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stderr) }
}

private struct StdoutOutputStream: TextOutputStream {
    public mutating func write(_ string: String) { fputs(string, stdout) }
}
