//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.03.2021.
//

import Fluent

struct CreateOrders: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(OrderModel.schema)
            .id()
            .field("stylist_id", .uuid, .references(StylistModel.schema, "id"))
            .field("makeuper_id", .uuid, .references(MakeuperModel.schema, "id"))
            .field("studio_id", .uuid, .references(StudioModel.schema, "id"))
            .field("price", .int, .required)
            .field("start_date", .datetime, .required)
            .field("end_date", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(OrderModel.schema).delete()
    }
}
