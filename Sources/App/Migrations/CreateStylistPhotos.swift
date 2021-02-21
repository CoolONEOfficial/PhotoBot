//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.02.2021.
//

import Fluent

struct CreateStylistPhotos: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(StylistPhoto.schema)
            .id()
            .field("stylist_id", .uuid, .required, .references(StylistModel.schema, "id"))
            .field("photo_id", .uuid, .required, .references(PlatformFileModel.schema, "id"))
            .unique(on: "stylist_id", "photo_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(StylistPhoto.schema).delete()
    }
}
