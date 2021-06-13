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
            .field("makeuper_id", .uuid, .references(MakeuperModel.schema, .id))
            .field("stylist_id", .uuid, .references(StylistModel.schema, .id))
            .field("photographer_id", .uuid, .references(PhotographerModel.schema, .id))
            .field("studio_id", .uuid, .references(StudioModel.schema, .id))
            .field("last_destination", .json)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserModel.schema).delete()
    }
}
