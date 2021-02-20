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
        guard let message = update.message,
              let photos = message.photo,
              let biggestPhoto = photos.sorted(by: { $0.fileSize ?? 0 < $1.fileSize ?? 0 }).first else {
            return
        }

//        let params = Bot.SendMessageParams(
//            chatId: .chat(message.chat.id),
//            text: "Thats photo",
//            replyMarkup: .inlineKeyboardMarkup(.init(inlineKeyboard: [ [ .init(text: "test", callbackData: "fix:dgdfgd") ] ]))
//        )
        
        try bot.sendMessage(params: .init(chatId: .chat(message.chat.id), text: biggestPhoto.fileId))
        
        //if let data = try? Data(contentsOf: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/1e/Caerte_van_Oostlant_4MB.jpg")!) {
        try bot.sendPhoto(params: .init(chatId: .chat(message.chat.id), photo: .fileId(biggestPhoto.fileId), caption: "Thats photo"))
        //}
        
        
    }
}
