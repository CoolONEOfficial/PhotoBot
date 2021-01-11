//
//  File.swift
//
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent

struct CreateNodes: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("nodes")
            .id()
            .field("systemic", .bool, .required)
            .field("name", .string, .required)
            .field("messages", .array(of: .json), .required)
            .field("entry_point", .string)
            .field("action", .json)
            .unique(on: "entry_point")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("nodes").delete()
    }
}
