//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.02.2021.
//

import Fluent

struct CreatePlatformFiles: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(PlatformFileModel.schema)
            .id()
            .field("platform", .array(of: .json))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(PlatformFileModel.schema).delete()
    }
}
