//
//  File.swift
//
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent

struct CreateUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users")
            .id()
            .field("name", .string)
            .field("vk_id", .int64)
            .field("tg_id", .int64)
            .field("history", .array(of: .json), .required)
            .field("node_id", .uuid, .references("nodes", "id"))
            .field("node_payload", .json)
            .unique(on: "vk_id", "tg_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("users").delete()
    }
}
