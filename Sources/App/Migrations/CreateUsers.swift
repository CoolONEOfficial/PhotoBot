//
//  File.swift
//
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent

struct CreateUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema)
            .id()
            .field("is_admin", .bool, .required)
            .field("first_name", .string)
            .field("last_name", .string)
            .field("platform_ids", .array(of: .json))
            .field("history", .array(of: .json), .required)
            .field("node_id", .uuid, .references(NodeModel.schema, "id"))
            .field("node_payload", .json)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema).delete()
    }
}
