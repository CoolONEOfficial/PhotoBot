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
    var hourPrice: Float = 0
    var promotions: [PromotionModel] = []
    
    required init() {}
    
}

extension Order: ModeledType {
    var isValid: Bool {
        true
    }
    
    func cancelAvailable(user: User) -> Bool {
        guard !isCancelled else { return false }
        return user.isAdmin || user.makeuperId == makeuperId || user.stylistId == stylistId || user.id == userId
    }
    
    func save(app: Application) throws -> EventLoopFuture<TwinType> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return try TwinType.create(other: self, app: app)
    }
}
