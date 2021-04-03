//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation
import AnyCodable

public enum NodeActionType: String, Codable {
    case messageEdit
    case createNode
    case uploadPhoto
    case applyPromocode
    case handleCalendar
    case handleOrderAgreement
}

public struct NodeAction: Codable {
    
    let type: NodeActionType
    
    enum Action: AutoCodable {
        case push(target: PushTarget)
        case pop
    }
    
    let action: Action?
    
    init(_ type: NodeActionType, success action: Action? = nil) {
        self.type = type
        self.action = action
    }
}
