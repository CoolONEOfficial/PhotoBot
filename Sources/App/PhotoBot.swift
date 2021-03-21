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
import DateHelper

enum PhotoBotError: Error {
    case nodeByEntryPointNotFound(EntryPoint)
    case nodeByActionNotFound
    case nodeByIdNotFound
    case destinationNotFound
}

public enum HandleActionError: Error, LocalizedError {
    case textNotFound
    case textIncorrect
    case nodePayloadInvalid
    case eventPayloadInvalid
    case noAttachments
    case promoCondition
    case dateNotHandled
    case promoNotFound
    case actionNotHandled
    
    public var errorDescription: String? {
        switch self {
        case .promoCondition:
            return "К сожалению в Вашем заказе не выполняются условия акции."
            
        case .dateNotHandled:
            return "Дата или время не было распознано."
            
        case .promoNotFound:
            return "По данному промокоду не найдено акций."
            
        default:
            return nil
        }
    }
}

enum HandleEventError: Error {
    case eventNotFound
}

class PhotoBot {
    public let dispatcher: Botter.Dispatcher
    public let bot: Botter.Bot
    public let updater: Botter.Updater
    public let app: Application
    
    public let controllers: [NodeController]
    
    public init(settings: Botter.Bot.Settings, app: Application, controllers: [NodeController]) throws {
        self.bot = try .init(settings: settings)
        self.dispatcher = .init(bot: bot, app: app)
        self.updater = .init(bot: bot, dispatcher: dispatcher)
        self.app = app
        self.controllers = controllers

        dispatcher.add(handler: Botter.MessageHandler(filters: .text, callback: handleText))
        dispatcher.add(handler: Botter.MessageEventHandler(callback: handleEvent))
    }
    
    func handleError<T: Botter.Replyable & PlatformObject>(_ platformReplyable: T, err: Error, context: BotContextProtocol) {
        try? platformReplyable.replyMessage(.init(text: "Error: \(err)"), context: context)
        #if DEBUG
        print("Error: \(err)")
        #endif
    }

    func handleEventPayload(_ event: Botter.MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> Future<[Botter.Message]> {
        let user = context.user

        switch eventPayload {
        case .back:
            replyText = "Pop"
            return try user.pop(to: event, context: context)
            
        case let .push(target, nodePayload, saveMoveToHistory):
            replyText = "Move"
            return user.push(target, payload: nodePayload, to: event, saveMove: saveMoveToHistory, context: context)
            
        
        case .nextPage, .previousPage:
            var pageIndex: Int
            if case let .page(index) = context.user.nodePayload {
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

            return context.user.push(.id(context.user.nodeId!), payload: .page(at: pageIndex), to: event, saveMove: false, context: context)
            
        default: break
        }
        
        for controller in controllers {
            if let payload = try controller.handleEventPayload(event, eventPayload, &replyText, context: context) {
                return payload
            }
        }
        
        throw HandleEventError.eventNotFound
    }
    
    func handleEvent(_ update: Botter.Update, _ context: BotContextProtocol) throws {
        guard case let .event(event) = update.content else { return }
        
        let userFuture = try User.findOrCreate(from: event, context: context).throwingFlatMap { [self] user -> Future<[Botter.Message]> in
            
            let context = PhotoBotContext(app: app, bot: bot, user: user, platform: event.platform.any, controllers: controllers)
            
            var replyText: String = "Not handled"
            var nextFuture: Future<[Botter.Message]?>? = nil
            
            let eventData = event.data.value as? Data
            let eventStr = String(data: eventData ?? .init(), encoding: .utf8)
            
            if eventStr == "nope" {
                nextFuture = nil
            } else if let eventStr = eventStr,
                      let eventPayloadId = UUID(uuidString: eventStr) {
                nextFuture = EventPayloadModel.find(eventPayloadId, on: app.db)
                    .optionalFlatMapThrowing { model in try EventPayload(from: model.instance) }
                    .optionalThrowingFlatMap { eventPayload in try handleEventPayload(event, eventPayload, &replyText, context: context) }
            } else if let eventPayload: EventPayload = try? event.decodeData() {
                nextFuture = try handleEventPayload(event, eventPayload, &replyText, context: context).map { Optional($0) }
            }
            
            var futureArr: [EventLoopFuture<[Botter.Message]>] = update.platform.same(.vk) ? [] : [
                try event.reply(.init(type: .notification(text: replyText)), context: context).map { _ in [] }
            ]
            
            if let nextFuture = nextFuture {
                futureArr.append(nextFuture.unwrap(orReplace: []))
            }
            
            return futureArr.flatten(on: app.eventLoopGroup.next()).map { $0.last ?? [] }
        }
        userFuture.whenFailure { [weak self] in self?.handleError(event, err: $0, context: context) }
    }

    func handleText(_ update: Botter.Update, _ context: BotContextProtocol) throws {
        guard case let .message(message) = update.content else { return }
        
        let userFuture = try User.findOrCreate(from: message, context: context)
            .throwingFlatMap { [self] user -> Future<[Botter.Message]?> in
                let context = PhotoBotContext(app: app, bot: bot, user: user, platform: update.platform.any, controllers: controllers)
                
                if let nodeId = user.nodeId {
                    return NodeModel.find(nodeId, on: self.app.db)
                        .unwrap(or: PhotoBotError.nodeByIdNotFound)
                        .throwingFlatMap { [self] node -> Future<[Botter.Message]?> in
                            let nextFuture: Future<[Botter.Message]?>?
                            
                            if let action = node.action {
                                nextFuture = try handleAction(action, message, context: context).throwingFlatMap { result -> Future<[Botter.Message]?> in
                                    switch result {
                                    case .success:
                                        var future: Future<[Botter.Message]>?
                                    
                                        guard let successNodeId = action.action else { return self.app.eventLoopGroup.future(nil) }
                                        switch successNodeId {
                                        case let .push(target):
                                            future = user.push(target, to: message, context: context)
                                            
                                        case .pop:
                                            future = try user.pop(to: message, context: context)
                                        }
                                        
                                        return future?.map { Optional($0) } ?? (self.app.eventLoopGroup.future(nil))
                                        
                                    case let .failure(error):
                                        return try message.reply(.init(text: error.errorDescription ?? "Некорректное сообщение, попробуй еще раз но с другим текстом."), context: context).map(\.first).optionalThrowingFlatMap { sentMessage in
                                            try user.pushToActualNode(to: message, context: context).map { $0 + [sentMessage] }
                                        }
                                    }
                                }
                            } else {
                                nextFuture = try message.reply(.init(text: "В этом месте не принимается текст. Попробуй нажать на подходящую кнопку."), context: context).map(\.first).optionalThrowingFlatMap { message in
                                    try user.pushToActualNode(to: message, context: context).map { $0 + [message] }
                                }
                            }
                            
                            return nextFuture ?? self.app.eventLoopGroup.future(nil)
                        }
                } else {
                    return Node.find(.entryPoint(.welcomeGuest), app: self.app).throwingFlatMap { node in
                        try user.push(node, to: message, context: context).map { Optional($0) }
                    }
                }
            }
        userFuture.whenFailure { [weak self] in self?.handleError(message, err: $0, context: context) }
    }

    func handleAction(_ action: NodeAction, _ message: Botter.Message, context: PhotoBotContextProtocol) throws -> Future<Result<Void, HandleActionError>> {
        guard let text = message.text else { return app.eventLoopGroup.future(error: HandleActionError.textNotFound) }
        
        for controller in controllers {
            if let result = try controller.handleAction(action, message, text, context: context) {
                return result
            }
        }
        
        throw HandleActionError.actionNotHandled
    }

}
