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

        let test =  Button(action: .link(.init(payload: .init("{}"), label: "Test", link: "https://google.com")))
        
        let params = Vkontakter.Bot.SendMessageParams(
            randomId: .random(),
            peerId: wrapper.message.fromId!,
            message: "Starting.."
            //keyboard: .init(oneTime: false, buttons: [ [ test ] ], inline: true)
        )

//        let data: Data = try JSONEncoder().encode(params)
//        let data2 = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
//        let data3 = try JSONSerialization.data(withJSONObject: data2, options: .prettyPrinted)
//
//        let testStr = String(data: data3, encoding: .utf8)
        
        try bot.sendMessage(params: params)

        let jpgLink = "https://upload.wikimedia.org/wikipedia/commons/1/1e/Caerte_van_Oostlant_4MB.jpg"
        let txtLink = "https://www.w3.org/TR/PNG/iso_8859-1.txt"
        
        if let data = try? Data(contentsOf: URL(string: txtLink)!) {
            try! bot.upload(.init(data: data, filename: "test_file.txt"), as: .doc(peerId: wrapper.message.fromId!), for: .message).whenSuccess { res in
                guard let attachable = res.first?.attachable else { return }

                let att: Attachments = .init([ .doc(.init(id: attachable.mediaId, ownerId: attachable.ownerId)) ])

                try! self.bot.sendMessage(params: .init(userId: wrapper.message.fromId, randomId: .random(), attachment: att,
                                                        keyboard: .init(oneTime: false, buttons: [ [ test ] ], inline: true)))
            }
        }
    }
}
