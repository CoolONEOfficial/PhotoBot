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

protocol Cloneable: class {
    associatedtype TwinType: Cloneable
    
    static func create(other: TwinType, app: Application) -> Future<Self>
    
    func saveIfNeeded(app: Application) -> Future<Self>
}

extension Cloneable where TwinType: Model { // non-model types
    func saveIfNeeded(app: Application) -> Future<Self> {
        app.eventLoopGroup.future(self)
    }

    static func find(
        _ id: TwinType.IDValue?,
        app: Application
    ) -> EventLoopFuture<Self?> {
        TwinType.find(id, on: app.db).optionalFlatMap { Self.create(other: $0, app: app) }
    }
}

extension Cloneable where Self: Model { // model types
    func saveIfNeeded(app: Application) -> Future<Self> {
        if self.id != nil {
            self._$id.exists = true
        }
        return self.save(on: app.db).transform(to: self)
    }
}
