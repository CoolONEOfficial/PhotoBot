//
//  PhotoBot.swift
//  
//
//  Created by Nickolay Truhin on 07.01.2021.
//

import Foundation
import Botter
import Vapor
import Fluent
import Vkontakter
import AnyCodable

protocol OptionalProtocol {
    var myWrappedType: Any.Type { get }
    var myWrapped: Any? { get }
}

extension Optional: OptionalProtocol {
    var myWrappedType: Any.Type {
        Wrapped.self
    }
    
    var myWrapped: Any? {
        wrapped
    }
}

extension Array where Element == Buildable.DictEntry {
    var nextEntry: Element? {
        for entry in self {
            if Optional.isNil(entry.value) {
               return entry
            } else if let childDict = entry.value as? [Buildable.DictEntry] {
                if let nextChildEntry = childDict.nextEntry {
                    return nextChildEntry
                }
            }
        }
        return nil
    }
}

extension Buildable {
    typealias DictEntry = (key: String, value: Any)
    
    var dict: [DictEntry] {
        let dict: [DictEntry] = Mirror(reflecting: self).children.compactMap { child in
            if let label = child.label {
                return (key: label, value: child.value)
            }
            return nil
        }
        
        return dict.reduce([]) { arr, entry in
            var arr = arr

            if let child = entry.value as? OptionalProtocol,
               let childType = child.myWrappedType as? Buildable.Type {
                if let childWrappedInstance = child.myWrapped,
                    let childInstance = childWrappedInstance as? Buildable {
                    arr.append((key: entry.key, value: childInstance.dict))
                } else {
                    arr.append((key: entry.key, value: childType.init().dict))
                }
            } else {
                arr.append(entry)
            }
            
            return arr
        }
    }
}

extension Optional {
    static func isNil(_ object: Wrapped) -> Bool {
        switch object as Any {
        case Optional<Any>.none:
            return true
        default:
            return false
        }
    }
}

class PhotoBot {
    public let dispatcher: Botter.Dispatcher
    public let bot: Botter.Bot
    public let updater: Botter.Updater
    public let app: Application
    
    public init(settings: Botter.Bot.Settings, app: Application) throws {
        self.bot = try .init(settings: settings)
        self.dispatcher = .init(bot: bot)
        self.updater = .init(bot: bot, dispatcher: dispatcher)
        self.app = app
        
        //dispatcher.add(handler: Botter.CommandHandler(commands: [ "start" ], callback: handleStart))
        
        dispatcher.add(handler: Botter.MessageHandler(filters: .text, callback: handleText))
        
        dispatcher.add(handler: Botter.MessageEventHandler(callback: handleEvent))
    }
    
//    func handleStart(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
//        guard case let .message(message) = update.content, let command = message.command else { return }
//
//
//    }
    
    func handleError(err: Error) {
        fatalError("Error: \(err.localizedDescription)")
    }
    
    func handleEvent(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .event(event) = update.content else { return }
        
        let userFuture = User.findOrCreate(event, on: app.db, app: app)
        userFuture.whenFailure(handleError)
        userFuture.whenSuccess { user in
        
            let replyText: String
            
            if let eventPayload: EventPayload = try? event.decodeData() {
                switch eventPayload {
                case let .editText(messageId):
                    Node.find(.messageEdit, on: self.app.db).flatMap { node -> Future<[Botter.Message]> in
                        try! user.moveToNode(node, payload: .editText(messageId: messageId), to: event, with: self.bot, on: self.app.db, app: self.app)
                    }
                    replyText = "Move"
                case let .createNode(type):
                    Node.find(.createNode, on: self.app.db).flatMap { node -> Future<[Botter.Message]> in
                        try! user.moveToNode(node, payload: .build(type: type), to: event, with: self.bot, on: self.app.db, app: self.app)
                    }
                    replyText = "Move"
                }
            } else if let navPayload: NavigationPayload = try? event.decodeData() {
                switch navPayload {
                case .back:
                    try! user.pop(to: event, with: self.bot, on: self.app.db, app: self.app)
                    replyText = "Pop"
                case let .toNode(id):
                    try! user.moveToNode(id, to: event, with: self.bot, on: self.app.db, app: self.app)
                    replyText = "Move"
                }
            } else {
                replyText = "Not handled"
            }
            
            try! event.reply(from: self.bot, params: .init(type: .notification(text: replyText)), app: self.app)
        }
    }
    
    static func dropSome(_ val: Any) -> Any? { Mirror(reflecting: val).descendant("Some") }
    
    func handleText(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content, let text = message.text else { return }
        
        let userFuture = User.findOrCreate(message, on: app.db, app: app)
        userFuture.whenFailure(handleError)
        userFuture.whenSuccess { user in
            if let nodeId = user.nodeId {
                NodeModel.find(nodeId, on: self.app.db)
                    .unwrap(or: PhotoBotError.node_by_id_not_found)
                    .whenSuccess { node in
                        if let action = node.action {
                            self.handleAction(action, user, message, context)?.flatMap { result -> Future<[Botter.Message]?> in
                                var future: Future<[Botter.Message]>?
                                if result {
                                    guard let successNodeId = action.action else { return self.app.eventLoopGroup.future(nil) }
                                    switch successNodeId {
                                    case let .moveToNode(nodeId):
                                        future = user.moveToNode(nodeId, to: message, with: self.bot, on: self.app.db, app: self.app)
                                        
                                    case .pop:
                                        future = user.pop(to: message, with: self.bot, on: self.app.db, app: self.app)

                                    case .moveToBuilder(let builderType):
                                        future = self.moveToBuilder(builderType, user: user, nodeId: nodeId, message: message, text: text)
                                    }
                                } else {
                                    guard let failureMessage = action.failureMessage else { return self.app.eventLoopGroup.future(nil) }
                                    future = try! message.reply(from: self.bot, params: .init(text: failureMessage), app: self.app)?.map { [$0] }
                                }
                                return future?.map { Optional($0) } ?? self.app.eventLoopGroup.future(nil)
                            }
                        } else {
                            try! message.reply(from: self.bot, params: .init(text: "That node not handles text, use buttons please."), app: self.app)
                        }
                    }
            } else {
                Node.find(.welcome_guest, on: self.app.db).flatMap { node in
                    try! user.moveToNode(node, to: message, with: self.bot, on: self.app.db, app: self.app)
                }
            }
        }
    }
    
    enum UpdateNextValueResult {
        case success([String: AnyCodable])
        case checkFailed
        case notFound
    }
    
    func updatingNextValue(_ dict: [Buildable.DictEntry], _ payloadObject: [String: AnyCodable], _ text: String) -> UpdateNextValueResult {
        var payloadObject = payloadObject
        for entry in dict {
            if Optional.isNil(entry.value),
               let fieldType = type(of: entry.value) as? BuildableField.Type {
                if fieldType.check(text) {
                    payloadObject[entry.key] = fieldType.value(text)
                    return .success(payloadObject)
                } else {
                    return .checkFailed
                }
            } else if let childDict = entry.value as? [Buildable.DictEntry] {
                if payloadObject[entry.key] == nil {
                    payloadObject[entry.key] = [:]
                }
                
                switch updatingNextValue(childDict, payloadObject[entry.key]!.value as! [String: AnyCodable], text) {
                case let .success(childPayloadObject):
                    payloadObject[entry.key] = .init(childPayloadObject)
                    return .success(payloadObject)

                case .checkFailed:
                    return .checkFailed

                case .notFound:
                    break
                }
            }
        }
        return .notFound
    }
    
    func moveToBuilder(_ builderType: BuildableType, user: User, nodeId: UUID, message: Botter.Message, text: String) -> Future<[Botter.Message]>? {
        var payloadObject: [String: AnyCodable]
        
        if case let .build(payloadType, actualPayloadObject) = user.nodePayload, builderType == payloadType {
            payloadObject = actualPayloadObject.wrapped
            
            let buildableInstance = try! builderType.type.init(from: payloadObject)
            
            switch updatingNextValue(buildableInstance.dict, payloadObject, text) {
            case let .success(updatedPayloadObject):
                payloadObject = updatedPayloadObject
                
            case .notFound:
                let future: Future<Void>?
                if let model = try? Node(from: NodeModel(from: NodeBuildable(from: payloadObject))).toModel {
                    future = model.save(on: self.app.db)
                } else {
                    future = try? message.reply(from: self.bot, params: .init(text: "Failed to crete model"), app: self.app)?.map { _ in () }
                }
                return future.flatMap { _ in user.pop(to: message, with: self.bot, on: self.app.db, app: self.app)
                    { $0.nodeId != nodeId }! }
                
            case .checkFailed:
                return try? message.reply(from: self.bot, params: .init(text: "Incorrect format, try again"), app: self.app)?.map { [$0] }
            }
        } else {
            payloadObject = [:]
        }
        
        return user.moveToNode(nodeId, payload: .build(type: builderType, object: payloadObject), to: message, with: self.bot, on: self.app.db, app: self.app)
    }

    func handleAction(_ action: NodeAction, _ user: User, _ message: Botter.Message, _ context: Botter.BotContext?) -> Future<Bool>? {
        switch action.type {
        case .messageEdit:
            guard let text = message.text else { return app.eventLoopGroup.future(false) }
            return Node.find(user.history.last!.nodeId, on: app.db).flatMap { node in
                if let nodePayload = user.nodePayload,
                   case let .editText(messageId) = nodePayload {
                    return node.messagesGroup.array(app: self.app, user, nodePayload).flatMap { messages in
                        node.messagesGroup.updateText(at: messageId, text: text)
                        
                        if let nodeModel = node.toModel {
                            return nodeModel.save(on: self.app.db).flatMap {
                                user.pop(to: message, with: self.bot, on: self.app.db, app: self.app)!.map { _ in true }
                            }
                        } else {
                            return self.app.eventLoopGroup.future(false)
                        }
                    }
                } else {
                    return self.app.eventLoopGroup.future(false)
                }
            }

        case .setName:
            user.name = message.text
            if user.isValid {
                let userModel = user.toModel
                return userModel.save(on: app.db).flatMap {
                    try! message.reply(from: self.bot, params: .init(text: "Good, \(user.name!)"), app: self.app)!.map { _ in true }
                }
            } else {
                return app.eventLoopGroup.future(false)
            }

        case .createNode:
            return app.eventLoopGroup.future(true)
            
        case .buildType:
            return app.eventLoopGroup.future(true)
        }
    }
}

extension Botter.Button {
    init(text: String, action: NodeAction, color: Vkontakter.Button.Color? = nil, payload: String? = nil) throws {
        try self.init(text: text, action: .callback, color: color, data: action)
    }
}

enum PhotoBotError: Error {
    case node_by_entry_point_not_found
    case node_by_action_not_found
    case node_by_id_not_found
}

func strType(of value: Any) -> String {
    String(describing: type(of: value))
}

protocol BuildableField {
    static func check(_ str: String) -> Bool
    static func value(_ str: String) -> AnyCodable
}

extension String: BuildableField {
    static func value(_ str: String) -> AnyCodable { .init(str) }
    
    static func check(_ str: String) -> Bool { !str.isEmpty }
}

extension Bool: BuildableField {
    static func value(_ str: String) -> AnyCodable { .init(str == "+") }
    
    static func check(_ str: String) -> Bool { str == "+" || str == "-" }
}

extension Optional: BuildableField where Wrapped: BuildableField {
    static func check(_ str: String) -> Bool { Wrapped.check(str) }
    
    static func value(_ str: String) -> AnyCodable { Wrapped.value(str) }
}
