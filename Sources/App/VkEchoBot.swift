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

class VkEchoBot {
    public let dispatcher: Vkontakter.Dispatcher
    public let bot: Vkontakter.Bot
    public let updater: Vkontakter.Updater

    public init(settings: Vkontakter.Bot.Settings) throws {
        self.bot = try .init(settings: settings)
        self.dispatcher = .init(bot: bot)
        self.updater = .init(bot: bot, dispatcher: dispatcher)

        dispatcher.add(
            handler: Vkontakter.MessageHandler(
                filters: .all,
                callback: echoResponse
            )
        )
    }

    func echoResponse(_ update: Vkontakter.Update, _ context: Vkontakter.BotContext?) throws {
        guard case let .messageWrapper(wrapper) = update.object, let text = wrapper.message.text else {
            return
        }
        
        var message: String = "Starting.."
        
        defer {
            let params = Vkontakter.Bot.SendMessageParams(
                randomId: .random(),
                peerId: wrapper.message.fromId!,
                message: message
            )
            
            try! bot.sendMessage(params: params)
        }
//        let jpgLink = "https://upload.wikimedia.org/wikipedia/ru/a/a9/Example.jpg"
//        let txtLink = "https://www.w3.org/TR/PNG/iso_8859-1.txt"
        
        guard let url = URL(string: text) else {
            message = "URL incorrect"
            return
        }
        
        guard let data = try? Data(contentsOf: url) else {
            message = "Cannot get data"
            return
        }

        func randomString(length: Int) -> String {
          let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
          return String((0..<length).map{ _ in letters.randomElement()! })
        }
        
        try! bot.upload(.init(data: data, filename: "\(randomString(length: 10)).jpg"), as: .photo, for: .message).whenSuccess { res in
            guard let attachable = res.first?.attachable else { return }

            let att: ArrayByComma<Vkontakter.Attachment> = [ .photo(.init(id: attachable.mediaId, ownerId: attachable.ownerId)) ]

            try! self.bot.sendMessage(params: .init(
                userId: wrapper.message.fromId,
                randomId: .random(),
                message: String(attachable.mediaId!),
                attachment: att
            ))
        }
        
    }
}
