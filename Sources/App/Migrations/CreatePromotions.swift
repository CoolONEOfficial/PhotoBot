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
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("condition", .json, .required)
            .field("impact", .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(PromotionModel.schema).delete()
    }
}
