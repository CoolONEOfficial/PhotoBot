//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.03.2021.
//

import Foundation
import Vapor
import Fluent
import Botter
import FluentSQL

protocol OrderProtocol: Cloneable where TwinType: OrderProtocol {
    
    var id: UUID? { get set }
    var stylistId: UUID? { get set }
    var makeuperId: UUID? { get set }
    var studioId: UUID? { get set }
    var date: Date { get set }
    var price: Int { get set }
    
    init()
    static func create(id: UUID?, stylistId: UUID?, makeuperId: UUID?, studioId: UUID?, date: Date, price: Int, app: Application) -> Future<Self>
}

enum OrderCreateError: Error {
    case noDate
}

extension OrderProtocol {
    static func create(other: TwinType, app: Application) -> Future<Self> {
        Self.create(id: other.id, stylistId: other.stylistId, makeuperId: other.makeuperId, studioId: other.studioId, date: other.date, price: other.price, app: app)
    }
    
    static func create(id: UUID? = nil, stylistId: UUID?, makeuperId: UUID?, studioId: UUID?, date: Date, price: Int = 0, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.stylistId = stylistId
        instance.makeuperId = makeuperId
        instance.studioId = studioId
        instance.date = date
        instance.price = price
        return instance.saveIfNeeded(app: app)
    }
    
    static func create(id: UUID? = nil, checkoutState: CheckoutState, app: Application) throws -> Future<Self> {
        let order = checkoutState.order
        guard let date = order.date else { throw OrderCreateError.noDate }
        return Self.create(
            stylistId: order.stylistId,
            makeuperId: order.makeuperId,
            studioId: order.studioId,
            date: date,
            price: order.price,
            app: app
        )
    }
}
