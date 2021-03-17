//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 25.02.2021.
//

import Foundation
import Botter
import Vapor
import Fluent

protocol Twinable: class {
    associatedtype TwinType: Twinable
    
    static func create(other: TwinType, app: Application) throws -> Future<Self>
    
    func saveIfNeeded(app: Application) -> Future<Self>
}

extension Twinable where TwinType: Model { // non-model types
    func saveIfNeeded(app: Application) -> Future<Self> {
        app.eventLoopGroup.future(self)
    }

    static func find(
        _ id: TwinType.IDValue?,
        app: Application
    ) -> EventLoopFuture<Self?> {
        TwinType.find(id, on: app.db).optionalThrowingFlatMap { try Self.create(other: $0, app: app) }
    }
}

extension Twinable where Self: Model { // model types
    func saveIfNeeded(app: Application) -> Future<Self> {
        if self.id != nil {
            self._$id.exists = true
        }
        return self.save(on: app.db).transform(to: self)
    }
}
