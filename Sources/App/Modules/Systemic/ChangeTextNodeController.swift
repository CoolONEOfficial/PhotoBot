//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class ChangeTextNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            systemic: true,
            name: "Change static node text node",
            messagesGroup: [ .init(text: "Пришли мне новый текст") ],
            entryPoint: .messageEdit,
            action: .init(.messageEdit, success: .pop),
            app: app
        )
    }
    
    func handleAction(_ action: NodeAction, _ message: Message, _ text: String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? {
        guard case .messageEdit = action.type else { return nil }
        
        let (app, user) = (context.app, context.user)
        
        return Node.find(.id(user.history.last!.nodeId), app: app).throwingFlatMap { node in
            
            guard let nodePayload = user.nodePayload,
                  case let .editText(messageId) = nodePayload else {
                throw HandleActionError.nodePayloadInvalid
            }

            node.messagesGroup?.updateText(at: messageId, text: text)
            
            return try node.save(app: app).map { _ in .success }
        }
    }
    
    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<[Message]>? {
        guard case let .editText(messageId) = eventPayload else { return nil }
        let (app, user) = (context.app, context.user)
        
        replyText = "Move"
        return Node.find(.entryPoint(.messageEdit), app: app).throwingFlatMap { node in
            try user.push(node, payload: .editText(messageId: messageId), to: event, context: context)
        }
    }
}

extension SendMessageGroup {
    mutating func updateText(at index: Int, text: String) {
        guard case let .array(arr) = self else { return }
        arr[index].text = text
        self = .array(arr)
    }
}
