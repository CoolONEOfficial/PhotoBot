//
//  File.swift
//
//
//  Created by Nickolay Truhin on 31.01.2021.
//

import Foundation
import AnyCodable
import Botter

public struct OrderState: Codable {
    var type: OrderType!
    var stylistId: UUID?
    var makeuperId: UUID?
    var studioId: UUID?
    var date: Date?
    var duration: TimeInterval?
    var hourPrice: Float = 0
    var isCancelled = false
    var id: UUID?
    
    var price: Float {
        let hours: Float
        if let duration = duration {
            hours = Float(duration / 60 / 60)
        } else {
            hours = 1
        }
        return hours * hourPrice
    }
}

public extension OrderState {
    var watchers: [UUID] {
        [makeuperId, stylistId].compactMap { $0 }
    }
    
    var isValid: Bool {
        let requiredParams: [Any?] = [date, studioId, duration]
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
    init(with oldPayload: NodePayload?, type: OrderType? = nil, stylist: Stylist? = nil, makeuper: Makeuper? = nil, studio: Studio? = nil, date: Date? = nil, duration: TimeInterval? = nil) {
        let priceables: [Priceable?] = [ stylist, makeuper, studio ]
        let appendingPrice = priceables.compactMap { $0?.price }.reduce(0, +)
        if case let .orderBuilder(state) = oldPayload {
            self.init(
                type: type ?? state.type,
                stylistId: stylist?.id ?? state.stylistId,
                makeuperId: makeuper?.id ?? state.makeuperId,
                studioId: studio?.id ?? state.studioId,
                date: date ?? state.date,
                duration: duration ?? state.duration,
                hourPrice: state.hourPrice + appendingPrice
            )
        } else {
            self.init(
                type: type,
                stylistId: stylist?.id,
                makeuperId: makeuper?.id,
                studioId: studio?.id,
                date: date,
                duration: duration,
                hourPrice: appendingPrice
            )
        }
    }
}

public struct CheckoutState: Codable {
    var order: OrderState
    var promotions: [PromotionModel] = []
}

public enum NodePayload: Codable {
    case editText(messageId: Int)
    case build(type: BuildableType, object: [String: AnyCodable] = [:])
    case page(at: Int)
    case orderBuilder(OrderState)
    case checkout(CheckoutState)
    case calendar(year: Int, month: Int, day: Int? = nil, time: TimeInterval? = nil, needsConfirm: Bool = false)
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

        case let .calendar(year, month, day, time, needsConfirm):
            try container.encode(year, forKey: .calendarYear)
            try container.encode(month, forKey: .calendarMonth)
            try container.encode(day, forKey: .calendarDay)
            try container.encode(time, forKey: .calendarTime)
            try container.encode(needsConfirm, forKey: .calendarNeedsConfirm)
        }
    }

}
