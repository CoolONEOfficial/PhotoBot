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
    
    static func create(other: TwinType, app: Application) throws -> Future<Self>
    
    func saveIfNeeded(app: Application) -> Future<Self>
}

extension Cloneable {
    func saveIfNeeded(app: Application) -> Future<Self> {
        app.eventLoopGroup.future(self)
    }
}

extension Cloneable where Self: Model {
    func saveIfNeeded(app: Application) -> Future<Self> {
        self.save(on: app.db).transform(to: self)
    }
}
