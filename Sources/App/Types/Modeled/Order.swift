//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.03.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent

public final class Order: OrderProtocol {
    
    typealias TwinType = OrderModel
    
    var id: UUID?
    var userId: UUID!
    var type: OrderType!
    var isCancelled: Bool = false
    var stylistId: UUID?
    var makeuperId: UUID?
    var studioId: UUID?
    var interval: DateInterval = .init()
    var price: Float = 0
    var promotions: [PromotionModel] = []
    
    required init() {}
    
}

extension Order: ModeledType {
    var isValid: Bool {
        true
    }
    
    func save(app: Application) throws -> EventLoopFuture<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return try TwinType.create(other: self, app: app)
    }
}
