//
//  File.swift
//
//
//  Created by Nickolay Truhin on 31.01.2021.
//

import Foundation
import AnyCodable
import Botter

struct OrderState: Codable {
    var stylistId: UUID?
    var makeuperId: UUID?
    var studioId: UUID?
    var price: Int
}

struct CheckoutState: Codable {
    var order: OrderState
    var promotions: [UUID] = []
}

extension OrderState {
    init(with oldPayload: NodePayload?, stylist: Stylist? = nil, makeuper: Makeuper? = nil, studio: Studio? = nil) {
        let priceables: [Priceable?] = [ stylist, makeuper, studio ]
        let appendingPrice = priceables.compactMap { $0?.price }.reduce(0, +)
        if case let .orderBuilder(state) = oldPayload {
            self.init(
                stylistId: stylist?.id ?? state.stylistId,
                makeuperId: makeuper?.id ?? state.makeuperId,
                studioId: studio?.id ?? state.studioId,
                price: state.price + appendingPrice
            )
        } else {
            self.init(
                stylistId: stylist?.id,
                makeuperId: makeuper?.id,
                studioId: studio?.id,
                price: appendingPrice
            )
        }
    }
}

enum NodePayload: Codable {
    case editText(messageId: Int)
    case build(type: BuildableType, object: [String: AnyCodable] = [:])
    case page(at: Int)
    case orderBuilder(OrderState)
    case checkout(CheckoutState)
}

//extension NodePayload {
//    static func orderBuilder(with oldPayload: NodePayload?, stylistId: UUID? = nil, makeuperId: UUID? = nil, studioId: UUID? = nil) -> Self {
//        if case let .orderBuilder(_stylistId, _makeuperId, _studioId) = oldPayload {
//            return .orderBuilder(
//                stylistId: stylistId ?? _stylistId,
//                makeuperId: makeuperId ?? _makeuperId,
//                studioId: studioId ?? _studioId
//            )
//        }
//        return .orderBuilder(stylistId: stylistId, makeuperId: makeuperId, studioId: studioId)
//    }
//}

extension NodePayload {

    enum CodingKeys: String, CodingKey {
        case editTextMessageId
        case createBuildableType
        case createBuildableObject
        case pageAt
        case orderBuilderState
        case checkoutState
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
        if container.allKeys.contains(.orderBuilderState) {
            let state = try container.decode(OrderState.self, forKey: .orderBuilderState)
            self = .orderBuilder(state)
            return
        }
        if container.allKeys.contains(.checkoutState) {
            let state = try container.decode(CheckoutState.self, forKey: .checkoutState)
            self = .checkout(state)
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

        case let .orderBuilder(state):
            try container.encode(state, forKey: .orderBuilderState)
        
        case let .checkout(checkout):
            try container.encode(checkout, forKey: .checkoutState)
        }
    }

}
