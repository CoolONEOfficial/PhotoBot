//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.03.2021.
//

import Foundation
import Fluent
import Vapor

final class OrderPromotion: Model {
    static let schema = "orders+promotions"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: OrderModel

    @Parent(key: "promotion_id")
    var promotion: PromotionModel

    init() { }

    init(id: UUID? = nil, order: OrderModel, promotion: PromotionModel) throws {
        self.id = id
        self.$order.id = try order.requireID()
        self.$promotion.id = try promotion.requireID()
    }
}
