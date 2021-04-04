//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 27.03.2021.
//

import Foundation
import Botter
import Vapor

class OrderAgreementNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            systemic: true,
            name: "Order agreement node",
            messagesGroup: .orderAgreement,
            entryPoint: .orderAgreement,
            action: .init(.handleOrderAgreement, success: .pop),
            app: app
        )
    }
    
//    func handleAction(_ action: NodeAction, _ message: Message,, context: PhotoBotContextProtocol) throws -> EventLoopFuture<Result<Void, HandleActionError>>? {
//        guard case .handleOrderAgreement = action.type else { return nil }
//
//        let (app, user) = (context.app, context.user)
//
////        return Node.find(.id(user.history.last!.nodeId), app: app).throwingFlatMap { node in
////
////            guard let nodePayload = user.nodePayload,
////                  case let .editText(messageId) = nodePayload else {
////                throw HandleActionError.nodePayloadInvalid
////            }
////
////            node.messagesGroup?.updateText(at: messageId, text: text)
////
////            return try node.save(app: app).map { _ in .success }
////        }
//    }
    
//    func handleEventPayload(_ event: MessageEvent, _ eventPayload: EventPayload, _ replyText: inout String, context: PhotoBotContextProtocol) throws -> EventLoopFuture<[Message]>? {
//        guard case let .handleOrderAgreement(agreement) = eventPayload else { return nil }
//        let (app, user) = (context.app, context.user)
//        
//        replyText = "Move"
//        
//        if agreement {
//            
//        } else {
//            
//        }
//        
//
////        return Node.find(.entryPoint(.messageEdit), app: app).throwingFlatMap { node in
////            try user.push(node, payload: .editText(messageId: messageId), to: event, context: context)
////        }
//    }
}
