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

protocol OrderProtocol: PromotionsProtocol, Twinable where TwinType: OrderProtocol {

    associatedtype ImplementingModel = OrderModel
    associatedtype SiblingModel = OrderPromotion

    var id: UUID? { get set }
    var userId: UUID! { get set }
    var type: OrderType! { get set }
    var isCancelled: Bool { get set }
    var stylistId: UUID? { get set }
    var makeuperId: UUID? { get set }
    var studioId: UUID? { get set }
    var interval: DateInterval { get set }
    var price: Float { get set }
    var promotions: [PromotionModel] { get set }
    
    init()
    static func create(id: UUID?, userId: UUID, type: OrderType, stylistId: UUID?, makeuperId: UUID?, studioId: UUID?, interval: DateInterval, price: Float, promotions: [PromotionModel], isCancelled: Bool, app: Application) -> Future<Self>
}

enum OrderCreateError: Error {
    case noDateOrType
}

extension OrderProtocol {
    func state(app: Application) -> Future<CheckoutState> {
        getPromotions(app: app).map { [self] promotions in
            CheckoutState(order: .init(type: type, stylistId: stylistId, makeuperId: makeuperId, studioId: studioId, date: interval.start, duration: interval.duration, hourPrice: price, isCancelled: isCancelled, id: id), promotions: promotions)
        }
    }
    
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        other.getPromotions(app: app).flatMap { promotions in
            Self.create(id: other.id, userId: other.userId, type: other.type, stylistId: other.stylistId, makeuperId: other.makeuperId, studioId: other.studioId, interval: other.interval, price: other.price, promotions: promotions, isCancelled: other.isCancelled, app: app)
        }
    }
    
    static func create(id: UUID? = nil, userId: UUID, type: OrderType, stylistId: UUID?, makeuperId: UUID?, studioId: UUID?, interval: DateInterval, price: Float = 0, promotions: [PromotionModel], isCancelled: Bool = false, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.userId = userId
        instance.type = type
        instance.stylistId = stylistId
        instance.makeuperId = makeuperId
        instance.studioId = studioId
        instance.interval = interval
        instance.price = price
        instance.isCancelled = isCancelled
        return instance.saveIfNeeded(app: app).throwingFlatMap {
            try $0.attachPromotions(promotions, app: app).transform(to: instance)
        }
    }
    
    static func create(id: UUID? = nil, userId: UUID, checkoutState: CheckoutState, app: Application) throws -> Future<Self> {
        let order = checkoutState.order
        guard let date = order.date,
              let duration = order.duration,
              let type = order.type else { throw OrderCreateError.noDateOrType }
        return Self.create(
            userId: userId,
            type: type,
            stylistId: order.stylistId,
            makeuperId: order.makeuperId,
            studioId: order.studioId,
            interval: .init(start: date, duration: duration),
            price: order.hourPrice,
            promotions: checkoutState.promotions,
            isCancelled: false,
            app: app
        )
    }
}
