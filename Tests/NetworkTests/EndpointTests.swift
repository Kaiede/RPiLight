//
//  EndpointTests.swift
//  RPiLight
//
//  Created by Adam Thayer on 9/7/19.
//

import XCTest
import PerfectMosquitto
@testable import Network

class MockService: Service {
    func publish(message: Message) {
        // Do Nothing
    }
    
    func register(endpoint: EndpointProtocol) {
        // Do Nothing
    }
    
    func unregister(endpoint: EndpointProtocol) {
        // Do Nothing
    }
}

class EndpointTests: XCTestCase {
    func testMessageHandler() {
        let mockService = MockService()
        let endpoint = Endpoint(service: mockService)
        
        let expectation = XCTestExpectation(description: "topic/hit should be hit")
        expectation.assertForOverFulfill = true
        expectation.expectedFulfillmentCount = 1
        
        endpoint.message(topic: "topic/hit") { msg in
            XCTAssertEqual(msg.topic, "topic/hit")
            XCTAssertEqual(msg.id, 2)

            expectation.fulfill()
        }
        
        XCTAssertEqual(endpoint.topics.count, 1)
        XCTAssertTrue(endpoint.topics.contains("topic/hit"))
        XCTAssertFalse(endpoint.topics.contains("topic/miss"))

        let missMessage = Message(id: 1, topic: "topic/miss", qos: 0, retain: false, payload: .string("Hello World"))
        let hitMessage = Message(id: 2, topic: "topic/hit", qos: 0, retain: false, payload: .string("Hello World"))

        endpoint.handle(message: missMessage)
        endpoint.handle(message: hitMessage)
    }
    
    func testMultipleMessageHandlers() {
        let mockService = MockService()
        let endpoint = Endpoint(service: mockService)
        
        let firstExpectation = XCTestExpectation(description: "topic/hit should be hit")
        firstExpectation.assertForOverFulfill = true
        firstExpectation.expectedFulfillmentCount = 1
        
        let secondExpectation = XCTestExpectation(description: "topic/hit should be hit")
        secondExpectation.assertForOverFulfill = true
        secondExpectation.expectedFulfillmentCount = 1
        
        // Two handlers should both be called for the same message
        endpoint.message(topic: "topic/hit") { msg in
            XCTAssertEqual(msg.topic, "topic/hit")
            XCTAssertEqual(msg.id, 2)
            
            firstExpectation.fulfill()
        }
        
        endpoint.message(topic: "topic/hit") { msg in
            XCTAssertEqual(msg.topic, "topic/hit")
            XCTAssertEqual(msg.id, 2)
            
            secondExpectation.fulfill()
        }
        
        XCTAssertEqual(endpoint.topics.count, 1)
        XCTAssertTrue(endpoint.topics.contains("topic/hit"))
        XCTAssertFalse(endpoint.topics.contains("topic/miss"))
        
        let missMessage = Message(id: 1, topic: "topic/miss", qos: 0, retain: false, payload: .string("Hello World"))
        let hitMessage = Message(id: 2, topic: "topic/hit", qos: 0, retain: false, payload: .string("Hello World"))
        
        endpoint.handle(message: missMessage)
        endpoint.handle(message: hitMessage)
    }
    
    static var allTests = [
        ("testMessageHandler", testMessageHandler),
        ("testMultipleMessageHandlers", testMultipleMessageHandlers)
    ]
}
