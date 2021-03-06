//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

enum EventPayload {
    case editText(messageId: Int)
    case createNode(type: BuildableType)
    case selectStylist(id: UUID)
    case selectMakeuper(id: UUID)
    case selectStudio(id: UUID)
    case toCheckout
    case createOrder
    
    // MARK: Navigation
    
    case back
    case push(PushTarget, payload: NodePayload? = nil, saveToHistory: Bool = true)
    case previousPage
    case nextPage
}

extension EventPayload: Codable {

    enum CodingKeys: String, CodingKey {
        case editText
        case createNode
        case selectStylist = "selStylist"
        case selectMakeuper = "selMakeuper"
        case selectStudio = "selStudio"
        case toCheckout
        case createOrder
        case back
        case push
        case previousPage
        case nextPage
        case messageId
        case type
        case id
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.editText), try container.decodeNil(forKey: .editText) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .editText)
            let messageId = try associatedValues.decode(Int.self, forKey: .messageId)
            self = .editText(messageId: messageId)
            return
        }
        if container.allKeys.contains(.createNode), try container.decodeNil(forKey: .createNode) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .createNode)
            let type = try associatedValues.decode(BuildableType.self, forKey: .type)
            self = .createNode(type: type)
            return
        }
        if container.allKeys.contains(.selectStylist), try container.decodeNil(forKey: .selectStylist) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .selectStylist)
            let id = try associatedValues.decode(UUID.self, forKey: .id)
            self = .selectStylist(id: id)
            return
        }
        if container.allKeys.contains(.selectMakeuper), try container.decodeNil(forKey: .selectMakeuper) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .selectMakeuper)
            let id = try associatedValues.decode(UUID.self, forKey: .id)
            self = .selectMakeuper(id: id)
            return
        }
        if container.allKeys.contains(.selectStudio), try container.decodeNil(forKey: .selectStudio) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .selectStudio)
            let id = try associatedValues.decode(UUID.self, forKey: .id)
            self = .selectStudio(id: id)
            return
        }
        if container.allKeys.contains(.toCheckout), try container.decodeNil(forKey: .toCheckout) == false {
            self = .toCheckout
            return
        }
        if container.allKeys.contains(.createOrder), try container.decodeNil(forKey: .createOrder) == false {
            self = .createOrder
            return
        }
        if container.allKeys.contains(.back), try container.decodeNil(forKey: .back) == false {
            self = .back
            return
        }
        if container.allKeys.contains(.push), try container.decodeNil(forKey: .push) == false {
            var associatedValues = try container.nestedUnkeyedContainer(forKey: .push)
            let target = try associatedValues.decode(PushTarget.self)
            let nodePayload = try associatedValues.decodeIfPresent(NodePayload.self)
            let saveToHistory = try associatedValues.decode(Bool.self)
            self = .push(target, payload: nodePayload, saveToHistory: saveToHistory)
            return
        }
        if container.allKeys.contains(.previousPage), try container.decodeNil(forKey: .previousPage) == false {
            self = .previousPage
            return
        }
        if container.allKeys.contains(.nextPage), try container.decodeNil(forKey: .nextPage) == false {
            self = .nextPage
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .editText(messageId):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .editText)
            try associatedValues.encode(messageId, forKey: .messageId)
        case let .createNode(type):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .createNode)
            try associatedValues.encode(type, forKey: .type)
        case let .selectStylist(id):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .selectStylist)
            try associatedValues.encode(id, forKey: .id)
        case let .selectMakeuper(id):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .selectMakeuper)
            try associatedValues.encode(id, forKey: .id)
        case let .selectStudio(id):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .selectStudio)
            try associatedValues.encode(id, forKey: .id)
        case .toCheckout:
            try container.encode(true, forKey: .toCheckout)
        case .createOrder:
            try container.encode(true, forKey: .createOrder)
        case .back:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .back)
        case let .push(associatedValue0, associatedValue1, associatedValue2):
            var associatedValues = container.nestedUnkeyedContainer(forKey: .push)
            try associatedValues.encode(associatedValue0)
            try associatedValues.encode(associatedValue1)
            try associatedValues.encode(associatedValue2)
        case .previousPage:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .previousPage)
        case .nextPage:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .nextPage)
        }
    }

}

enum PushTarget {
    case id(UUID)
    case entryPoint(EntryPoint)
    case action(NodeActionType)
}

enum PushTargetError: Error {
    case decodeFailed
}

extension PushTarget: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let id = try? container.decode(UUID.self) {
            self = .id(id)
        } else if let entryPoint = try? container.decode(EntryPoint.self) {
            self = .entryPoint(entryPoint)
        } else if let action = try? container.decode(NodeActionType.self) {
            self = .action(action)
        } else {
            throw PushTargetError.decodeFailed
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .entryPoint(entryPoint):
            try container.encode(entryPoint)
        
        case let .id(id):
            try container.encode(id)
        
        case let .action(action):
            try container.encode(action)
        }
    }
}
