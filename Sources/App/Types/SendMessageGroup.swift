//
//  SendMessageGroup.swift
//  
//
//  Created by Nickolay Truhin on 01.02.2021.
//

import Foundation
import Botter
import Vapor
import Fluent

enum SendMessageGroupError: Error {
    case messagesNotFound
    case invalidPayload
    case nodesNotFound
}

extension NSObject {
    func propertyNames() -> [String] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap{ $0.label }
    }
}


extension Optional {
    var wrappedType: Any.Type {
        Wrapped.self
    }
}

public enum MessageListType: String, Codable {
    case portfolio
    case stylists
    case makeupers
    case studios
    case reviews
    case orders
}

public enum SendMessageGroup {
    case array(_ elements: [SendMessage])
    case list(_ content: MessageListType)
    case orderTypes
    case orderBuilder
    case orderCheckout
    case welcome
    case calendar
    
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol) throws -> Future<[SendMessage]> {
        var result: Future<[SendMessage]>?
        let user = context.user
        let app = context.app
        
        for controller in context.controllers {
            result = try controller.getSendMessages(platform: platform, in: node, payload, context: context, group: self)
            if result != nil {
                break
            }
        }
        
        switch self {
        case var .array(arr):
            
            if !node.systemic, user.isValid, user.isAdmin {
                for (index, params) in arr.enumerated() {
                    params.keyboard.buttons.insert([
                        try! Button(
                            text: "Редактировать текст",
                            action: .callback,
                            eventPayload: .editText(messageId: index)
                        )
                    ], at: 0)
                    arr[index] = params
                }
            }
            result = app.eventLoopGroup.future(arr)

        case let .list(type):
            
            var pageNumber: Int
            if case let .page(num) = payload {
                pageNumber = num
            } else {
                pageNumber = 0
            }
            
            let itemsPerPage = 3
            let startIndex = pageNumber * itemsPerPage
            let endIndex = startIndex + itemsPerPage
            let indexRange = startIndex..<endIndex
            
            for controller in context.controllers {
                if result != nil {
                    break
                }
                result = try controller.getListSendMessages(platform: platform, in: node, payload, context: context, listType: type, indexRange: indexRange)?
                    .map { ($0.0.isEmpty ? [ SendMessage(text: "Тут пусто") ] : $0.0, $0.1) }
                    .map { Self.addPageButtons($0.0, indexRange, $0.1) }
            }
            
        case .orderBuilder:
            
            guard case let .orderBuilder(state) = payload, let type = state.type else {
                return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
            }
            
            var keyboard: Keyboard = [[
                try .init(text: "Студия", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderStudio))),
                try .init(text: "Дата", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderDate)))
            ]]

            switch type {
            case .loveStory, .family:
                keyboard.buttons[0].insert(contentsOf: [
                    try .init(text: "Стилист", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderStylist))),
                    try .init(text: "Визажист", action: .callback, eventPayload: .push(.entryPoint(.orderBuilderMakeuper))),
                ], at: 0)
            case .content: break
            }
            
            if state.isValid {
                keyboard.buttons.safeAppend([
                    try .init(text: "👌 К завершению", action: .callback, eventPayload: .pushCheckout(state: state))
                ])
            }
            
            result = app.eventLoopGroup.future([ .init(
                text: [
                    "Ваш заказ:",
                    .replacing(by: .orderBlock),
                    "Сумма: " + .replacing(by: .price) + " ₽"
                ].joined(separator: "\n"),
                keyboard: keyboard
            ) ])
            
        case .orderCheckout:
            result = app.eventLoopGroup.future([ .init(
                text: [
                    "Оформление заказа",
                    .replacing(by: .orderBlock),
                    .replacing(by: .priceBlock),
                    .replacing(by: .promoBlock),
                ].joined(separator: "\n"),
                keyboard: [[
                    try .init(text: "✅ Отправить", action: .callback, eventPayload: .createOrder)
                ]]
            ) ])

        default: break
        }
        
        guard let resultFuture = result else { throw SendMessageGroupError.messagesNotFound }

        return resultFuture.map { Self.addNavigationButtons($0, user) }
            .flatMapEach(on: app.eventLoopGroup.next()) { Self.formatMessage($0, platform: platform, context: context) }
    }

    static private func addPageButtons(_ messages: [SendMessage], _ indexRange: Range<Int>, _ count: Int) -> [SendMessage] {
        if let lastMessage = messages.last {
            var buttons = [Button]()
            if indexRange.lowerBound > 0, let prevButton = try? Button(text: "Предыдущая стр", action: .callback, eventPayload: .previousPage) {
                buttons.append(prevButton)
            }
            if indexRange.upperBound < count, let nextButton = try? Button(text: "Следующая стр", action: .callback, eventPayload: .nextPage) {
                buttons.append(nextButton)
            }
            
            lastMessage.keyboard.buttons.append(buttons)
        }
        return messages
    }
    
    static private func addNavigationButtons(_ messages: [SendMessage], _ user: User) -> [SendMessage] {
        if !user.history.isEmpty, let lastMessage = messages.last {
            lastMessage.keyboard.buttons.safeAppend([ try! .init(
                text: user.history.last?.nodeId == user.nodeId ? "❌ Отменить действие" : "👈 Назад",
                action: .callback, eventPayload: .back
            ) ])
        }
        return messages
    }
    
    static private func formatMessage(_ message: SendMessage, platform: AnyPlatform? = nil, context: PhotoBotContextProtocol) -> Future<SendMessage> {
        if let text = message.text {
            return MessageFormatter.shared.format(text, platform: platform, context: context).map { text in
                message.text = text
                return message
            }
        } else {
            return context.app.eventLoopGroup.future(message)
        }
    }

}

extension SendMessageGroup: Codable {

    enum CodingKeys: String, CodingKey {
        case builder
        case elements
        case listType
        case orderBuilder
        case orderCheckout
        case orderTypes
        case welcome
        case calendar
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.elements), try container.decodeNil(forKey: .elements) == false {
            let elements = try container.decode([SendMessage].self, forKey: .elements)
            self = .array(elements)
            return
        }
        if container.allKeys.contains(.listType), try container.decodeNil(forKey: .listType) == false {
            let type = try container.decode(MessageListType.self, forKey: .listType)
            self = .list(type)
            return
        }
        if container.allKeys.contains(.orderBuilder), try container.decodeNil(forKey: .orderBuilder) == false {
            self = .orderBuilder
            return
        }
        if container.allKeys.contains(.orderCheckout), try container.decodeNil(forKey: .orderCheckout) == false {
            self = .orderCheckout
            return
        }
        if container.allKeys.contains(.orderTypes), try container.decodeNil(forKey: .orderTypes) == false {
            self = .orderTypes
            return
        }
        if container.allKeys.contains(.welcome), try container.decodeNil(forKey: .welcome) == false {
            self = .welcome
            return
        }
        if container.allKeys.contains(.calendar), try container.decodeNil(forKey: .calendar) == false {
            self = .calendar
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .array(elements):
            try container.encode(elements, forKey: .elements)
        case let .list(type):
            try container.encode(type, forKey: .listType)
        case .orderBuilder:
            try container.encode(true, forKey: .orderBuilder)
        case .orderCheckout:
            try container.encode(true, forKey: .orderCheckout)
        case .welcome:
            try container.encode(true, forKey: .welcome)
        case .calendar:
            try container.encode(true, forKey: .calendar)
        case .orderTypes:
            try container.encode(true, forKey: .orderTypes)
        }
    }

}

extension SendMessageGroup: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = SendMessage

    public init(arrayLiteral elements: SendMessage...) {
        self = .array(elements)
    }
}
