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

protocol ArrayProtocol {
    static var elementType: Any.Type { get }
    var elements: [Any] { get }
}

extension Array: ArrayProtocol {
    static var elementType: Any.Type { Element.self }
    var elements: [Any] { self }
}

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

extension Array where Element == DictEntry {
    var nextEntry: Element? {
        for entry in self {
            if Optional.isNil(entry.value) {
               return entry
            } else if let childDict = entry.value as? [DictEntry] {
                if let nextChildEntry = childDict.nextEntry {
                    return nextChildEntry
                }
            } else if let childArrDict = entry.value as? [[DictEntry]] {
                for childDict in childArrDict {
                    if let nextChildEntry = childDict.nextEntry {
                        return nextChildEntry
                    }
                }
            }
        }
        return nil
    }
}

struct DictEntry {
    let key: String
    let value: Any
    
    enum DictEntryType {
        case array
    }
    
    var type: DictEntryType?
}

extension Buildable {

    var dict: [DictEntry] {
        let dict: [DictEntry] = Mirror(reflecting: self).children.compactMap { child in
            if let label = child.label {
                return .init(key: label, value: child.value)
            }
            return nil
        }
        
        let res: [DictEntry] = dict.reduce([]) { arr, entry in
            var arr = arr

            switch entry.value {
            case let child as OptionalProtocol:
                
                var shouldFallthrough: Bool = false
                
                switch child.myWrappedType {
                case let childType as Buildable.Type:
                    let val: Any
                    if let childWrappedInstance = child.myWrapped,
                        let childInstance = childWrappedInstance as? Buildable {
                        val = childInstance.dict
                    } else {
                        val = childType.init().dict
                    }
                    arr.append(.init(key: entry.key, value: val))
                    
                case let childType as ArrayProtocol.Type where childType.elementType is Buildable.Type:
                    let _entry: DictEntry
                    if let childWrappedInstance = child.myWrapped,
                       let childInstance = childWrappedInstance as? [Buildable] {
                        _entry = .init(key: entry.key, value: childInstance.map(\.dict), type: .array)
                    } else {
                        _entry = .init(key: entry.key, value: (childType.elementType as! Buildable.Type).init().dict, type: .array)
                    }
                    arr.append(_entry)
                    
                default:
                    shouldFallthrough = true
                }
                
                if shouldFallthrough {
                    fallthrough
                }
                
            default:
                arr.append(entry)
            }
            
            return arr
        }
        
        return res
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
    
    func handleError<T: Botter.Replyable & PlatformObject>(_ platformReplyable: T, err: Error) {
        try? platformReplyable.replyMessage(from: bot, params: .init(text: "Error: \(err)"), app: app)
        #if DEBUG
        print("Error: \(err)")
        #endif
    }
    
    func handleEvent(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .event(event) = update.content else { return }
        
        let userFuture = User.findOrCreate(from: event, on: app.db, bot: bot, app: app).throwingFlatMap { user -> Future<[Botter.Message]> in
            
            var replyText: String = "Not handled"
            var nextFuture: Future<[Botter.Message]>? = nil
            
            if let eventPayload: EventPayload = try? event.decodeData() {
                switch eventPayload {
                case let .editText(messageId):
                    nextFuture = Node.find(.action(.messageEdit), on: self.app.db).throwingFlatMap { node in
                        try user.push(node, payload: .editText(messageId: messageId), to: event, with: self.bot, app: self.app)
                    }
                    replyText = "Move"

                case let .createNode(type):
                    nextFuture = Node.find(.action(.createNode), on: self.app.db).throwingFlatMap { node in
                        try user.push(node, payload: .build(type: type), to: event, with: self.bot, app: self.app)
                    }
                    replyText = "Move"

                case let .selectStylist(stylistId):
                    nextFuture = Node.find(.entryPoint(.orderBuilder), on: self.app.db).throwingFlatMap { node in
                        try user.push(node, payload: .orderBuilder(.init(with: user.history.last?.nodePayload, stylistId: stylistId)), to: event, with: self.bot, app: self.app, saveMove: false)
                    }
                    replyText = "Selected"
                    
                case let .selectMakeuper(makeuperId):
                    nextFuture = Node.find(.entryPoint(.orderBuilder), on: self.app.db).throwingFlatMap { node in
                        try user.push(node, payload: .orderBuilder(.init(with: user.history.last?.nodePayload, makeuperId: makeuperId)), to: event, with: self.bot, app: self.app, saveMove: false)
                    }
                    replyText = "Selected"
                    
                case let .selectStudio(studioId):
                    nextFuture = Node.find(.entryPoint(.orderBuilder), on: self.app.db).throwingFlatMap { node in
                        try user.push(node, payload: .orderBuilder(.init(with: user.history.last?.nodePayload, studioId: studioId)), to: event, with: self.bot, app: self.app, saveMove: false)
                    }
                    replyText = "Selected"

                case .back:
                    nextFuture = user.pop(to: event, with: self.bot, app: self.app)
                    replyText = "Pop"

                case let .push(target, saveMoveToHistory):
                    nextFuture = user.push(target, to: event, with: self.bot, app: self.app, saveMove: saveMoveToHistory)
                    replyText = "Move"
                
                case .toCheckout:
                    //guard case let .page(index) = user.nodePayload else { break }
                    nextFuture = user.push(.entryPoint(.orderCheckout), to: event, with: self.bot, app: self.app)
                    replyText = "Move"
                    
                case .createOrder:
                    nextFuture = user.push(.entryPoint(.orderFinish), to: event, with: self.bot, app: self.app)
                    replyText = "Move"

                case .nextPage, .previousPage:
                    var pageIndex: Int
                    if case let .page(index) = user.nodePayload {
                        pageIndex = index
                    } else {
                        pageIndex = 0
                    }
                    
                    if case .nextPage = eventPayload {
                        replyText = "👉 Следующая"
                        pageIndex += 1
                    } else {
                        pageIndex -= 1
                        replyText = "👈 Предыдущая"
                    }

                    nextFuture = user.push(.id(user.nodeId!), payload: .page(at: pageIndex), to: event, with: self.bot, app: self.app, saveMove: false)
                }
            }
            
            var futureArr: [EventLoopFuture<[Botter.Message]>] = [
                try event.reply(from: self.bot, params: .init(type: .notification(text: replyText)), app: self.app).map { _ in [] }
            ]
            
            if let nextFuture = nextFuture {
                futureArr.append(nextFuture)
            }
            
            return futureArr.flatten(on: self.app.eventLoopGroup.next()).map { $0.last ?? [] }
        }
        userFuture.whenFailure { [weak self] in self?.handleError(event, err: $0) }
    }

    func handleText(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content, let text = message.text else { return }
        
        let userFuture = User.findOrCreate(from: message, on: app.db, bot: bot, app: app)
            .throwingFlatMap { user -> Future<[Botter.Message]?> in
                if let nodeId = user.nodeId {
                    return NodeModel.find(nodeId, on: self.app.db)
                        .unwrap(or: PhotoBotError.nodeByIdNotFound)
                        .throwingFlatMap { node -> Future<[Botter.Message]?> in
                            let nextFuture: Future<[Botter.Message]?>?
                            
                            if let action = node.action {
                                nextFuture = try self.handleAction(action, user, message, context).flatMap { result -> Future<[Botter.Message]?> in
                                    var future: Future<[Botter.Message]>?
                                
                                    guard let successNodeId = action.action else { return self.app.eventLoopGroup.future(nil) }
                                    switch successNodeId {
                                    case let .push(target):
                                        future = user.push(target, to: message, with: self.bot, app: self.app)
                                        
                                    case .pop:
                                        future = user.pop(to: message, with: self.bot, app: self.app)

                                    case .moveToBuilder(let builderType):
                                        future = self.moveToBuilder(builderType, user: user, nodeId: nodeId, message: message, text: text)
                                    }
                                    
                                    return future?.map { Optional($0) } ?? (self.app.eventLoopGroup.future(nil))
                                }
                            } else {
                                nextFuture = try message.reply(from: self.bot, params: .init(text: "В этом месте не принимается текст. Попробуй нажать на подходящую кнопку."), app: self.app).map { [$0] }
                            }
                            
                            return nextFuture ?? self.app.eventLoopGroup.future(nil)
                        }
                } else {
                    return Node.find(.entryPoint(.welcomeGuest), on: self.app.db).throwingFlatMap { node in
                        try user.push(node, to: message, with: self.bot, app: self.app).map { Optional($0) }
                    }
                }
            }
        userFuture.whenFailure { [weak self] in self?.handleError(message, err: $0) }
    }
    
    enum UpdateNextValueResult {
        case success([String: AnyCodable])
        case checkFailed
        case notFound
    }
    
    func checkEntry(_ entry: DictEntry, _ payloadObject: [String: AnyCodable]?, _ text: String) -> UpdateNextValueResult {
        var payloadObject = payloadObject ?? [:]
        if Optional.isNil(entry.value),
           let fieldType = type(of: entry.value) as? BuildableField.Type {
            if fieldType.check(text) {
                payloadObject[entry.key] = fieldType.value(text)
                return .success(payloadObject)
            } else {
                return .checkFailed
            }
        } else if let childDict = entry.value as? [DictEntry] {
            if entry.type == .array {
                for entry in childDict {
                    switch checkEntry(entry, payloadObject[entry.key]?.value as? [String: AnyCodable], text) {
                    case let .success(obj):
                        payloadObject[entry.key] = .init(obj)
                        return .success(payloadObject)
                    case .checkFailed:
                        return .checkFailed
                    case .notFound:
                        break
                    }
                }
            } else {
                switch updatingNextValue(childDict, payloadObject[entry.key]?.value as? [String: AnyCodable], text) {
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
    
    func updatingNextValue(_ dict: [DictEntry], _ payloadObject: [String: AnyCodable]?, _ text: String) -> UpdateNextValueResult {
        for entry in dict {
            let res = checkEntry(entry, payloadObject, text)
            guard case .notFound = res else {
                return res
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
                if let modelFuture = try? Node(from: NodeModel(from: NodeBuildable(from: payloadObject))).saveModel(app: app) {
                    future = modelFuture.map { _ in () }
                } else {
                    future = try? message.reply(from: self.bot, params: .init(text: "Failed to crete model"), app: self.app).map { _ in () }
                }
                return future.flatMap { _ in user.pop(to: message, with: self.bot, app: self.app)
                    { $0.nodeId != nodeId } }
                
            case .checkFailed:
                return try? message.reply(from: self.bot, params: .init(text: "Incorrect format, try again"), app: self.app).map { [$0] }
            }
            
        } else {
            payloadObject = [:]
        }
        
        return user.push(.id(nodeId), payload: .build(type: builderType, object: payloadObject), to: message, with: self.bot, app: self.app)
    }

    enum HandleActionError: Error {
        case textNotFound
        case textIncorrect
        case payloadInvalid
        case noAttachments
    }
    
    func handleAction(_ action: NodeAction, _ user: User, _ message: Botter.Message, _ context: Botter.BotContext?) throws -> Future<Void> {
        switch action.type {
        case .messageEdit:
            guard let text = message.text else { throw HandleActionError.textNotFound }
            return Node.find(user.history.last!.nodeId, on: app.db).throwingFlatMap { node in
                
                guard let nodePayload = user.nodePayload,
                      case let .editText(messageId) = nodePayload else {
                    throw HandleActionError.payloadInvalid
                }

                node.messagesGroup.updateText(at: messageId, text: text)
                
                return try node.saveModel(app: self.app).map { _ in () }
            }

        case .setName:
            user.name = message.text
            return try user.saveModel(app: app).throwingFlatMap { _ in
                try message.reply(from: self.bot, params: .init(text: "Good, \(user.name!)"), app: self.app).map { _ in () }
            }

        case .uploadPhoto:
            guard let text = message.text else { throw HandleActionError.textNotFound }
            
            var platforms: [Platform<AnyCodable, AnyCodable>] = []
            
            if bot.vk != nil {
                platforms.append(.vk(.init()))
            }
            
            if bot.tg != nil {
                platforms.append(.tg(.init()))
            }
            
            return try platforms.map { platform -> Future<PlatformFile.Entry> in
                let (userId, chatId): (Int64?, Int64?)
                switch platform {
                case .tg:
                    chatId = Application.tgBufferUserId
                    userId = nil
                case .vk:
                    userId = Application.vkBufferUserId
                    chatId = nil
                }
                return try self.bot.sendMessage(params: .init(
                    chatId: chatId,
                    userId: userId,
                    text: "Загружаю вот эту фото",
                    attachments: [
                        .init(type: .photo, content: .url(text))
                    ]
                ), platform: platform, app: app).throwingFlatMap { res -> Future<PlatformFile.Entry> in
                    guard let attachment = res.attachments.first else { throw HandleActionError.noAttachments }
                    var text = ""
                    switch platform {
                    case .tg:
                        text.append("tg id: ")
                        
                    case .vk:
                        text.append("vk id: ")
                    }
                    text.append(attachment.attachmentId)
                    return try message.reply(from: self.bot, params: .init(text: text), app: self.app)
                        .map { _ in platform.to(attachment.attachmentId) }
                }
            }.flatten(on: app.eventLoopGroup.next()).throwingFlatMap { platformEntries in
                try PlatformFile(platform: platformEntries, type: .photo).saveModelReturningId(app: self.app).throwingFlatMap { savedId in
                    try message.reply(from: self.bot, params: .init(text: "локальный id: \(savedId)"), app: self.app)
                        .map { _ in () }
                }
            }

        case .buildType, .createNode:
            return app.eventLoopGroup.future(())
        }
    }
    
    
}

extension Botter.Button {
    init(text: String, action: NodeAction, color: Vkontakter.Button.Color? = nil, payload: String? = nil) throws {
        try self.init(text: text, action: .callback, color: color, data: action)
    }
}

enum PhotoBotError: Error {
    case nodeByEntryPointNotFound
    case nodeByActionNotFound
    case nodeByIdNotFound
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
