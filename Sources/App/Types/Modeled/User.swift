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

public final class User: UserProtocol {
    
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
    
    var makeuper: MakeuperModel?
    
    var makeuperId: UUID? { makeuper?.id }
    
    var stylist: StylistModel?
    
    var stylistId: UUID? { stylist?.id }
    
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
        return try TwinType.create(other: self, app: app)
    }
}

enum UserNavigationError: Error {
    case noHistory
    case noNodeId
}

extension User {

    static func create(from user: Botter.User, context: BotContextProtocol) throws -> Future<User> {
        let (app, bot, platform) = (context.app, context.bot, context.platform)
        let firstName = user.firstName
        let lastName = user.lastName
        return try user.getUsername(bot: bot, app: app).flatMap { username in
            let platformId = UserPlatformId(id: user.id, username: username)
            return User.create(platformIds: [ user.platform.convert(to: platformId) ], isAdmin: Application.adminNickname(for: platform) == username, firstName: firstName, lastName: lastName, app: app)
        }
    }
    
    public static func find(
        destination: SendDestination,
        platform: AnyPlatform,
        app: Application
    ) throws -> Future<User?> {
        try TwinType.find(destination: destination, platform: platform, on: app.db).optionalThrowingFlatMap { try User.create(other: $0, app: app) }
    }
    
    static func find<T: PlatformObject & Replyable>(
        _ platformReplyable: T,
        app: Application
    ) throws -> Future<User?> {
        try TwinType.find(platformReplyable, on: app.db).optionalThrowingFlatMap { try User.create(other: $0, app: app) }
    }
    
    public static func findOrCreate<T: PlatformObject & Replyable & UserFetchable>(
        from instance: T,
        context: BotContextProtocol
    ) throws -> Future<User> {
        let (bot, app) = (context.bot, context.app)
        return try Self.find(instance, app: app).flatMap { model in
            if let model = model {
                return app.eventLoopGroup.next().makeSucceededFuture(model)
            } else {
                return try! bot.getUser(from: instance, app: app)!.throwingFlatMap { botterUser -> Future<User> in
                    try Self.create(from: botterUser, context: context)
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
        to replyable: T, saveMove: Bool = true, context: PhotoBotContextProtocol
    ) -> Future<[Message]> {
        Node.find(target, app: context.app).throwingFlatMap { node in
            try self.push(node, payload: payload, to: replyable, saveMove: saveMove, context: context)
        }
    }
    
    func push<T: PlatformObject & Replyable>(
        _ node: Node, payload: NodePayload? = nil,
        to replyable: T, saveMove: Bool = true,
        context: PhotoBotContextProtocol
    ) throws -> Future<[Message]> {
        
        if node.entryPoint == .welcome {
            history.removeAll()
        } else if saveMove, let oldNodeId = self.nodeId {
            history.append(.init(nodeId: oldNodeId, nodePayload: nodePayload))
        }

        self.nodePayload = payload
        self.nodeId = node.id!
        
        return try self.saveReturningId(app: context.app).throwingFlatMap { (id) -> Future<[Message]> in
            self.id = id
            return try replyable.replyNode(node: node, payload: payload, context: context)!
        }
    }
    
    func popToMain<T: PlatformObject & Replyable>(to replyable: T, context: PhotoBotContextProtocol) throws -> Future<[Message]> {
        try pop(to: replyable, context: context) { _ in true }
    }

    func pop<T: PlatformObject & Replyable>(to replyable: T, context: PhotoBotContextProtocol) throws -> Future<[Message]> {
        var counter = 0
        return try pop(to: replyable, context: context) { _ in
            counter += 1
            return counter == 1
        }
    }
    
    func pop<T: PlatformObject & Replyable>(to replyable: T, context: PhotoBotContextProtocol, while whileCompletion: (UserHistoryEntry) -> Bool) throws -> Future<[Message]> {
        guard !history.isEmpty, let nodeId = nodeId else { throw UserNavigationError.noHistory }
        if whileCompletion(UserHistoryEntry(nodeId: nodeId, nodePayload: nodePayload)) {
            for (index, entry) in history.enumerated().reversed() {
                if whileCompletion(entry), index != 0 {
                    history.removeLast()
                } else {
                    break
                }
            }
        }
        let newestHistoryEntry = history.last!
        history.removeLast()
        return push(.id(newestHistoryEntry.nodeId), payload: newestHistoryEntry.nodePayload, to: replyable, saveMove: false, context: context)
    }
    
    func pushToActualNode<T: PlatformObject & Replyable>(to replyable: T, context: PhotoBotContextProtocol) throws -> Future<[Message]> {
        guard let nodeId = nodeId else { throw UserNavigationError.noNodeId }
        return push(.id(nodeId), payload: nodePayload, to: replyable, saveMove: false, context: context)
    }
}

extension Encodable {
    func encodeToString() throws -> String? {
        String(data: try JSONEncoder.snakeCased.encode(self), encoding: .utf8)
    }
}
