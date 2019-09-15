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

public protocol Service: class {
    func connect(host: String, port: Int32, keepAlive: Int32)
    func disconnect()
    
    func register(endpoint: EndpointProtocol)
    func unregister(endpoint: EndpointProtocol)
    
    func publish(message: Message)
}

extension Array where Array.Element == EndpointProtocol {
    func matching(topic: String) -> Array<EndpointProtocol> {
        return self.filter( { $0.topics.contains(topic) } )
    }
}

public typealias MessageClosure = (Message) -> Void

public protocol EndpointProtocol: class {
    var topics: Set<String> { get }
    
    func handle(message: Message)
}

public class Endpoint: EndpointProtocol {  
    private weak var service: Service?
    public var topics: Set<String> {
        // TODO: Performance on this may be iffy?
        get { return Set<String>(self.messageHandlers.keys) }
    }
    
    private var messageHandlers: [String: [MessageClosure]] = [:]
    
    public init() {
        self.service = nil
    }
    
    public init(service: Service) {
        self.service = service
        service.register(endpoint: self)
    }
    
    public func connect(service: Service) {
        disconnect()
        self.service = service
        service.register(endpoint: self)
    }
    
    public func disconnect() {
        if let service = self.service {
            service.unregister(endpoint: self)
            self.service = nil
        }
    }
    
    deinit {
        disconnect()
    }
    
    public func publish(message: Message) {
        if let service = self.service {
            service.publish(message: message)
        }
    }
    
    public func message(topic: String, body: @escaping MessageClosure) {
        // TODO: This is entirely glue code. Extractable?
        if var topicHandlers = self.messageHandlers[topic] {
            topicHandlers.append(body)
            self.messageHandlers[topic] = topicHandlers
        } else {
            self.messageHandlers[topic] = [body]
        }
    }
    
    public func handle(message: Message) {
        // TODO: Get the list of closures for this event.
        let closures: [MessageClosure] = self.messageHandlers[message.topic] ?? []
        
        for closure in closures {
            closure(message)
        }
    }
}
