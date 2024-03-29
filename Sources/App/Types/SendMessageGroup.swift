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
    case photographers
    case orders

    static let orderReplaceable: [Self] = [ .makeupers, .studios, .stylists, .photographers ]

    var listNodeEntryPoint: EntryPoint {
        switch self {
        case .portfolio:        return .portfolio
        case .stylists:         return .orderBuilderStylist
        case .makeupers:        return .orderBuilderMakeuper
        case .studios:          return .orderBuilderStudio
        case .reviews:          return .reviews
        case .photographers:    return .orderBuilderPhotographer
        case .orders:           return .orders
        }
    }
}

public enum SendMessageGroup {
    case array(_ elements: [SendMessage])
    case list(_ content: MessageListType)
    case orderTypes
    case orderReplacement
    case orderBuilder
    case orderCheckout
    case welcome
    case calendar
    case orderAgreement
    case editNodeText
    
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

        default: break
        }
        
        guard var resultFuture = result else { throw SendMessageGroupError.messagesNotFound }

        if node.closeable {
            resultFuture = resultFuture.map { Self.addCloseButton($0, user) }
        }
        
        return resultFuture.flatMapEach(on: app.eventLoopGroup.next()) { Self.formatMessage($0, platform: platform, context: context) }
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
    
    static private func addCloseButton(_ messages: [SendMessage], _ user: User) -> [SendMessage] {
        if !user.history.isEmpty, let lastMessage = messages.last {
            lastMessage.keyboard.buttons.safeAppend([ try! .init(
                text: user.history.last?.nodeId == user.nodeId ? "❌ Отменить выбор" : "👈 Назад",
                action: .callback, eventPayload: .back
            ) ])
        }
        return messages
    }
    
    static private func formatMessage(_ message: SendMessage, platform: AnyPlatform? = nil, context: PhotoBotContextProtocol) -> Future<SendMessage> {
        if let text = message.text, message.formatText {
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
        case orderAgreement
        case editNodeText
        case orderReplacement
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
        if container.allKeys.contains(.orderReplacement), try container.decodeNil(forKey: .orderReplacement) == false {
            self = .orderReplacement
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
        if container.allKeys.contains(.editNodeText), try container.decodeNil(forKey: .editNodeText) == false {
            self = .editNodeText
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
        if container.allKeys.contains(.orderAgreement), try container.decodeNil(forKey: .orderAgreement) == false {
            self = .orderAgreement
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
        case .orderAgreement:
            try container.encode(true, forKey: .orderAgreement)
        case .editNodeText:
            try container.encode(true, forKey: .editNodeText)
        case .orderReplacement:
            try container.encode(true, forKey: .orderReplacement)
        }
    }

}

extension SendMessageGroup: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = SendMessage

    public init(arrayLiteral elements: SendMessage...) {
        self = .array(elements)
    }
}
