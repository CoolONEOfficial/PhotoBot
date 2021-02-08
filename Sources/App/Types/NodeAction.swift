//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import AnyCodable

struct NodeAction: Codable {
    enum `Type`: String, Codable {
        case messageEdit
        case setName
        case buildType
        case createNode
    }
    
    let type: Type
    
    enum Action: AutoCodable {
        case moveToNode(id: UUID)
        case moveToBuilder(of: BuildableType)
        case pop
    }
    
    let action: Action?
    let failureMessage: String?
    
    init(_ type: Type, success action: Action? = nil, failure message: String? = nil) {
        self.type = type
        self.action = action
        self.failureMessage = message
    }
}
