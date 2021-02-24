//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 23.02.2021.
//

import Fluent

struct CreateStudios: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(StudioModel.schema)
            .id()
            .field("name", .string, .required)
            .field("description", .string, .required)
            .field("address", .string, .required)
            .field("coords", .json, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(StudioModel.schema).delete()
    }
}
