//
//  Priceable.swift
//  
//
//  Created by Nickolay Truhin on 05.03.2021.
//

import Foundation

protocol Priceable {
    var price: Float { get set }
}

extension Priceable {
    var formattedPrice: String {
        "\(price) ₽ / час"
    }
}
