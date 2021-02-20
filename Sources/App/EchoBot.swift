//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.11.2020.
//

import Foundation
import Telegrammer
import TelegrammerMiddleware
import Vkontakter
import VkontakterMiddleware
import Botter
import Vapor

class EchoBot {
    public let dispatcher: Botter.Dispatcher
    public let bot: Botter.Bot
    public let updater: Botter.Updater
    public let app: Application

    public init(settings: Botter.Bot.Settings, app: Application) throws {
        self.bot = try .init(settings: settings)
        self.dispatcher = .init(bot: bot)
        self.updater = .init(bot: bot, dispatcher: dispatcher)
        self.app = app

        dispatcher.add(handler: Botter.MessageHandler(filters: .all, callback: handleMessage))
        
//        dispatcher.add(
//            handler: Botter.MessageHandler(
//                filters: .command,
//                callback: handleCommand
//            )
//        )
//
//        dispatcher.add(
//            handler: Botter.MessageHandler(
//                filters: .photo,
//                callback: handlePhoto
//            )
//        )
//
//        dispatcher.add(
//            handler: Botter.MessageEventHandler(
//                callback: handleEvent
//            )
//        )
    }
    
    func handleMessage(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content else { return }
        
//        try bot.sendMessage(params: .init(peerId: message.fromId!, message: "Cool image", attachments: [ .init(type: .photo, content: .fileId(photo)) ]), platform: message.platform, eventLoop: app.eventLoopGroup.next())
        
        //try bot.sendMessage(params: .init(peerId: message.fromId!, message: "Starting send message"), platform: message.platform, eventLoop: app.eventLoopGroup.next())
        
//        let jpgLink = "https://upload.wikimedia.org/wikipedia/en/a/a9/Example.jpg"
//        let jpgData = try Data(contentsOf: URL(string: jpgLink)!)
//        let txtLink = "https://www.w3.org/TR/PNG/iso_8859-1.txt"
//        let txtData = try Data(contentsOf: URL(string: txtLink)!)

        let params: Botter.Bot.SendMessageParams = .init(to: message, text: "that is doc")

//        if let prevMessage = prevMessage {
//            try bot.editMessage(prevMessage, params: .init(message: "Other text"), app: app)
//        }
        
        try bot.sendMessage(params: params, platform: message.platform, app: app).flatMap { message in
            try! self.bot.editMessage(message, params: .init(message: "Other text"), app: self.app)!
        }
    }
    
    func handleEvent(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .event(event) = update.content else { return }
        
        try bot.sendMessageEventAnswer(params: .init(event: event, type: .notification(text: "BOMBOM")), platform: update.platform)
        
        let data: TestData = try! event.decodeData()
        
        debugPrint("event \(data) handled")
    }
    
    struct TestData: Codable {
        let text: String
    }

    func handleCommand(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content, let text = message.text, let context = context else { return }
        
        let textButton: Botter.Button = .init(text: "Test", action: .text)
        
        let params = Botter.Bot.SendMessageParams(
            chatId: message.chatId,
            userId: message.fromId,
            text: text,
            keyboard: .init([ [ textButton ] ]),
            attachments: nil
        )
        
        try bot.sendMessage(params: params, platform: update.platform, app: app).whenComplete { res in
            switch res {
            case .success(_):
                debugPrint("success sent message")
            case let .failure(err):
                debugPrint("error while sent message \(err.localizedDescription)")
            }
        }
    }
    
    func handlePhoto(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content, let att = message.attachments.first else { return }

        
        
//        let linkButton: Botter.Button = try .init(text: "Link", action: .link(.init(link: "https://google.gik-team.com/?q=\(text)")), payload: .init("{}"))
//        let callbackButton: Botter.Button = try .init(text: "Callback", action: .callback, data: TestData(text: "14342353"))
//
//        let params = Botter.Bot.SendMessageParams(
//            peerId: message.fromId!,
//            message: text,
//            keyboard: .init(
//                oneTime: false,
//                buttons: [ [ linkButton ], [ callbackButton ] ],
//                inline: true
//            )
//        )
//
//        try bot.sendMessage(params: params, platform: update.platform)!.whenComplete { res in
//            switch res {
//            case .success(_):
//                debugPrint("success sent message")
//            case let .failure(err):
//                debugPrint("error while sent message \(err.localizedDescription)")
//            }
//        }
    }
}
