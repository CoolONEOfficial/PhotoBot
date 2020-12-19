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

class TgEchoBot: TelegrammerMiddleware {
    public let dispatcher: Telegrammer.Dispatcher
    public let path: String
    public let bot: Telegrammer.Bot

    public init(path: String, settings: Telegrammer.Bot.Settings) throws {
        self.path = path
        self.bot = try Bot(settings: settings)
        self.dispatcher = Dispatcher(bot: bot)

        dispatcher.add(
            handler: MessageHandler(
                filters: .all,
                callback: echoResponse
            )
        )
    }

    func echoResponse(_ update: Telegrammer.Update, _ context: Telegrammer.BotContext?) throws {
        guard let message = update.message, let text = message.text else {
            return
        }

        let params = Bot.SendMessageParams(
            chatId: .chat(message.chat.id),
            text: text
        )

        try bot.sendMessage(params: params)
    }
}

//class VkEchoBot: VkontakterMiddleware {
//    public let dispatcher: Vkontakter.Dispatcher
//    public let path: String
//    public let bot: Vkontakter.Bot
//
//    public init(path: String, settings: Vkontakter.Bot.Settings) throws {
//        self.path = path
//        self.bot = try .init(settings: settings)
//        self.dispatcher = .init(bot: bot)
//
//        dispatcher.add(
//            handler: Vkontakter.MessageHandler(
//                filters: .text,
//                callback: echoResponse
//            )
//        )
//    }
//
//    func echoResponse(_ update: Vkontakter.Update, _ context: Vkontakter.BotContext?) throws {
//        guard case let .message(message) = update.object, let text = message.message.text else {
//            return
//        }
//
//        let params = Vkontakter.Bot.SendMessageParams(
//            randomId: .random(),
//            peerId: message.message.fromId!,
//            message: text
//        )
//
//        try bot.sendMessage(params: params)
//    }
//}

class EchoBot: BotterMiddleware {
    public let middlewares: [Middleware]
    public let dispatcher: Botter.Dispatcher
    public let bot: Botter.Bot

    public init(settings: Botter.Bot.Settings) throws {
        self.bot = try .init(settings: settings)
        self.dispatcher = .init(bot: bot)
        var middlewares = [Middleware]()
        if let vkDispatcher = dispatcher.vk, let vkBot = bot.vk {
            middlewares.append(VkontakterMiddlewareMock(vkDispatcher, vkBot, "vk"))
        }
        if let tgDispatcher = dispatcher.tg, let tgBot = bot.tg {
            middlewares.append(TelegrammerMiddlewareMock(tgDispatcher, tgBot, "tg"))
        }
        self.middlewares = middlewares

        dispatcher.add(
            handler: Botter.MessageHandler(
                filters: .all,
                callback: echoResponse
            )
        )
    }

    func echoResponse(_ update: Botter.Update, _ context: Botter.BotContext?) throws {
        guard case let .message(message) = update.content, let text = message.text else {
            return
        }

        let params = Botter.Bot.SendMessageParams(
            peerId: message.fromId!,
            message: text
        )

        try bot.sendMessage(params: params, platform: update.platform.void)!.whenComplete { res in
            switch res {
            case .success(_):
                debugPrint("success sent message")
            case let .failure(err):
                debugPrint("error while sent message \(err.localizedDescription)")
            }
        }
    }
}
