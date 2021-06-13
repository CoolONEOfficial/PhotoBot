//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 02.06.2021.
//

import Foundation
import Fluent
import Vapor
import Botter
import ValidatedPropertyKit

final class AgreementModel: Model {
    static var schema: String  = "agreements"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "order_id")
    var order: OrderModel

    @Parent(key: "approver_id")
    var approver: UserModel

    required init() {}
    
    init(id: UUID? = nil, order: OrderModel, approver: UserModel) throws { // TODO: model args to ids
        self.id = id
        self.$order.id = try order.requireID()
        self.$approver.id = try approver.requireID()
    }
}
