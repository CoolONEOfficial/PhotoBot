//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Fluent

struct CreateMakeupers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(MakeuperModel.schema)
            .id()
            .field("name", .string)
            .field("platform_ids", .array(of: .json))
            .field("prices", .dictionary(of: .float), .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(MakeuperModel.schema).delete()
    }
}
