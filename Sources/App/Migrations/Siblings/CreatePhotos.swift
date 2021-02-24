//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 23.02.2021.
//

import Fluent
import Vapor

protocol CreatePhotos: Migration {
    associatedtype MyType: PhotoModeledType & ModeledType
    
    var name: String { get }
}

extension CreatePhotos {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(MyType.PhotoModel.schema)
            .id()
            .field(.init(stringLiteral: "\(name)_id"), .uuid, .required, .references(MyType.Model.schema, "id"))
            .field("photo_id", .uuid, .required, .references(PlatformFileModel.schema, "id"))
            .unique(on: .init(stringLiteral: "\(name)_id"), "photo_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(MyType.PhotoModel.schema).delete()
    }
}
