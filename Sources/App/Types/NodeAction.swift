//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import AnyCodable

enum NodeActionType: String, Codable {
    case messageEdit
    case setName
    case buildType
    case createNode
    case uploadPhoto
    case applyPromocode
}

struct NodeAction: Codable {
    
    let type: NodeActionType
    
    enum Action: AutoCodable {
        case push(target: PushTarget)
        case moveToBuilder(of: BuildableType)
        case pop
    }
    
    let action: Action?
    
    init(_ type: NodeActionType, success action: Action? = nil) {
        self.type = type
        self.action = action
    }
}
