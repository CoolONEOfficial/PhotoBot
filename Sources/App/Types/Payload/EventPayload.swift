//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

public enum EventPayload {
    case editText(messageId: Int)
    case selectStylist(id: UUID)
    case selectMakeuper(id: UUID)
    case selectPhotographer(id: UUID)
    case selectStudio(id: UUID)
    case selectDay(date: Date)
    case selectTime(time: TimeInterval)
    case selectDuration(duration: TimeInterval)
    case createOrder
    case pushCheckout(state: OrderState)
    case cancelOrder(id: UUID)
    case handleOrderAgreement(orderId: UUID, agreement: Bool)
    case handleOrderReplacement(Bool)
    case applyOrderReplacement(orderId: UUID, state: OrderState)

    // MARK: Navigation
    
    case back
    case push(PushTarget, payload: NodePayload? = nil, saveToHistory: Bool = true)
    case previousPage
    case nextPage
}

extension EventPayload: Codable {

    enum CodingKeys: String, CodingKey {
        case editText
        case selectStylist = "selStylist"
        case selectMakeuper = "selMakeuper"
        case selectStudio = "selStudio"
        case selectPhotographer = "selPhoto"
        case selectDay = "selDay"
        case selectTime = "selTime"
        case selectDuration = "selDuration"
        case createOrder
        case cancelOrderId
        case back
        case push
        case pushToCheckoutState
        case previousPage
        case nextPage
        case orderAgreementOrderId
        case orderAgreement
        case orderReplacement
        case orderReplacementState
        case orderReplacementId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.editText), try container.decodeNil(forKey: .editText) == false {
            let messageId = try container.decode(Int.self, forKey: .editText)
            self = .editText(messageId: messageId)
            return
        }
        if container.allKeys.contains(.selectStylist), try container.decodeNil(forKey: .selectStylist) == false {
            let id = try container.decode(UUID.self, forKey: .selectStylist)
            self = .selectStylist(id: id)
            return
        }
        if container.allKeys.contains(.selectMakeuper), try container.decodeNil(forKey: .selectMakeuper) == false {
            let id = try container.decode(UUID.self, forKey: .selectMakeuper)
            self = .selectMakeuper(id: id)
            return
        }
        if container.allKeys.contains(.selectStudio), try container.decodeNil(forKey: .selectStudio) == false {
            let id = try container.decode(UUID.self, forKey: .selectStudio)
            self = .selectStudio(id: id)
            return
        }
        if container.allKeys.contains(.selectPhotographer), try container.decodeNil(forKey: .selectPhotographer) == false {
            let id = try container.decode(UUID.self, forKey: .selectPhotographer)
            self = .selectPhotographer(id: id)
            return
        }
        if container.allKeys.contains(.selectDay), try container.decodeNil(forKey: .selectDay) == false {
            let date = try container.decode(Date.self, forKey: .selectDay)
            self = .selectDay(date: date)
            return
        }
        if container.allKeys.contains(.selectTime), try container.decodeNil(forKey: .selectTime) == false {
            let time = try container.decode(TimeInterval.self, forKey: .selectTime)
            self = .selectTime(time: time)
            return
        }
        if container.allKeys.contains(.selectDuration), try container.decodeNil(forKey: .selectDuration) == false {
            let duration = try container.decode(TimeInterval.self, forKey: .selectDuration)
            self = .selectDuration(duration: duration)
            return
        }
        if container.allKeys.contains(.createOrder), try container.decodeNil(forKey: .createOrder) == false {
            self = .createOrder
            return
        }
        if container.allKeys.contains(.cancelOrderId), try container.decodeNil(forKey: .cancelOrderId) == false {
            let id = try container.decode(UUID.self, forKey: .cancelOrderId)
            self = .cancelOrder(id: id)
            return
        }
        if container.allKeys.contains(.back), try container.decodeNil(forKey: .back) == false {
            self = .back
            return
        }
        if container.allKeys.contains(.push), try container.decodeNil(forKey: .push) == false {
            var associatedValues = try container.nestedUnkeyedContainer(forKey: .push)
            let target = try associatedValues.decode(PushTarget.self)
            let nodePayload = try associatedValues.decodeIfPresent(NodePayload.self)
            let saveToHistory = try associatedValues.decode(Bool.self)
            self = .push(target, payload: nodePayload, saveToHistory: saveToHistory)
            return
        }
        if container.allKeys.contains(.previousPage), try container.decodeNil(forKey: .previousPage) == false {
            self = .previousPage
            return
        }
        if container.allKeys.contains(.nextPage), try container.decodeNil(forKey: .nextPage) == false {
            self = .nextPage
            return
        }
        if container.allKeys.contains(.pushToCheckoutState), try container.decodeNil(forKey: .pushToCheckoutState) == false {
            let state = try container.decode(OrderState.self, forKey: .pushToCheckoutState)
            self = .pushCheckout(state: state)
            return
        }
        if container.allKeys.contains(.orderAgreement), try container.decodeNil(forKey: .orderAgreement) == false,
           container.allKeys.contains(.orderAgreementOrderId), try container.decodeNil(forKey: .orderAgreementOrderId) == false{
            let agreement = try container.decode(Bool.self, forKey: .orderAgreement)
            let orderId = try container.decode(UUID.self, forKey: .orderAgreementOrderId)
            self = .handleOrderAgreement(orderId: orderId, agreement: agreement)
            return
        }
        if container.allKeys.contains(.orderReplacement), try container.decodeNil(forKey: .orderReplacement) == false {
            let replacement = try container.decode(Bool.self, forKey: .orderReplacement)
            self = .handleOrderReplacement(replacement)
            return
        }
        if container.allKeys.contains(.orderReplacementState), try container.decodeNil(forKey: .orderReplacementState) == false,
           container.allKeys.contains(.orderReplacementId), try container.decodeNil(forKey: .orderReplacementId) == false{
            let state = try container.decode(OrderState.self, forKey: .orderReplacementState)
            let orderId = try container.decode(UUID.self, forKey: .orderReplacementId)
            self = .applyOrderReplacement(orderId: orderId, state: state)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .editText(messageId):
            try container.encode(messageId, forKey: .editText)
        case let .selectStylist(id):
            try container.encode(id, forKey: .selectStylist)
        case let .selectMakeuper(id):
            try container.encode(id, forKey: .selectMakeuper)
        case let .selectStudio(id):
            try container.encode(id, forKey: .selectStudio)
        case let .selectPhotographer(id):
            try container.encode(id, forKey: .selectPhotographer)
        case let .selectDay(date):
            try container.encode(date, forKey: .selectDay)
        case let .selectTime(timeInterval):
            try container.encode(timeInterval, forKey: .selectTime)
        case let .selectDuration(duration):
            try container.encode(duration, forKey: .selectDuration)
        case .createOrder:
            try container.encode(true, forKey: .createOrder)
        case let .cancelOrder(id):
            try container.encode(id, forKey: .cancelOrderId)
        case .back:
            _ = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .back)
        case let .push(associatedValue0, associatedValue1, associatedValue2):
            var associatedValues = container.nestedUnkeyedContainer(forKey: .push)
            try associatedValues.encode(associatedValue0)
            try associatedValues.encode(associatedValue1)
            try associatedValues.encode(associatedValue2)
        case let .pushCheckout(state):
            try container.encode(state, forKey: .pushToCheckoutState)
        case let .handleOrderAgreement(orderId, agreement):
            try container.encode(agreement, forKey: .orderAgreement)
            try container.encode(orderId, forKey: .orderAgreementOrderId)
        case let .handleOrderReplacement(replacement):
            try container.encode(replacement, forKey: .orderReplacement)
        case let .applyOrderReplacement(orderId, state):
            try container.encode(state, forKey: .orderReplacementState)
            try container.encode(orderId, forKey: .orderReplacementId)
        case .previousPage:
            try container.encode(true, forKey: .previousPage)
        case .nextPage:
            try container.encode(true, forKey: .nextPage)
        }
    }

}

public enum PushTarget {
    case id(UUID)
    case entryPoint(EntryPoint)
}

enum PushTargetError: Error {
    case decodeFailed
}

extension PushTarget: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let id = try? container.decode(UUID.self) {
            self = .id(id)
        } else if let entryPoint = try? container.decode(EntryPoint.self) {
            self = .entryPoint(entryPoint)
        } else {
            throw PushTargetError.decodeFailed
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .entryPoint(entryPoint):
            try container.encode(entryPoint)
        
        case let .id(id):
            try container.encode(id)
        }
    }
}
