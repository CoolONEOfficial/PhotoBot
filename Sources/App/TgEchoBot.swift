//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 06.01.2021.
//

import Foundation
import Telegrammer
import TelegrammerMiddleware
import Vkontakter
import VkontakterMiddleware
import Botter
import Vapor

class TgEchoBot {
    public let dispatcher: Telegrammer.Dispatcher
    public let bot: Telegrammer.Bot
    public let updater: Telegrammer.Updater

    public init(settings: Telegrammer.Bot.Settings) throws {
        self.bot = try .init(settings: settings)
        self.dispatcher = .init(bot: bot)
        self.updater = .init(bot: bot, dispatcher: dispatcher)
        
        dispatcher.add(
            handler: Telegrammer.MessageHandler(
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
            text: text,
            replyMarkup: .inlineKeyboardMarkup(.init(inlineKeyboard: [ [ .init(text: "test", callbackData: "fix:dgdfgd") ] ]))
        )
        
        try bot.sendMessage(params: .init(chatId: .chat(message.chat.id), text: "Starting..."))
        
        //if let data = try? Data(contentsOf: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/1e/Caerte_van_Oostlant_4MB.jpg")!) {
            try bot.sendPhoto(params: .init(chatId: .chat(message.chat.id), photo: .url("https://upload.wikimedia.org/wikipedia/en/a/a9/Example.jpg"), caption: "123123"))
        //}
        
        
    }
}
