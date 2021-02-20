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
        let nodePayload: NodePayload?
    }
    
    var history: [HistoryEntry]

    var nodeId: UUID?
    
    var nodePayload: NodePayload?
    
    var vkId: Int64?

    var tgId: Int64?
    
    @Validated(.greater(1)) // .isLetters && 
    var name: String?
    
    private let model: Model?
    
    init(history: [HistoryEntry] = [], nodeId: UUID? = nil, nodePayload: NodePayload, vkId: Int64? = nil, tgId: Int64? = nil, name: String? = nil) {
        self.model = nil
        self.history = history
        self.nodeId = nodeId
        self.nodePayload = nodePayload
        self.vkId = vkId
        self.tgId = tgId
        self.name = name
    }
    
    // MARK: - Modeled Type

    required init(from model: Model) {
        self.model = model
        history = model.history
        nodeId = model.$node.id
        nodePayload = model.nodePayload
        vkId = model.vkId
        tgId = model.tgId
        name = model.name
    }

}

extension User: ModeledType {
    typealias Model = UserModel
    
    var isValid: Bool {
        _name.isValid
    }
    
    func toModel() throws -> Model {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        let model = self.model ?? .init()
        model.history = history
        model.$node.id = nodeId
        model.nodePayload = nodePayload
        model.tgId = tgId
        model.vkId = vkId
        model.name = name
        return model
    }
}

extension User {
    public static func findOrCreate<T: PlatformObject & Replyable & UserFetchable>(
        from: T,
        on database: Database,
        bot: Bot,
        app: Application
    ) -> Future<User> {
        Model.findOrCreate(from: from, bot: bot, on: database, app: app).map { try! $0.toMyType() }
    }
    
    public static func find<T: PlatformObject & Replyable>(
        _ replyable: T,
        on database: Database
    ) -> Future<User?> {
        Model.find(replyable, on: database).map { try! $0?.toMyType() }
    }
    
    enum HistoryAction {
        case save
        case noSave
        case replacing
    }
    
    func moveToNode<T: PlatformObject & Replyable>(
        _ nodeId: UUID, payload: NodePayload? = nil,
        to replyable: T, with bot: Bot, on database: Database,
        app: Application, saveMove: Bool = true
    ) -> Future<[Message]> {
        Node.find(nodeId, on: database).flatMap { node in
            try! self.moveToNode(node, payload: payload, to: replyable, with: bot, on: database, app: app, saveMove: saveMove)
        }
    }
    
    func moveToNode<T: PlatformObject & Replyable>(
        _ node: Node, payload: NodePayload? = nil,
        to replyable: T, with bot: Bot, on database: Database,
        app: Application, saveMove: Bool = true
    ) throws -> Future<[Message]> {
        if node.entryPoint == .welcome {
            history.removeAll()
        } else if saveMove, let oldNodeId = self.nodeId {
            history.append(.init(nodeId: oldNodeId, nodePayload: nodePayload))
        }

        return node.messagesGroup.initializeArray(in: node, app: app, self, payload).throwingFlatMap { messages in
            
            if !self.history.isEmpty, let lastMessage = messages.last {
                let actualLastButtons = lastMessage.keyboard.buttons.last
                let newLastButtons: [Button] = (actualLastButtons ?? [])
                    + [ try! .init(text: "Back", action: .callback, data: NavigationPayload.back) ]
                
                if actualLastButtons != nil {
                    lastMessage.keyboard.buttons.indices.last.map { lastMessage.keyboard.buttons[$0] = newLastButtons }
                } else {
                    lastMessage.keyboard.buttons = [newLastButtons]
                }
                
            }

            self.nodePayload = payload
            self.nodeId = node.id!
            
            return try self.toModel().save(on: database).flatMap { () -> Future<[Message]> in
                for message in messages {
                    if let text = message.text {
                        message.text = MessageFormatter.shared.format(text, user: self)
                    }
                }
                return try! replyable.replyNode(with: bot, user: self, node: node, app: app)!
            }
        }
    }
    
    func pop<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, on database: Database, app: Application) -> Future<[Message]>? {
        var counter = 0
        return pop(to: replyable, with: bot, on: database, app: app) { _ in
            counter += 1
            return counter == 1
        }
    }
    
    func pop<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, on database: Database, app: Application, while whileCompletion: (HistoryEntry) -> Bool) -> Future<[Message]>? {
        guard let lastHistoryEntry = history.last else { return nil }
        for entry in history {
            if whileCompletion(entry) {
                history.removeLast()
            } else {
                break
            }
        }
        return moveToNode(lastHistoryEntry.nodeId, payload: lastHistoryEntry.nodePayload, to: replyable, with: bot, on: database, app: app, saveMove: false)
    }
}

extension Encodable {
    func encodeToString() throws -> String? {
        String(data: try JSONEncoder.snakeCased.encode(self), encoding: .utf8)
    }
}
