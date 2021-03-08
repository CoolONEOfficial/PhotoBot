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

    var history: [UserHistoryEntry] = []

    var nodeId: UUID?
    
    var nodePayload: NodePayload?
    
    var platformIds: [TypedPlatform<UserPlatformId>] = []
    
    var isAdmin: Bool = false
    
    @Validated(.greater(1))
    var firstName: String?

    @Validated(.greater(1))
    var lastName: String?
    
    required init() {}

}

extension User: ModeledType {
    
    var isValid: Bool {
        _firstName.isValid && _lastName.isValid
    }
    
    func save(app: Application) throws -> EventLoopFuture<UserModel> {
        guard isValid else {
            throw ModeledTypeError.validationError(self)
        }
        return TwinType.create(other: self, app: app)
    }
}

enum UserNavigationError: Error {
    case noHistory
    case noNodeId
}

extension User {

    static func create(from user: Botter.User, bot: Bot, app: Application) throws -> Future<User> {
        let firstName = user.firstName
        let lastName = user.lastName
        return try user.getUsername(bot: bot, app: app).flatMap { username in
            let platformId = UserPlatformId(id: user.id, username: username)
            return User.create(platformIds: [ user.platform.convert(to: platformId) ], firstName: firstName, lastName: lastName, app: app)
        }
    }
    
    public static func find(
        destination: SendDestination,
        platform: AnyPlatform,
        app: Application
    ) throws -> Future<User?> {
        try TwinType.find(destination: destination, platform: platform, on: app.db).optionalFlatMap { User.create(other: $0, app: app) }
    }
    
    static func find<T: PlatformObject & Replyable>(
        _ platformReplyable: T,
        app: Application
    ) throws -> Future<User?> {
        try TwinType.find(platformReplyable, on: app.db).optionalFlatMap { User.create(other: $0, app: app) }
    }
    
    public static func findOrCreate<T: PlatformObject & Replyable & UserFetchable>(
        from instance: T,
        bot: Bot,
        app: Application
    ) throws -> Future<User> {
        try Self.find(instance, app: app).flatMap { model in
            if let model = model {
                return app.eventLoopGroup.next().makeSucceededFuture(model)
            } else {
                return try! bot.getUser(from: instance, app: app)!.throwingFlatMap { botterUser -> Future<User> in
                    try Self.create(from: botterUser, bot: bot, app: app)
                }
            }
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
        Node.find(target, app: app).throwingFlatMap { node in
            try self.push(node, payload: payload, to: replyable, with: bot, app: app, saveMove: saveMove)
        }
    }
    
    func push<T: PlatformObject & Replyable>(
        _ node: Node, payload: NodePayload? = nil,
        to replyable: T, with bot: Bot,
        app: Application, saveMove: Bool = true
    ) throws -> Future<[Message]> {
        
        if node.entryPoint == .welcome {
            history.removeAll()
        } else if saveMove, let oldNodeId = self.nodeId {
            history.append(.init(nodeId: oldNodeId, nodePayload: nodePayload))
        }

        self.nodePayload = payload
        self.nodeId = node.id!
        
        return try self.saveReturningId(app: app).throwingFlatMap { (id) -> Future<[Message]> in
            self.id = id
            return try replyable.replyNode(with: bot, user: self, node: node, payload: payload, app: app)!
        }
    }
    
    func popToMain<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, app: Application) throws -> Future<[Message]> {
        try pop(to: replyable, with: bot, app: app) { _ in true }
    }

    func pop<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, app: Application) throws -> Future<[Message]> {
        var counter = 0
        return try pop(to: replyable, with: bot, app: app) { _ in
            counter += 1
            return counter == 1
        }
    }
    
    func pop<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, app: Application, while whileCompletion: (UserHistoryEntry) -> Bool) throws -> Future<[Message]> {
        guard !history.isEmpty else { throw UserNavigationError.noHistory }
        for (index, entry) in history.enumerated().reversed() {
            if whileCompletion(entry), index != 0 {
                history.removeLast()
            } else {
                break
            }
        }
        let newestHistoryEntry = history.last!
        return push(.id(newestHistoryEntry.nodeId), payload: newestHistoryEntry.nodePayload, to: replyable, with: bot, app: app, saveMove: false)
    }
    
    func pushToActualNode<T: PlatformObject & Replyable>(to replyable: T, with bot: Bot, app: Application) throws -> Future<[Message]> {
        guard let nodeId = nodeId else { throw UserNavigationError.noNodeId }
        return push(.id(nodeId), payload: nodePayload, to: replyable, with: bot, app: app, saveMove: false)
    }
}

extension Encodable {
    func encodeToString() throws -> String? {
        String(data: try JSONEncoder.snakeCased.encode(self), encoding: .utf8)
    }
}
