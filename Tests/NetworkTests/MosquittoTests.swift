//
//  MessageTests.swift
//  Ephemeris
//
//  Created by Adam Thayer on 9/8/19.
//

import XCTest
import PerfectMosquitto
@testable import Network

class MockEndpoint: EndpointProtocol {
    var topics: Set<String> = Set<String>()
    var receivedMessages: [Message] = []
    
    func handle(message: Message) {
        receivedMessages.append(message)
    }
}

class MosquittoTests: XCTestCase {
    func testMessageConversion() {
        var validMessage = Mosquitto.Message(id: 1, topic: "topic/hit", qos: 0, retain: true)
        validMessage.string = "Hello World"
        
        let convertedMessage = Message(other: validMessage)
        XCTAssertEqual(convertedMessage.id, validMessage.id)
        XCTAssertEqual(convertedMessage.topic, validMessage.topic)
        XCTAssertEqual(convertedMessage.qos, validMessage.qos)
        XCTAssertEqual(convertedMessage.retain, validMessage.retain)
        
        switch convertedMessage.payload {
        case .data(_):
            XCTFail("Wasn't expecting data payload")
        case .string(let string):
            XCTAssertEqual(string, validMessage.string)
        }
        
        validMessage.payload = [0, 0, 0, 0]
        let payloadMessage = Message(other: validMessage)
        switch payloadMessage.payload {
        case .data(let data):
            var expectedData = Data()
            expectedData.append(contentsOf: [0,0,0,0])
            XCTAssertEqual(data.count, 4)
            XCTAssertEqual(data, expectedData)
        case .string(_):
            XCTFail("Wasn't expecting string payload")
        }

    }
    
    func testMosquittoMessageConversion() {
        var validMessage = Message(id: 1, topic: "topic/hit", qos: 0, retain: true, payload: .string("Hello World"))
        
        let convertedMessage = Mosquitto.Message(other: validMessage)
        XCTAssertEqual(convertedMessage.id, validMessage.id)
        XCTAssertEqual(convertedMessage.topic, validMessage.topic)
        XCTAssertEqual(convertedMessage.qos, validMessage.qos)
        XCTAssertEqual(convertedMessage.retain, validMessage.retain)
        XCTAssertEqual(convertedMessage.string, "Hello World")
        
        let payloadData = Data(bytes: [0, 1, 2, 3])
        validMessage.payload = .data(payloadData)
        
        let dataMessage = Mosquitto.Message(other: validMessage)
        XCTAssertNil(dataMessage.string)
        XCTAssertEqual(dataMessage.payload.count, 4)
    }
    
    func testServiceMessageHandling() {
        let service = MosquittoService(id: "testSession", cleanSession: true)
        let mockEndpoint = MockEndpoint()
        mockEndpoint.topics.insert("topic/hit")
        
        service.register(endpoint: mockEndpoint)
        var validMessage = Mosquitto.Message(id: 1, topic: "topic/hit", qos: 0, retain: true)
        validMessage.string = "Hello World"
        var invalidMessage = Mosquitto.Message(id: 2, topic: "topic/miss", qos: 0, retain: true)
        invalidMessage.string = "Hello World"
        
        service.mosquitto.OnMessage(validMessage)
        service.mosquitto.OnMessage(invalidMessage)
        XCTAssertEqual(mockEndpoint.receivedMessages.count, 1)
        XCTAssertEqual(mockEndpoint.receivedMessages.first?.id, 1)
        XCTAssertEqual(mockEndpoint.receivedMessages.first?.topic, "topic/hit")
    }

    static var allTests = [
        ("testMessageConversion", testMessageConversion),
        ("testMosquittoMessageConversion", testMosquittoMessageConversion),
        ("testServiceMessageHandling", testServiceMessageHandling)
    ]
}
