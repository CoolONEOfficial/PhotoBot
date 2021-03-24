//
//  Priceable.swift
//  
//
//  Created by Nickolay Truhin on 05.03.2021.
//

import Foundation
import Vapor
import Fluent

protocol Priceable {
    var prices: [OrderType: Float] { get set }
    var _prices: [String: Float] { get set }
}

extension Priceable where Self: Model {
    var prices: [OrderType: Float] {
        get {
            .init(uniqueKeysWithValues: _prices.compactMap { key, value in
                guard let type = OrderType(rawValue: key) else { return nil }
                return (type, value)
            })
        }
        mutating set {
            _prices = .init(uniqueKeysWithValues: newValue.compactMap { type, value in
                (type.rawValue, value)
            })
        }
    }
}

extension Priceable where Self: Twinable, Self.TwinType: Model {
    var _prices: [String: Float] { get { [:] } set {} }
}

//extension Priceable {
//    var formattedPrice(): String {
//        "\(price) ₽ / час"
//    }
//}
