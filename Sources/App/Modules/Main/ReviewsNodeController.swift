//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class ReviewsNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "Reviews node",
            messagesGroup: .list(.reviews),
            entryPoint: .reviews, app: app
        )
    }
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<([SendMessage], Int)>? {
        guard listType == .reviews else { return nil }
        let (app, _) = (context.app, context.user)
        
        return app.eventLoopGroup.future(([], 0))
    }
}
