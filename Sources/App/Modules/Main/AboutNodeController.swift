//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 20.03.2021.
//

import Foundation
import Botter
import Vapor

class AboutNodeController: NodeController {
    func create(app: Application) throws -> EventLoopFuture<Node> {
        Node.create(
            name: "About node",
            messagesGroup: [
                .init(text: "Test message here."),
                .init(text: "And other message.")
            ],
            entryPoint: .about, app: app
        )
    }
}
