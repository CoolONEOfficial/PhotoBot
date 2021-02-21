//
//  SendMessageGroup.swift
//  
//
//  Created by Nickolay Truhin on 01.02.2021.
//

import Foundation
import Botter
import Vapor

enum SendMessageGroupError: Error {
    case invalidPayload
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

enum MessageListType: String, Codable {
    case portfolio
    case stylists
}

enum SendMessageGroup {
    case array(_ elements: [SendMessage])
    case builder
    case list(_ content: MessageListType)
    
//    struct MessagesInfo {
//        var messages: [SendMessage] = []
//        var isStatic: Bool
//    }
    
    mutating func getSendMessages(in node: Node, app: Application, _ user: User, _ payload: NodePayload?) -> Future<[SendMessage]> {
        let result: Future<[SendMessage]>
        
        switch self {
        case var .array(arr):
            
            if !node.systemic, user.isValid {
                for (index, params) in arr.enumerated() {
                    params.keyboard.buttons.insert([
                        try! Button(
                            text: "Edit text",
                            action: .callback,
                            eventPayload: .editText(messageId: index)
                        )
//                        try! Button( TODO: node creation
//                            text: "Add node",
//                            action: .callback,
//                            eventPayload: .createNode(type: .node)
//                        )
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
            
            let messagesByPage = 5
            let startIndex = pageNumber * messagesByPage
            let endIndex = startIndex + messagesByPage
            
            switch type {
            case .portfolio:
                result = app.eventLoopGroup.future([])
                
            case .stylists:
                result = StylistModel.query(on: app.db).count().flatMap { count in
                    var buttons = [Button]()
                    if startIndex > 0, let prevButton = try? Button(text: "Предыдущая стр", action: .callback, data: NavigationPayload.previousPage) {
                        buttons.append(prevButton)
                    }
                    if endIndex < count, let nextButton = try? Button(text: "Следующая стр", action: .callback, data: NavigationPayload.nextPage) {
                        buttons.append(nextButton)
                    }
                    
                    return StylistModel.query(on: app.db).range(startIndex ..< endIndex).all().flatMap { stylists in
                        stylists.enumerated().map { (index, stylist) -> Future<SendMessage> in
                            stylist.$photos.get(on: app.db).flatMapThrowing { photos in
                                SendMessage(
                                    text: stylist.name,
                                    keyboard: Keyboard(buttons: index == messagesByPage - 1 ? [buttons] : []),
                                    attachments: try photos.compactMap { try $0.toMyType().fileInfo }
                                )
                            }
                        }.flatten(on: app.eventLoopGroup.next())
                    }
                }
            }
            
        case .builder:
            guard let payload = payload, case let .build(payloadTypeWrapper, payloadObject) = payload else {
                return app.eventLoopGroup.future(error: SendMessageGroupError.invalidPayload)
            }
            let buildableInstance = try! payloadTypeWrapper.type.init(from: payloadObject)
            
            let arr: [SendMessage]
            let statusStr = buildableInstance.statusStr()
            if let nextKey = buildableInstance.dict.nextEntry?.key {
                arr = [ .init(text: "Builder status" + statusStr), .init(text: "Send \(nextKey)") ]
            } else {
                arr = [ .init(text: "Builded obj" + statusStr) ]
            }
            
            result = app.eventLoopGroup.future(arr)
        }

        return result
            .map { Self.addNavigationButtons($0, user) }
            .map { Self.formatMessages($0, user) }
    }
    
    static private func addNavigationButtons(_ messages: [SendMessage], _ user: User) -> [SendMessage] {
        if !user.history.isEmpty, let lastMessage = messages.last {
            let actualLastButtons = lastMessage.keyboard.buttons.last ?? []
            let newLastButtons: [Button] = actualLastButtons + [ try! .init(text: "Pop", action: .callback, data: NavigationPayload.back) ]
            
            lastMessage.keyboard.buttons.indices.last.map {
                if newLastButtons.count < 2 {
                    lastMessage.keyboard.buttons[$0] = newLastButtons
                } else {
                    lastMessage.keyboard.buttons.append([ newLastButtons.last! ])
                }
            }
        }
        return messages
    }
    
    static private func formatMessages(_ messages: [SendMessage], _ user: User) -> [SendMessage] {
        for message in messages {
            if let text = message.text {
                message.text = MessageFormatter.shared.format(text, user: user)
            }
        }
        return messages
    }
    
    mutating func updateText(at index: Int, text: String) {
        guard case let .array(arr) = self else { return }
        arr[index].text = text
        self = .array(arr)
    }
}

extension Buildable {
    func statusStr(_ keyPrefix: String = "", _ entries: [DictEntry]? = nil) -> String {
        (entries ?? dict).map { entry in
            var value = entry.value
            
            if let valueOptional = value as? OptionalProtocol,
               let valueUnwrapped = valueOptional.myWrapped {
                value = valueUnwrapped
            }
            let statusVal: String
            switch value {
            case let subEntries as [[DictEntry]]:
                statusVal = "\n---" + subEntries.map { statusStr("\t" + keyPrefix + entry.key + " -> ", $0) }.joined(separator: "\n\n---\n\n") + "\n---"
            
            case let subEntries as [DictEntry]:
                statusVal = statusStr("\t" + keyPrefix + entry.key + " -> ", subEntries)

            case let strConv as CustomStringConvertible:
                statusVal = strConv.description

            default:
                statusVal = String(describing: value)
            }
            
            let typeStr: String
            if let optionalType = value as? OptionalProtocol {
                typeStr = ": \(optionalType.myWrappedType)"
            } else {
                typeStr = .init()
            }
            
            return "\n\t\(keyPrefix)\(entry.key)\(typeStr) = \(statusVal)"
        }.reduce("", +)
    }
}

extension SendMessageGroup: Codable {

    enum CodingKeys: String, CodingKey {
        case builder
        case elements
        case listType
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if container.allKeys.contains(.elements), try container.decodeNil(forKey: .elements) == false {
            let elements = try container.decode([SendMessage].self, forKey: .elements)
            self = .array(elements)
            return
        }
        if container.allKeys.contains(.builder), try container.decodeNil(forKey: .builder) == false {
            self = .builder
            return
        }
        if container.allKeys.contains(.listType), try container.decodeNil(forKey: .listType) == false {
            let type = try container.decode(MessageListType.self, forKey: .listType)
            self = .list(type)
            return
        }
        throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown enum case"))
    }

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .array(elements):
            try container.encode(elements, forKey: .elements)
        case .builder:
            try container.encode("builder", forKey: .builder)
        case let .list(type):
            try container.encode(type, forKey: .listType)
        }
    }

}

extension SendMessageGroup: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = SendMessage

    init(arrayLiteral elements: SendMessage...) {
        self = .array(elements)
    }
}
