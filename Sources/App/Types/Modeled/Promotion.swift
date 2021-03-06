//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 24.02.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent

final class Promotion: PromotionProtocol {
    
    typealias TwinType = PromotionModel
    
    var id: UUID?
    
    @Validated(.nonEmpty)
    var name: String?
    
    @Validated(.nonEmpty)
    var description: String?

    var impact: PromotionImpact?
    
    var condition: PromotionCondition?

    required init() {}
    
}

extension Promotion: ModeledType {
    
    var isValid: Bool {
        _name.isValid
    }
    
    func save(app: Application) throws -> Future<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return TwinType.create(other: self, app: app)
    }
}