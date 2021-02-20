//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 14.02.2021.
//

import Fluent

struct CreateStylists: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(StylistModel.schema)
            .id()
            .field("name", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(StylistModel.schema).delete()
    }
}
