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
    
    
    func handleEvent(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .event(event) = update.content else { return }
        
        User.findOrCreate(event, on: app.db, app: app).whenSuccess { user in
        
            let replyText: String
            
            if let editPayload: EditPayload = try? event.decodeData() {
                switch editPayload.type {
                case .edit_text:
                    Node.find(.message_edit, on: self.app.db).flatMap { node -> Future<[Botter.Message]> in
                        try! user.moveToNode(node, payload: editPayload, to: event, with: self.bot, on: self.app.db, app: self.app)
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
    
    func handleText(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content else { return }
        
        User.findOrCreate(message, on: app.db, app: app).whenSuccess { user in
            if let nodeId = user.nodeId {
                NodeModel.find(nodeId, on: self.app.db)
                    .unwrap(or: PhotoBotError.node_by_id_not_found)
                    .whenSuccess { node in
                        if let action = node.action {
                            self.handleAction(action, user, message, context)?.flatMap { result -> Future<[Botter.Message]?> in
                                let future: Future<[Botter.Message]>?
                                if result {
                                    guard let successNodeId = action.action else { return self.app.eventLoopGroup.future(nil) }
                                    switch successNodeId {
                                    case let .moveToNode(nodeId):
                                        future = try! user.moveToNode(nodeId, nil, to: message, with: self.bot, on: self.app.db, app: self.app)
                                        
                                    case .pop:
                                        future = try! user.pop(to: message, with: self.bot, on: self.app.db, app: self.app)
                                    }
                                } else {
                                    guard let failureMessage = action.failureMessage else { return self.app.eventLoopGroup.future(nil) }
                                    future = try! message.reply(from: self.bot, params: .init(message: failureMessage), app: self.app)?.map { [$0] }
                                }
                                return future?.map { Optional($0) } ?? self.app.eventLoopGroup.future(nil)
                            }
                        } else {
                            try! message.reply(from: self.bot, params: .init(message: "That node not handles text, use buttons please."), app: self.app)
                        }
                    }
            } else {
                Node.find(.welcome_guest, on: self.app.db).flatMap { node in
                    try! user.moveToNode(node, nil, to: message, with: self.bot, on: self.app.db, app: self.app)
                }
            }
        }
    }

    func handleAction(_ action: ActionPayload, _ user: User, _ message: Botter.Message, _ context: Botter.BotContext?) -> Future<Bool>? {
        switch action.type {
        case .message_edit:
            Node.find(user.history.last!.nodeId, on: app.db).whenSuccess { node in
                if let editPayload: EditPayload = try! user.nodePayload?.decode() {
                    node.messages![editPayload.messageId].message = message.text
                    node.toModel?.save(on: self.app.db).flatMap {
                        try! user.pop(to: message, with: self.bot, on: self.app.db, app: self.app)!
                    }
                }
            }

        case .set_name:
            user.name = message.text
            if user.isValid {
                let userModel = user.toModel
                return userModel.save(on: app.db).flatMap {
                    try! message.reply(from: self.bot, params: .init(message: "Good, \(user.name!)"), app: self.app)!.map { _ in true }
                }
            } else {
                return app.eventLoopGroup.future(false)
            }
        }
        return nil
    }
}

extension Botter.Button {
    init(text: String, action: ActionPayload, color: Vkontakter.Button.Color? = nil, payload: String? = nil) throws {
        try self.init(text: text, action: .callback, color: color, data: action)
    }
}

enum PhotoBotError: Error {
    case node_by_entry_point_not_found
    case node_by_action_not_found
    case node_by_id_not_found
}
