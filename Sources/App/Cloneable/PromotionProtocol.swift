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
    var impact: PromotionImpact? { get set }
    var condition: PromotionCondition? { get set }
    
    init()
    static func create(id: UUID?, name: String?, description: String?, impact: PromotionImpact?, condition: PromotionCondition?, app: Application) -> Future<Self>
}

extension PromotionProtocol {
    static func create(other: TwinType, app: Application) -> Future<Self> {
        Self.create(id: other.id, name: other.name, description: other.description, impact: other.impact, condition: other.condition, app: app)
    }
    
    static func create(id: UUID? = nil, name: String?, description: String?, impact: PromotionImpact?, condition: PromotionCondition?, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.name = name
        instance.description = description
        instance.condition = condition
        instance.impact = impact
        return instance.saveIfNeeded(app: app)
    }
}
