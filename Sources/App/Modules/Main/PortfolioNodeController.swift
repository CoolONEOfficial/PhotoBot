//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class PortfolioNodeController: NodeController {
    func create(app: Application) -> Future<Node> {
        Node.create(
            name: "Portfolio node",
            messagesGroup: [
                .init(text: "Test message here.")
            ],
            entryPoint: .portfolio, app: app
        )
    }
    
    
    func getListSendMessages(platform: AnyPlatform, in node: Node, _ payload: NodePayload?, context: PhotoBotContextProtocol, listType: MessageListType, indexRange: Range<Int>) throws -> EventLoopFuture<[SendMessage]>? {
        guard listType == .portfolio else { return nil }
        //let (app, user) = (context.app, context.user)
        
        return context.app.eventLoopGroup.future([])
    }
}
