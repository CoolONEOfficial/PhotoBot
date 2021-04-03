//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 03.04.2021.
//

import Foundation

import Fluent

struct CreateReviews: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ReviewModel.schema)
            .id()
            .field("screenshot", .uuid, .required, .references(PlatformFileModel.schema, .id))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ReviewModel.schema).delete()
    }
}
