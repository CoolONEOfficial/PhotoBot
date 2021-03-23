//
//  File.swift
//
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Fluent

struct CreatePhotographers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(PhotographerModel.schema)
            .id()
            .field("name", .string)
            .field("platform_ids", .array(of: .json))
            .field("price", .float, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(PhotographerModel.schema).delete()
    }
}
