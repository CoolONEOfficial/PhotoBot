//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.03.2021.
//

import Foundation

struct CreateOrderPromotions: CreateSiblingPromotions {
    typealias TwinType = Order
    
    var name: String { "order" }
}
