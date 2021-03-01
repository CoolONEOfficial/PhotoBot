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

final class User: UserProtocol {
    
    typealias TwinType = UserModel
    
    var id: UUID?
    
    @Validated(.nonEmpty)
    var history: [UserHistoryEntry]?

    var nodeId: UUID?
    
    var nodePayload: NodePayload?
    
    var vkId: Int64?

    var tgId: Int64?
    
    @Validated(.greater(1)) // .isLetters &&
    var name: String?
    
    required init() {}
    
//    private let model: Model?
//
//    init(history: [HistoryEntry] = [], nodeId: UUID? = nil, nodePayload: NodePayload, vkId: Int64? = nil, tgId: Int64? = nil, name: String? = nil) {
//        id = nil
//        model = nil
//        self.history = history
//        self.nodeId = nodeId
//        self.nodePayload = nodePayload
//        self.vkId = vkId
//        self.tgId = tgId
//        self.name = name
//    }
//
//    // MARK: - Modeled Type
//
//    required init(from model: Model) {
//        self.model = model
//        id = model.id
//        history = model.history
//        nodeId = model.$node.id
//        nodePayload = model.nodePayload
//        vkId = model.vkId
//        tgId = model.tgId
//        name = model.name
//    }

}

extension User: ModeledType {
    //typealias Model = UserModel
    
    var isValid: Bool {
        _name.isValid
    }
    
    func saveModel(app: Application) throws -> EventLoopFuture<UserModel> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return try TwinType.create(other: self, app: app)
    }
}

extension User {
    public static func findOrCreate<T: PlatformObject & Replyable & UserFetchable>(
        from: T,
        on database: Database,
        bot: Bot,
        app: Application
    ) -> Future<User> {
        TwinType.findOrCreate(from: from, bot: bot, on: database, app: app).throwingFlatMap { try User.create(other: $0, app: app) }
    }
    
    public static func find<T: PlatformObject & Replyable>(
        _ replyable: T,
        on database: Database,
        app: Application
    ) -> Future<User?> {
        TwinType.find(replyable, on: database).throwingFlatMap { model in
            guard let model = model else { return app.eventLoopGroup.future(nil) }
            return try User.create(other: model, app: app).map { Optional($0) }
        }
    }
    
    enum HistoryAction {
        case save
        case noSave
        case replacing
    }
    
    func push<T: PlatformObject & Replyable>(
        _ target: PushTarget, payload: NodePayload? = nil,
        to replyable: T, with bot: Bot,
        app: Application, saveMove: Bool = true
    ) -> Future<[Message]> {
        Node.find(target, app: app).flatMap { node in
            try! self.push(node, payload: payload, to: replyable, with: bot, app: app, saveMove: saveMove)
        }
    }
    
    func push<T: PlatformObject & Replyable>(
        _ node: Node, payload: NodePayload? = nil,
        to replyable: T, with bot: Bot,
        app: Application, saveMove: Bool = true
    ) throws -> Future<[Message]> {
        
        if node.entryPoint == .welcome {
            history?.removeAll()
        } else if saveMove, let oldNodeId = self.nodeId {
            history?.append(.init(nodeId: oldNodeId, nodePayload: nodePayload))
        }

        self.nodePayload = payload
        self.nodeId = node.id!
        
        return try self.saveModelReturningId(app: app).flatMap { (id) -> Future<[Message]> in
            self.id = id
            return try! replyable.replyNode(with: bot, user: self, node: node, payload: payload, app: app)!
        }
    }
    
    func pop<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, app: Application) -> Future<[Message]>? {
        var counter = 0
        return pop(to: replyable, with: bot, app: app) { _ in
            counter += 1
            return counter == 1
        }
    }
    
    func pop<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, app: Application, while whileCompletion: (UserHistoryEntry) -> Bool) -> Future<[Message]>? {
        guard let lastHistoryEntry = history?.last else { return nil }
        for entry in history ?? [] {
            if whileCompletion(entry) {
                history?.removeLast()
            } else {
                break
            }
        }
        return push(.id(lastHistoryEntry.nodeId), payload: lastHistoryEntry.nodePayload, to: replyable, with: bot, app: app, saveMove: false)
    }
}

extension Encodable {
    func encodeToString() throws -> String? {
        String(data: try JSONEncoder.snakeCased.encode(self), encoding: .utf8)
    }
}
