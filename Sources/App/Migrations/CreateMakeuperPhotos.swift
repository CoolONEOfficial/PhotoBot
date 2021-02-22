//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Fluent

struct CreateMakeuperPhotos: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(MakeuperPhoto.schema)
            .id()
            .field("makeuper_id", .uuid, .required, .references(MakeuperModel.schema, "id"))
            .field("photo_id", .uuid, .required, .references(PlatformFileModel.schema, "id"))
            .unique(on: "makeuper_id", "photo_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(MakeuperPhoto.schema).delete()
    }
}
