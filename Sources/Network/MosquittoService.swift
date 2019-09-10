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
import PerfectMosquitto

extension Message {
    // Convert Mosquitto messages to the more "agnostic" form.
    init(other: Mosquitto.Message) {
        self.id = other.id
        self.topic = other.topic
        self.qos = other.qos
        self.retain = other.retain
        if let string = other.string {
            self.payload = .string(string)
        } else {
            let payload = UnsafePointer(other.payload)
            let data = Data(bytes: payload, count: other.payload.count)
            self.payload = .data(data)
        }
    }
}

extension Mosquitto.Message {
    init(other: Message) {
        self.init(id: other.id, topic: other.topic, qos: other.qos, retain: other.retain)
        switch other.payload {
        case .string(let string):
            self.string = string
            break
        case .data(let data):
            // This is goofy, because the library picked some weird type for exposing the raw bytes.
            data.withUnsafeBytes { ptr in
                let payloadPtr = ptr.bindMemory(to: Int8.self)
                self.payload = Array<Int8>(payloadPtr)
            }
        }
    }
}

public class MosquittoService: Service {
    internal var mosquitto: Mosquitto
    private var endpoints: [EndpointProtocol] = []
    
    public init(id: String? = nil, cleanSession: Bool = true) {
        self.mosquitto = Mosquitto(id: id, cleanSession: cleanSession)
        
        // Hook up Handlers Here
        self.mosquitto.OnMessage = { message in self.handle(message: message) }
    }
    
    public func register(endpoint: EndpointProtocol) {
        endpoints.append(endpoint)
    }
    
    public func unregister(endpoint: EndpointProtocol) {
        // TODO: Implement something that allows removal.
    }
    
    public func publish(message: Message) {
        // TODO: This needs to be able to handle propogating errors upward
        let mosquittoMessage = Mosquitto.Message(other: message)
        try! self.mosquitto.publish(message: mosquittoMessage)
    }
    
    private func handle(message: Mosquitto.Message) {
        let messageEndpoints = self.endpoints.matching(topic: message.topic)
        for endpoint in messageEndpoints {
            endpoint.handle(message: Message(other: message))
        }
    }
}


