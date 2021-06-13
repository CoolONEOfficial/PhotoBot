//
//  File.swift
//
//
//  Created by Nickolay Truhin on 31.01.2021.
//

import Foundation
import AnyCodable
import Vapor
import Botter

public struct OrderState: Codable {
    var type: OrderType!
    var stylistId: UUID?
    var makeuperId: UUID?
    var photographerId: UUID?
    var studioId: UUID?
    var date: Date?
    var duration: TimeInterval?
    var hourPrice: Float = 0
    var status: OrderStatus?
    var id: UUID?
    var userId: UUID?

    var price: Float {
        let hours: Float
        if let duration = duration {
            hours = Float(duration / 60 / 60)
        } else {
            hours = 1
        }
        return hours * hourPrice
    }
    
    init(type: OrderType? = nil, date: Date? = nil, duration: TimeInterval? = nil, status: OrderStatus? = nil, id: UUID? = nil, userId: UUID? = nil) {
        self.init(type: type, stylistId: nil, makeuperId: nil, photographerId: nil, studioId: nil, date: date, duration: duration, hourPrice: 0, status: status, id: id, userId: userId)
    }
    
    private init(type: OrderType? = nil, stylistId: UUID? = nil, makeuperId: UUID? = nil, photographerId: UUID? = nil, studioId: UUID? = nil, date: Date? = nil, duration: TimeInterval? = nil, hourPrice: Float = 0, status: OrderStatus? = nil, id: UUID? = nil, userId: UUID? = nil) {
        self.type = type
        self.stylistId = stylistId
        self.makeuperId = makeuperId
        self.photographerId = photographerId
        self.studioId = studioId
        self.date = date
        self.duration = duration
        self.hourPrice = hourPrice
        self.status = status
        self.id = id
        self.userId = userId
    }
}

extension OrderState {

    init<T: OrderProtocol>(from order: T) {
        self.init(type: order.type, stylistId: order.stylistId, makeuperId: order.makeuperId, photographerId: order.photographerId, studioId: order.studioId, date: order.interval.start, duration: order.interval.duration, hourPrice: order.hourPrice, status: order.status, id: order.id, userId: order.userId)
    }

}

public extension OrderState {
    var watchers: [UUID] {
        [makeuperId, stylistId, photographerId, studioId].compactMap { $0 }
    }
    
    var isValid: Bool {
        let requiredParams: [Any?] = [date, duration, photographerId]
//        switch type {
//        case .content: break
//            //requiredParams = [  ]
//        case .loveStory, .family:
//            requiredParams += [ makeuperId ]
//            
//        }
        return requiredParams.allSatisfy { $0 != nil }
    }
}

extension OrderState {
    init(with oldPayload: NodePayload?, type: OrderType? = nil, stylist: Stylist? = nil, makeuper: Makeuper? = nil, photographer: Photographer? = nil, studio: Studio? = nil, date: Date? = nil, duration: TimeInterval? = nil, customer: User? = nil) {
        let priceables: [Priceable?] = [ stylist, makeuper, photographer, studio ]
        
        if case let .orderBuilder(state) = oldPayload {
            let appendingPrice = priceables.compactMap { $0?.prices[type ?? state.type] }.reduce(0, +)
            self.init(
                type: type ?? state.type,
                stylistId: stylist?.id ?? state.stylistId,
                makeuperId: makeuper?.id ?? state.makeuperId,
                photographerId: photographer?.id ?? state.photographerId,
                studioId: studio?.id ?? state.studioId,
                date: date ?? state.date,
                duration: duration ?? state.duration,
                hourPrice: state.hourPrice + appendingPrice,
                userId: customer?.id ?? state.userId
            )
        } else {
            let appendingPrice = priceables.compactMap {
                if let type = type {
                    return $0?.prices[type]
                } else {
                    return $0?.prices.first?.value
                }
            }.reduce(Float(0), +)
            self.init(
                type: type,
                stylistId: stylist?.id,
                makeuperId: makeuper?.id,
                photographerId: photographer?.id,
                studioId: studio?.id,
                date: date,
                duration: duration,
                hourPrice: appendingPrice,
                userId: customer?.id
            )
        }
    }
}

public struct CheckoutState: Codable {
    var order: OrderState
    var promotions: [PromotionModel] = []
}

extension CheckoutState {
    static func create<T: OrderProtocol>(from order: T, app: Application) -> Future<CheckoutState> {
        order.getPromotions(app: app).map {
            .init(order: OrderState(from: order), promotions: $0)
        }
    }
}

public enum NodePayload: Codable {
    case editText(messageId: Int)
    case build(type: BuildableType, object: [String: AnyCodable] = [:])
    case page(at: Int)
    case orderBuilder(OrderState)
    case checkout(CheckoutState)
    case calendar(year: Int, month: Int, day: Int? = nil, time: TimeInterval? = nil, needsConfirm: Bool = false)
    case orderAgreement(orderId: UUID)
    case orderReplacement(orderId: UUID, type: MessageListType)
}

extension NodePayload {

    enum CodingKeys: String, CodingKey {
        case editTextMessageId
        case createBuildableType
        case createBuildableObject
        case pageAt
        case orderState
        case checkoutState
        case calendarYear
        case calendarMonth
        case calendarDay
        case calendarTime
        case calendarNeedsConfirm
        case orderAgreementId
        case orderReplacementId
        case orderReplacementType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.editTextMessageId), try container.decodeNil(forKey: .editTextMessageId) == false {
            let messageId = try container.decode(Int.self, forKey: .editTextMessageId)
            self = .editText(messageId: messageId)
            return
        }
        if container.allKeys.contains(.createBuildableType), try container.decodeNil(forKey: .createBuildableType) == false {
            let buildableType = try container.decode(BuildableType.self, forKey: .createBuildableType)
            let object = try container.decode([String: AnyCodable].self, forKey: .createBuildableObject)
            self = .build(type: buildableType, object: object)
            return
        }
        if container.allKeys.contains(.pageAt), try container.decodeNil(forKey: .pageAt) == false {
            let num = try container.decode(Int.self, forKey: .pageAt)
            self = .page(at: num)
            return
        }
        if container.allKeys.contains(.orderAgreementId), try container.decodeNil(forKey: .orderAgreementId) == false {
            let orderId = try container.decode(UUID.self, forKey: .orderAgreementId)
            self = .orderAgreement(orderId: orderId)
            return
        }
        if container.allKeys.contains(.orderReplacementId), try container.decodeNil(forKey: .orderReplacementId) == false,
           container.allKeys.contains(.orderReplacementType), try container.decodeNil(forKey: .orderReplacementType) == false{
            let id = try container.decode(UUID.self, forKey: .orderReplacementId)
            let type = try container.decode(MessageListType.self, forKey: .orderReplacementType)
            self = .orderReplacement(orderId: id, type: type)
            return
        }
        if container.allKeys.contains(.orderState) {
            let state = try container.decode(OrderState.self, forKey: .orderState)
            self = .orderBuilder(state)
            return
        }
        if container.allKeys.contains(.checkoutState) {
            let state = try container.decode(CheckoutState.self, forKey: .checkoutState)
            self = .checkout(state)
            return
        }
        if container.allKeys.contains(.calendarMonth), container.allKeys.contains(.calendarYear) {
            let year = try container.decode(Int.self, forKey: .calendarYear)
            let month = try container.decode(Int.self, forKey: .calendarMonth)
            let day = try container.decodeIfPresent(Int.self, forKey: .calendarDay)
            let time = try container.decodeIfPresent(TimeInterval.self, forKey: .calendarTime)
            let needsConfirm = try container.decodeIfPresent(Bool.self, forKey: .calendarNeedsConfirm)
            self = .calendar(year: year, month: month, day: day, time: time, needsConfirm: needsConfirm!)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .editText(messageId):
            try container.encode(messageId, forKey: .editTextMessageId)

        case let .build(buildableType, object):
            try container.encode(buildableType, forKey: .createBuildableType)
            try container.encode(AnyCodable(object.unwrapped), forKey: .createBuildableObject)

        case let .page(num):
            try container.encode(num, forKey: .pageAt)

        case let .orderBuilder(state):
            try container.encode(state, forKey: .orderState)
        
        case let .checkout(checkout):
            try container.encode(checkout, forKey: .checkoutState)

        case let .orderAgreement(orderId):
            try container.encode(orderId, forKey: .orderAgreementId)
            
        case let .orderReplacement(id, type):
            try container.encode(type, forKey: .orderReplacementType)
            try container.encode(id, forKey: .orderReplacementId)

        case let .calendar(year, month, day, time, needsConfirm):
            try container.encode(year, forKey: .calendarYear)
            try container.encode(month, forKey: .calendarMonth)
            try container.encode(day, forKey: .calendarDay)
            try container.encode(time, forKey: .calendarTime)
            try container.encode(needsConfirm, forKey: .calendarNeedsConfirm)
        }
    }

}
