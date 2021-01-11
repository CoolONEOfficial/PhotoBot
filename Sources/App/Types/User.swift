//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 07.01.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import Vapor
import Fluent
import AnyCodable

class User {
    
    struct HistoryEntry: Codable {
        let nodeId: UUID
        let nodePayload: DecodableString?
    }
    
    var history: [HistoryEntry]

    var nodeId: UUID?
    
    var nodePayload: DecodableString?
    
    var vkId: Int64?

    var tgId: Int64?
    
    @Validated(.isLetters && .greater(1) && .less(25))
    var name: String?
    
    var toModel: UserModel {
        let model = self.model ?? .init()
        model.history = history
        model.$node.id = nodeId
        model.nodePayload = nodePayload
        model.tgId = tgId
        model.vkId = vkId
        model.name = name
        return model
    }
    
    private let model: UserModel?
    
    init(history: [HistoryEntry] = [], nodeId: UUID? = nil, nodePayload: DecodableString, vkId: Int64? = nil, tgId: Int64? = nil, name: String? = nil) {
        self.model = nil
        self.history = history
        self.nodeId = nodeId
        self.nodePayload = nodePayload
        self.vkId = vkId
        self.tgId = tgId
        self.name = name
    }

    required init(from model: UserModel) {
        self.model = model
        history = model.history
        nodeId = model.$node.id
        nodePayload = model.nodePayload
        vkId = model.vkId
        tgId = model.tgId
        name = model.name
    }
    
    var isValid: Bool {
        _name.isValid
    }
    
    public static func findOrCreate<T: Replyable>(
        _ replyable: T,
        on database: Database,
        app: Application
    ) -> Future<User> {
        UserModel.findOrCreate(replyable, on: database, app: app).map { try! $0.toMyType() }
    }
    
    public static func find<T: Replyable>(
        _ replyable: T,
        on database: Database
    ) -> Future<User?> {
        UserModel.find(replyable, on: database).map { try! $0?.toMyType() }
    }
    
    func moveToNode<NodePayload: Encodable, T: Replyable>(
        _ nodeId: UUID, payload: NodePayload? = nil, to replyable: T,
        with bot: Bot, on database: Database,
        app: Application, saveMove: Bool = true
    ) throws -> Future<[Message]> {
        moveToNode(nodeId, try payload?.encodeToString(), to: replyable, with: bot, on: database, app: app, saveMove: saveMove)
    }
    
    func moveToNode<T: Replyable>(
        _ nodeId: UUID, _ payload: String? = nil,
        to replyable: T, with bot: Bot, on database: Database,
        app: Application, saveMove: Bool = true
    ) -> Future<[Message]> {
        Node.find(nodeId, on: database).flatMap { node in
            try! self.moveToNode(node, payload: payload, to: replyable, with: bot, on: database, app: app, saveMove: saveMove)
        }
    }
    
    func moveToNode<NodePayload: Encodable, T: Replyable>(
        _ node: Node, payload: NodePayload? = nil,
        to replyable: T, with bot: Bot, on database: Database,
        app: Application, saveMove: Bool = true
    ) throws -> Future<[Message]> {
        try moveToNode(node, try payload?.encodeToString(), to: replyable, with: bot, on: database, app: app, saveMove: saveMove)
    }
    
    func moveToNode<T: Replyable>(
        _ node: Node, _ payload: String? = nil,
        to replyable: T, with bot: Bot, on database: Database,
        app: Application, saveMove: Bool = true
    ) throws -> Future<[Message]> {
        if node.entryPoint == .welcome {
            history.removeAll()
        } else if saveMove, let oldNodeId = self.nodeId {
            history.append(.init(nodeId: oldNodeId, nodePayload: nodePayload))
        }

        if !history.isEmpty, let lastMessage = node.messages?.last {
            let lastButtons: [Button] = (lastMessage.keyboard?.buttons.last ?? [])
                + [ try .init(text: "Back", action: .callback, data: NavigationPayload.back) ]
            
            if let _ = lastMessage.keyboard?.buttons.last {
                lastMessage.keyboard?.buttons.indices.last.map { lastMessage.keyboard?.buttons[$0] = lastButtons }
            } else {
                if lastMessage.keyboard == nil {
                    lastMessage.keyboard = .init(oneTime: false, buttons: [], inline: true)
                }
                lastMessage.keyboard?.buttons = [lastButtons]
            }
            
        }

        self.nodePayload = payload
        self.nodeId = node.id!

        return toModel.save(on: database).flatMap {
            for message in node.messages ?? [] {
                if let text = message.message {
                    message.message = MessageFormatter.shared.format(text, user: self)
                }
            }
            return try! replyable.replyNode(from: bot, node: node, app: app)!
        }
    }
    
    func pop<T: Replyable>(to replyable: T, with bot: Bot, on database: Database, app: Application) throws -> Future<[Message]>? {
        guard let lastHistoryEntry = history.last else { return nil }
        history.removeLast()
        return try moveToNode(lastHistoryEntry.nodeId, payload: lastHistoryEntry.nodePayload, to: replyable, with: bot, on: database, app: app, saveMove: false)
    }
}

extension Encodable {
    func encodeToString() throws -> String? {
        String(data: try JSONEncoder.snakeCased.encode(self), encoding: .utf8)
    }
}
