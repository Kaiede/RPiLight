//
//  Message.swift
//  Ephemeris
//
//  Created by Adam Thayer on 9/7/19.
//

import Foundation

public struct Message {
    public var id: Int32 = 0
    
    public var topic: String = ""
        
    public var qos: Int32 = 0
    
    public var retain: Bool = false

    public var payload: Payload = .data(Data())

    public enum Payload {
        case string(String)
        case data(Data)
    }
    
    public init(id: Int32 = 0, topic: String = "", qos: Int32 = 0, retain: Bool = false, payload: Payload = .data(Data())) {
        self.id = id
        self.topic = topic
        self.qos = qos
        self.retain = retain
        self.payload = payload
    }
}
