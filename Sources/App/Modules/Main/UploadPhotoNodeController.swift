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
                .init(text: "Пришли мне ссылки на фото и/или приложи их.")
            ],
            entryPoint: .uploadPhoto,
            action: .init(.uploadPhoto), app: app
        )
    }
    
    func handleAction(_ action: NodeAction, _ message: Message, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? {
        guard case .uploadPhoto = action.type else { return nil }
        let (app, bot) = (context.app, context.bot)
        
        let availablePlatforms: [AnyPlatform] = .available(bot: bot)
        
        return try availablePlatforms.map { platform -> Future<[PlatformFile.Entry]> in
            let destination: SendDestination
            switch platform {
            case .tg:
                destination = .chatId(Application.tgBufferUserId)
            case .vk:
                destination = .userId(Application.vkBufferUserId)
            }
            
            var contentArray = [
                try message.attachments.compactMap { attachment in
                    try attachment.getUrl(context: context)?.optionalMap { url -> (FileInfo.Content, Attachment?) in
                        (.url(url), attachment)
                    }
                }.flatten(on: app.eventLoopGroup.next()).map { $0.compactMap { $0 } }
            ]
            if let text = message.text {
                contentArray.append(app.eventLoopGroup.future(text.extractUrls.map { (.url($0.absoluteString), nil) }))
            }
            
            return contentArray.flatten(on: app.eventLoopGroup.next()).map { $0.reduce([], +) }.throwingFlatMap { contentArray in
                try contentArray.map { (content, attachment) in
                    let attachmentFuture: Future<Attachment>
                    if let attachment = attachment, message.platform.same(platform) {
                        attachmentFuture = app.eventLoopGroup.future(attachment)
                    } else {
                        attachmentFuture = try bot.sendMessage(.init(
                            destination: destination,
                            text: "Загружаю вот эту фото",
                            attachments: [
                                .init(type: .photo, content: content)
                            ]
                        ), platform: platform, context: context)
                        .map(\.first?.attachments.first)
                        .unwrap(orError: HandleActionError.noAttachments)
                    }
                    return attachmentFuture.map { attachment in platform.convert(to: attachment.attachmentId) }
                }.flatten(on: app.eventLoopGroup.next())
            }
        }.flatten(on: app.eventLoopGroup.next())
        .map { $0.reduce([], +) }
        .flatMap { platformEntries in
            PlatformFile.create(platformEntries: platformEntries, type: .photo, app: app)
                .throwingFlatMap { try $0.saveReturningId(app: app) }
                .throwingFlatMap { savedId -> Future<[Message]> in
                var text = "локальный id: \(savedId)"
                text = platformEntries.map { $0.name + ": " + $0.description + "\n" }.joined() + text
                return try message.reply(.init(text: text), context: context)
            }
        }.map { _ in .success }
    }
}
