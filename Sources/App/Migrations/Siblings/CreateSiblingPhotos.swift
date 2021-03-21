//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 23.02.2021.
//

import Fluent
import Vapor

protocol CreateSiblingPhotos: Migration {
    associatedtype TwinType: PhotosProtocol & ModeledType
    
    var name: String { get }
}

extension CreateSiblingPhotos {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TwinType.SiblingModel.schema)
            .id()
            .field(.init(stringLiteral: "\(name)_id"), .uuid, .required, .references(TwinType.TwinType.schema, "id"))
            .field("photo_id", .uuid, .required, .references(PlatformFileModel.schema, "id"))
            .unique(on: .init(stringLiteral: "\(name)_id"), "photo_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TwinType.SiblingModel.schema).delete()
    }
}
