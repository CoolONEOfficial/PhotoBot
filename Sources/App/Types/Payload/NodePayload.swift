//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 31.01.2021.
//

import Foundation
import AnyCodable

enum NodePayload: Codable {
    case editText(messageId: Int)
    case build(type: BuildableType, object: [String: AnyCodable] = [:])
    case page(at: Int)
    case orderConstructor(stylistId: UUID?, makeuperId: UUID?)
}

extension NodePayload {
    static func orderConstructor(with oldPayload: NodePayload?, stylistId: UUID? = nil, makeuperId: UUID? = nil) -> Self {
        if case let .orderConstructor(_stylistId, _makeuperId) = oldPayload {
            return .orderConstructor(
                stylistId: stylistId ?? _stylistId,
                makeuperId: makeuperId ?? _makeuperId
            )
        }
        return .orderConstructor(stylistId: stylistId, makeuperId: makeuperId)
    }
}

extension NodePayload {

    enum CodingKeys: String, CodingKey {
        case editTextMessageId
        case createBuildableType
        case createBuildableObject
        case pageAt
        case orderConstructorStylistId
        case orderConstructorMakeuperId
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.editTextMessageId), try container.decodeNil(forKey: .editTextMessageId) == false {
            let messageId = try container.decode(Int.self, forKey: .editTextMessageId)
            self = .editText(messageId: messageId)
            return
        }
        if container.allKeys.contains(.createBuildableType), try container.decodeNil(forKey: .createBuildableType) == false {
            let buildableType = try container.decode(BuildableType.self, forKey: .createBuildableType)
            let object = try container.decode([String: AnyCodable].self, forKey: .createBuildableObject)
            self = .build(type: buildableType, object: object)
            return
        }
        if container.allKeys.contains(.pageAt), try container.decodeNil(forKey: .pageAt) == false {
            let num = try container.decode(Int.self, forKey: .pageAt)
            self = .page(at: num)
            return
        }
        if container.allKeys.contains(.orderConstructorStylistId) || container.allKeys.contains(.orderConstructorMakeuperId) {
            let stylistId = try? container.decode(UUID.self, forKey: .orderConstructorStylistId)
            let makeuperId = try? container.decode(UUID.self, forKey: .orderConstructorMakeuperId)
            self = .orderConstructor(stylistId: stylistId, makeuperId: makeuperId)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .editText(messageId):
            try container.encode(messageId, forKey: .editTextMessageId)

        case let .build(buildableType, object):
            try container.encode(buildableType, forKey: .createBuildableType)
            try container.encode(AnyCodable(object.unwrapped), forKey: .createBuildableObject)

        case let .page(num):
            try container.encode(num, forKey: .pageAt)

        case let .orderConstructor(stylistId, makeuperId):
            try container.encode(stylistId, forKey: .orderConstructorStylistId)
            try container.encode(makeuperId, forKey: .orderConstructorMakeuperId)
        }
    }

}
