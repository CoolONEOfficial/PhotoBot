//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Vapor
import Botter

class UploadPhotoNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Upload photo node",
            messagesGroup: [
                .init(text: "Пришли мне прямую ссылку.")
            ],
            entryPoint: .uploadPhoto,
            action: .init(.uploadPhoto), app: app
        )
    }
    
    func handleAction(_ action: NodeAction, _ message: Message, _ text: String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? {
        guard case .uploadPhoto = action.type else { return nil }
        let (app, bot) = (context.app, context.bot)
        
        let availablePlatforms: [AnyPlatform] = .available(bot: bot)
        
        return try availablePlatforms.map { platform -> Future<PlatformFile.Entry> in
            let destination: SendDestination
            switch platform {
            case .tg:
                destination = .chatId(Application.tgBufferUserId)
            case .vk:
                destination = .userId(Application.vkBufferUserId)
            }
            return try bot.sendMessage(.init(
                destination: destination,
                text: "Загружаю вот эту фото",
                attachments: [
                    .init(type: .photo, content: .url(text))
                ]
            ), platform: platform, context: context).throwingFlatMap { res -> Future<PlatformFile.Entry> in
                guard let attachment = res.first?.attachments.first else { throw HandleActionError.noAttachments }
                var text = ""
                switch platform {
                case .tg:
                    text.append("tg id: ")
                    
                case .vk:
                    text.append("vk id: ")
                }
                text.append(attachment.attachmentId)
                return try message.reply(.init(text: text), context: context)
                    .map { _ in platform.convert(to: attachment.attachmentId) }
            }
        }.flatten(on: app.eventLoopGroup.next()).flatMap { platformEntries in
            PlatformFile.create(platformEntries: platformEntries, type: .photo, app: app).throwingFlatMap { try $0.saveReturningId(app: app) }.throwingFlatMap { savedId in
                try message.reply(.init(text: "локальный id: \(savedId)"), context: context)
                    
            }
        }.map { _ in .success }
    }
}
