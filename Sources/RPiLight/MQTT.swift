/*
RPiLight

Copyright (c) 2018-2020 Adam Thayer
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

import NIOMQTTClient

import Service

extension MQTTClient.Configuration {
    init(configuration: ServiceBrokerDescription) {
        let port = configuration.port ?? 8883
        let clientId = configuration.clientId ?? "rpilight"
        let enableTls = configuration.enableTls ?? false
        
        self.init(host: configuration.host, port: port, clientId: clientId, qos: .atLeastOnce, tlsEnabled: enableTls)
    }
}

extension MQTTClient {
    convenience init(configuration: ServiceBrokerDescription) {
        let configuration = MQTTClient.Configuration(configuration: configuration)
        self.init(configuration: configuration)
    }
    
    func onConnect(closure: @escaping (() -> Void)) {
        self.onConnect = closure
    }
    
    func onDisconnect(closure: @escaping ((Error?) -> Void)) {
        self.onDisconnect = closure
    }
    
    func onText(closure: @escaping ((String, String) -> Void)) {
        self.onText = closure
    }
    
    func onData(closure: @escaping ((String, Data) -> Void)) {
        self.onData = closure
    }
}

class MQTTRouter {
    typealias RouterClosure = (String) -> Void

    let client: MQTTClient
    private var handlers: [String:RouterClosure]
    private var connectHandler: (() -> Void)?
    
    init(client: MQTTClient) {
        self.client = client
        self.handlers = [:]
        self.connectHandler = nil
        
        self.client.onConnect {
            for key in self.handlers.keys {
                self.subscribe(topic: key)
            }
            self.connectHandler?()
        }
        self.client.onText { (topic, text) in
            self.handleText(topic: topic, text: text)
        }
    }
    
    func onTopic(_ topic: String, closure: @escaping RouterClosure) {
        self.handlers[topic] = closure
        subscribe(topic: topic)
    }
    
    func onConnect(closure: @escaping (() -> Void)) {
        self.connectHandler = closure
    }
    
    func stopListening(topic: String) {
        self.handlers[topic] = nil
        client.unsubscribe(topic: topic)
    }
    
    private func subscribe(topic: String) {
        if client.connectivity.state == .ready {
            client.subscribe(topic: topic)
        }
    }
    
    private func handleText(topic: String, text: String) {
        if let handler = handlers[topic] {
            handler(text)
        }
    }
}
