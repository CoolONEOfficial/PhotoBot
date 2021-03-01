//
//  File.swift
//
//
//  Created by Nickolay Truhin on 25.02.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

protocol PromotionProtocol: Cloneable where TwinType: PromotionProtocol {
    var id: UUID? { get set }
    var name: String? { get set }
    var description: String? { get set }
    
    init()
    static func create(id: UUID?, name: String?, description: String?, app: Application) -> Future<Self>
}

extension PromotionProtocol {
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        Self.create(id: other.id, name: other.name, description: other.description, app: app)
    }
    
    static func create(id: UUID? = nil, name: String?, description: String?, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.name = name
        instance.description = description
        return instance.saveIfNeeded(app: app)
    }
}
