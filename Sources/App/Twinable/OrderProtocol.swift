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

enum OrderStatus: String, Codable {
    case inAgreement
    case inProgress
    case finished
    case cancelled
}

extension OrderStatus: CustomStringConvertible {
    var description: String {
        switch self {
        case .inAgreement:
            return "На согласовании"

        case .inProgress:
            return "На исполнении"
            
        case .finished:
            return "Завершен"

        case .cancelled:
            return "Отменен"
        }
    }
}

protocol OrderProtocol: PromotionsProtocol, Twinable where TwinType: OrderProtocol {

    associatedtype ImplementingModel = OrderModel
    associatedtype SiblingModel = OrderPromotion

    var id: UUID? { get set }
    var userId: UUID! { get set }
    var type: OrderType! { get set }
    var status: OrderStatus { get set }
    var stylistId: UUID? { get set }
    var makeuperId: UUID? { get set }
    var photographerId: UUID? { get set }
    var studioId: UUID? { get set }
    var interval: DateInterval { get set }
    var hourPrice: Float { get set }
    var promotions: [PromotionModel] { get set }
    
    init()
    static func create(id: UUID?, userId: UUID, type: OrderType, stylistId: UUID?, makeuperId: UUID?, photographerId: UUID?, studioId: UUID?, interval: DateInterval, price: Float, promotions: [PromotionModel], status: OrderStatus, app: Application) -> Future<Self>
}

enum OrderCreateError: Error {
    case noDateOrType
}

extension OrderProtocol {
    static func create(other: TwinType, app: Application) throws -> Future<Self> {
        other.getPromotions(app: app).flatMap { promotions in
            Self.create(id: other.id, userId: other.userId, type: other.type, stylistId: other.stylistId, makeuperId: other.makeuperId, photographerId: other.photographerId, studioId: other.studioId, interval: other.interval, price: other.hourPrice, promotions: promotions, status: other.status, app: app)
        }
    }
    
    static func create(id: UUID? = nil, userId: UUID, type: OrderType, stylistId: UUID?, makeuperId: UUID?, photographerId: UUID?, studioId: UUID?, interval: DateInterval, price: Float = 0, promotions: [PromotionModel], status: OrderStatus = .inAgreement, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.userId = userId
        instance.type = type
        instance.stylistId = stylistId
        instance.makeuperId = makeuperId
        instance.studioId = studioId
        instance.photographerId = photographerId
        instance.interval = interval
        instance.hourPrice = price
        instance.status = status
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
            photographerId: order.photographerId,
            studioId: order.studioId,
            interval: .init(start: date, duration: duration),
            price: order.hourPrice,
            promotions: checkoutState.promotions,
            app: app
        )
    }
    
    func merge(with order: OrderState) {
        if let date = order.date {
            interval.start = date
        }
        if let duration = order.duration {
            interval.duration = duration
        }
        if let type = order.type {
            self.type = type
        }
        if let stylistId = order.stylistId {
            self.stylistId = stylistId
        }
        if let makeuperId = order.makeuperId {
            self.makeuperId = makeuperId
        }
        if let photographerId = order.photographerId {
            self.photographerId = photographerId
        }
        if let studioId = order.studioId {
            self.studioId = studioId
        }
        
    }
}

extension OrderState {
    func getMergedUser(app: Application) -> Future<UserModel?>? {
        if let photographerId = photographerId {
            return Photographer.find(photographerId, app: app).optionalFlatMap { $0.getUser(app: app) }
        }
        if let studioId = studioId {
            return Studio.find(studioId, app: app).optionalFlatMap { $0.getUser(app: app) }
        }
        if let stylistId = stylistId {
            return Stylist.find(stylistId, app: app).optionalFlatMap { $0.getUser(app: app) }
        }
        if let makeuperId = makeuperId {
            return Makeuper.find(makeuperId, app: app).optionalFlatMap { $0.getUser(app: app) }
        }
        return nil
    }
}
