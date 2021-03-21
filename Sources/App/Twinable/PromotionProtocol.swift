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

protocol PromotionProtocol: Twinable where TwinType: PromotionProtocol {
    var id: UUID? { get set }
    var autoApply: Bool { get set }
    var name: String? { get set }
    var description: String? { get set }
    var promocode: String? { get set }
    var impact: PromotionImpact! { get set }
    var condition: PromotionCondition! { get set }
    
    init()
    static func create(id: UUID?, autoApply: Bool, name: String, description: String, promocode: String?, impact: PromotionImpact, condition: PromotionCondition, app: Application) -> Future<Self>
}

extension PromotionProtocol {
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        guard let description = other.description, let name = other.name else {
            throw ModeledTypeError.validationError(self)
        }
        return Self.create(id: other.id, autoApply: other.autoApply, name: name, description: description, promocode: other.promocode, impact: other.impact, condition: other.condition, app: app)
    }
    
    static func create(id: UUID? = nil, autoApply: Bool = false, name: String, description: String, promocode: String? = nil, impact: PromotionImpact, condition: PromotionCondition, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.autoApply = autoApply
        instance.name = name
        instance.description = description
        instance.promocode = promocode
        instance.condition = condition
        instance.impact = impact
        return instance.saveIfNeeded(app: app)
    }
}

extension Array where Element: PromotionProtocol {
    func applying(to price: Float) -> Float {
        reduce(Float(price)) { $1.impact.applying(to: $0) }
    }
}
