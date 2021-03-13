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

enum OrderType: String, Codable {
    case loveStory
    case family
    case content
}

extension OrderType {
    var name: String {
        switch self {
        case .loveStory:
            return "Love story"
        case .family:
            return "Семейная фотосессия"
        case .content:
            return "Контент-сьемка"
        }
    }
}

protocol OrderProtocol: Cloneable where TwinType: OrderProtocol {
    
    var id: UUID? { get set }
    var type: OrderType! { get set }
    var stylistId: UUID? { get set }
    var makeuperId: UUID? { get set }
    var studioId: UUID? { get set }
    var interval: DateInterval { get set }
    var price: Int { get set }
    
    init()
    static func create(id: UUID?, type: OrderType, stylistId: UUID?, makeuperId: UUID?, studioId: UUID?, interval: DateInterval, price: Int, app: Application) -> Future<Self>
}

enum OrderCreateError: Error {
    case noDateOrType
}

extension OrderProtocol {
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        Self.create(id: other.id, type: other.type, stylistId: other.stylistId, makeuperId: other.makeuperId, studioId: other.studioId, interval: other.interval, price: other.price, app: app)
    }
    
    static func create(id: UUID? = nil, type: OrderType, stylistId: UUID?, makeuperId: UUID?, studioId: UUID?, interval: DateInterval, price: Int = 0, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.type = type
        instance.stylistId = stylistId
        instance.makeuperId = makeuperId
        instance.studioId = studioId
        instance.interval = interval
        instance.price = price
        return instance.saveIfNeeded(app: app)
    }
    
    static func create(id: UUID? = nil, checkoutState: CheckoutState, app: Application) throws -> Future<Self> {
        let order = checkoutState.order
        guard let date = order.date,
              let duration = order.duration,
              let type = order.type else { throw OrderCreateError.noDateOrType }
        return Self.create(
            type: type,
            stylistId: order.stylistId,
            makeuperId: order.makeuperId,
            studioId: order.studioId,
            interval: .init(start: date, duration: duration),
            price: order.price,
            app: app
        )
    }
}
