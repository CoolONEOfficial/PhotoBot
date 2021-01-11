//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

struct ActionPayload: Codable {
    enum `Type`: String, Codable {
        case message_edit
        case set_name
    }
    
    let type: Type
    
    enum NodeIdOrPop: AutoCodable {
        case moveToNode(id: UUID)
        case pop
    }
    
    let action: NodeIdOrPop?
    let failureMessage: String?
    
    init(_ type: Type, success successNodeId: NodeIdOrPop? = nil, failure failureMessage: String? = nil) {
        self.type = type
        self.action = successNodeId
        self.failureMessage = failureMessage
    }
}
