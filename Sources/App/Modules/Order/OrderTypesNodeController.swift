//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderTypesNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Order types node",
            messagesGroup: .orderTypes,
            entryPoint: .orderTypes, app: app
        )
    }
    
    func getSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, group: SendMessageGroup) throws -> EventLoopFuture<[SendMessage]>? {
        guard case .orderTypes = group else { return nil }
        
        let (app, user) = (context.app, context.user)
        
        return PhotographerModel.query(on: app.db).first().optionalThrowingFlatMap { try $0.toTwin(app: app) }
            .flatMapThrowing { photographer in
            [
                .init(text: "Выберите тип фотосессии:", keyboard: [[
                    try .init(text: "❤️ Love story", action: .callback, eventPayload: .push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(with: nil, type: .loveStory, photographer: photographer, customer: user))))
                ], [
                    try .init(text: "💼 Контент сьемка", action: .callback, eventPayload: .push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(with: nil, type: .content, photographer: photographer, customer: user))))
                ], [
                    try .init(text: "👪 Семейная фотосессия", action: .callback, eventPayload: .push(.entryPoint(.orderBuilder), payload: .orderBuilder(.init(with: nil, type: .family, photographer: photographer, customer: user))))
                ]]),
            ]
        }
    }
}
