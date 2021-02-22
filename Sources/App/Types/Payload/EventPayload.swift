//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

enum EventPayload: AutoCodable {
    case editText(messageId: Int)
    case createNode(type: BuildableType)
    case selectStylist(id: UUID)
    case selectMakeuper(id: UUID)
    
    // MARK: Navigation
    
    case back
    case toNode(UUID, Bool = true)
    case previousPage
    case nextPage
}
