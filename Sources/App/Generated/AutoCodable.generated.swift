// Generated using Sourcery 1.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Vapor

extension ActionPayload.NodeIdOrPop {

    enum CodingKeys: String, CodingKey {
        case moveToNode
        case pop
        case id
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.moveToNode), try container.decodeNil(forKey: .moveToNode) == false {
            let associatedValues = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .moveToNode)
            let id = try associatedValues.decode(UUID.self, forKey: .id)
            self = .moveToNode(id: id)
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
        case .pop:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .pop)
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
