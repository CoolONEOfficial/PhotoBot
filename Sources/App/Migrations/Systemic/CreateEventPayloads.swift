//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.03.2021.
//

import Fluent

struct CreateEventPayloads: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(EventPayloadModel.schema)
            .id()
            .field("instance", .string, .required)
            .field("owner_id", .uuid, .required, .references(UserModel.schema, .id))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(EventPayloadModel.schema).delete()
    }
}
