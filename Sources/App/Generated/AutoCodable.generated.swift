// Generated using Sourcery 1.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Vapor
import AnyCodable

extension EventPayload {

    enum CodingKeys: String, CodingKey {
        case editText
        case createNode
        case messageId
        case type
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
        }
    }

}

extension NavigationPayload {

    enum CodingKeys: String, CodingKey {
        case back
        case toNode
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.back), try container.decodeNil(forKey: .back) == false {
            self = .back
            return
        }
        if container.allKeys.contains(.toNode), try container.decodeNil(forKey: .toNode) == false {
            var associatedValues = try container.nestedUnkeyedContainer(forKey: .toNode)
            let associatedValue0 = try associatedValues.decode(UUID.self)
            self = .toNode(associatedValue0)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .back:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .back)
        case let .toNode(associatedValue0):
            var associatedValues = container.nestedUnkeyedContainer(forKey: .toNode)
            try associatedValues.encode(associatedValue0)
        }
    }

}

extension NodeAction.Action {

    enum CodingKeys: String, CodingKey {
        case moveToNode
        case moveToBuilder
        case pop
        case id
        case of
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.moveToNode), try container.decodeNil(forKey: .moveToNode) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .moveToNode)
            let id = try associatedValues.decode(UUID.self, forKey: .id)
            self = .moveToNode(id: id)
            return
        }
        if container.allKeys.contains(.moveToBuilder), try container.decodeNil(forKey: .moveToBuilder) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .moveToBuilder)
            let of = try associatedValues.decode(BuildableType.self, forKey: .of)
            self = .moveToBuilder(of: of)
            return
        }
        if container.allKeys.contains(.pop), try container.decodeNil(forKey: .pop) == false {
            self = .pop
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .moveToNode(id):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .moveToNode)
            try associatedValues.encode(id, forKey: .id)
        case let .moveToBuilder(of):
            var associatedValues = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .moveToBuilder)
            try associatedValues.encode(of, forKey: .of)
        case .pop:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .pop)
        }
    }

}
