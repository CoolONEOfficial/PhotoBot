//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 24.02.2021.
//

import Fluent

struct CreatePromotions: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(PromotionModel.schema)
            .id()
            .field("auto_apply", .bool, .required)
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("promocode", .string)
            .field("condition", .json, .required)
            .field("impact", .json, .required)
            .unique(on: "promocode")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(PromotionModel.schema).delete()
    }
}
