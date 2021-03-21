//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.03.2021.
//

import Fluent
import Vapor

protocol CreateSiblingPromotions: Migration {
    associatedtype TwinType: PromotionsProtocol & ModeledType
    
    var name: String { get }
}

extension CreateSiblingPromotions {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TwinType.SiblingModel.schema)
            .id()
            .field(.init(stringLiteral: "\(name)_id"), .uuid, .required, .references(TwinType.TwinType.schema, "id"))
            .field("promotion_id", .uuid, .required, .references(PromotionModel.schema, "id"))
            .unique(on: .init(stringLiteral: "\(name)_id"), "promotion_id")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(TwinType.SiblingModel.schema).delete()
    }
}
