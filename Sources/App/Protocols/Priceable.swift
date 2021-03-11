//
//  Priceable.swift
//  
//
//  Created by Nickolay Truhin on 05.03.2021.
//

import Foundation

protocol Priceable {
    var price: Int { get set }
}

extension Priceable {
    var formattedPrice: String {
        "\(price) р./ч."
    }
}
