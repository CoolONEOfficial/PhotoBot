//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.06.2021.
//

import Foundation
import Fluent

struct CreateAgreements: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(AgreementModel.schema)
            .id()
            .field("order_id", .uuid, .required, .references(OrderModel.schema, .id))
            .field("approver_id", .uuid, .required, .references(UserModel.schema, .id))
            .unique(on: "order_id", "approver_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(AgreementModel.schema).delete()
    }
}
