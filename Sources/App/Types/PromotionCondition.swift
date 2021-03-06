//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 04.03.2021.
//

import Foundation
import Vapor
import Botter

enum PromotionCondition {
    
    indirect case and([PromotionCondition])
    indirect case or([PromotionCondition])
    case numeric(NumericKey, NumericCondition, Int)
    case equals(EquatableKey, UUID)
    
    enum EquatableKey: String, Codable {
        case studio
        case makeuper
        case stylist
    }
    
    enum NumericKey: String, Codable {
        case price
        case peopleCount
        case propsCount
    }
    
    enum NumericCondition: String, Codable  {
        case less
        case more
        case equals
    }
    
}

extension PromotionCondition {
    
    func check(state: OrderState, app: Application) -> Future<Bool> {
        Self.check(state: state, condition: self, app: app)
    }
    
    static func check(state: OrderState, condition: Self, app: Application) -> Future<Bool> {
        switch condition {
        case let .and(arr), let .or(arr):
            return arr.map { $0.check(state: state, app: app) }.flatten(on: app.eventLoopGroup.next()).map {
                switch condition {
                case .and:
                    return $0.allSatisfy { $0 }
                case .or:
                    return $0.contains { $0 }
                default: fatalError()
                }
            }
        case let .numeric(lhs, numCondition, rhs):
            return lhs.getValue(state: state, app: app).map { lhsNum in
                switch numCondition {
                case .less:
                    return lhsNum < rhs
                case .more:
                    return lhsNum > rhs
                case .equals:
                    return lhsNum == rhs
                }
            }
        case let .equals(lhs, rhs):
            return app.eventLoopGroup.future(lhs.getId(state: state) == rhs)
        }
    }
    
}

extension PromotionCondition.NumericKey {
    func getValue(state: OrderState, app: Application) -> Future<Int> {
        switch self {
        case .price:
            return app.eventLoopGroup.future(Int(state.price))
        case .peopleCount:
            return app.eventLoopGroup.future(0)
        case .propsCount:
            return app.eventLoopGroup.future(0)
        }
    }
}

extension PromotionCondition.EquatableKey {
    func getId(state: OrderState) -> UUID? {
        switch self {
        case .makeuper:
            return state.makeuperId
        case .studio:
            return state.studioId
        case .stylist:
            return state.stylistId
        }
    }
}

extension PromotionCondition: Codable {

    enum CodingKeys: String, CodingKey {
        case and
        case or
        case numericLhs
        case numericCondition
        case numericRhs
        case equalsLhs
        case equalsRhs
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.and), try container.decodeNil(forKey: .and) == false {
            let associatedValue0 = try container.decode([PromotionCondition].self, forKey: .and)
            self = .and(associatedValue0)
            return
        }
        if container.allKeys.contains(.or), try container.decodeNil(forKey: .or) == false {
            let associatedValue0 = try container.decode([PromotionCondition].self, forKey: .or)
            self = .or(associatedValue0)
            return
        }
        if container.allKeys.contains(.numericLhs), try container.decodeNil(forKey: .numericLhs) == false {
            let associatedValue0 = try container.decode(NumericKey.self, forKey: .numericLhs)
            let associatedValue1 = try container.decode(NumericCondition.self, forKey: .numericCondition)
            let associatedValue2 = try container.decode(Int.self, forKey: .numericRhs)
            self = .numeric(associatedValue0, associatedValue1, associatedValue2)
            return
        }
        if container.allKeys.contains(.equalsLhs), try container.decodeNil(forKey: .equalsLhs) == false {
            let associatedValue0 = try container.decode(EquatableKey.self, forKey: .equalsLhs)
            let associatedValue1 = try container.decode(UUID.self, forKey: .equalsRhs)
            self = .equals(associatedValue0, associatedValue1)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .and(associatedValue0):
            try container.encode(associatedValue0, forKey: .and)
        case let .or(associatedValue0):
            try container.encode(associatedValue0, forKey: .or)
        case let .numeric(associatedValue0, associatedValue1, associatedValue2):
            try container.encode(associatedValue0, forKey: .numericLhs)
            try container.encode(associatedValue1, forKey: .numericCondition)
            try container.encode(associatedValue2, forKey: .numericRhs)
        case let .equals(associatedValue0, associatedValue1):
            try container.encode(associatedValue0, forKey: .equalsLhs)
            try container.encode(associatedValue1, forKey: .equalsRhs)
        }
    }

}
