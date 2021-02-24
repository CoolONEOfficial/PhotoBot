//
//  UserModel.swift
//
//
//  Created by Nickolay Truhin on 08.01.2021.
//

import Fluent
import Vapor
import Botter
import ValidatedPropertyKit

final class UserModel: SchemedModel, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "history")
    var history: [User.HistoryEntry]
    
    @OptionalParent(key: "node_id")
    var node: NodeModel?
    
    @OptionalField(key: "node_payload")
    var nodePayload: NodePayload?
    
    @ID(custom: "vk_id")
    var vkId: Int64?
    
    @ID(custom: "tg_id")
    var tgId: Int64?

    @OptionalField(key: "name")
    var name: String?
    
    init() { }

    init(id: UUID? = nil, node: NodeModel? = nil, history: [User.HistoryEntry] = [], tgId: Int64? = nil, vkId: Int64? = nil, name: String? = nil) throws {
        self.id = id
        self.vkId = vkId
        self.tgId = tgId
        self.name = name
        if let node = node {
            self.$node.id = try node.requireID()
        }
        self.history = history
    }
    
    convenience init(from user: Botter.User) throws {
        let name = user.firstName
        switch user.platform {
        case .tg:
            try self.init(tgId: user.id, name: name)
        case .vk:
            try self.init(vkId: user.id, name: name)
        }
    }
    
    public static func findOrCreate<T: PlatformObject & Replyable & UserFetchable>(
        from instance: T,
        bot: Bot,
        on database: Database,
        app: Application
    ) -> Future<UserModel> {
        find(instance, on: database).flatMap { user in
            if let user = user {
                return app.eventLoopGroup.next().makeSucceededFuture(user)
            } else {
                return try! bot.getUser(from: instance, app: app)!.flatMap { user -> Future<UserModel> in
                    let userModel = try! UserModel(from: user)
                    return userModel.save(on: database).transform(to: userModel)
                }
            }
        }
    }
    
    public static func find<T: PlatformObject & Replyable>(
        _ platformReplyable: T,
        on database: Database
    ) -> Future<UserModel?> {
        let id = platformReplyable.userId!
        switch platformReplyable.platform {
        case .tg:
            return query(on: database)
                .filter(\.$tgId == id)
                .first()
        case .vk:
            return query(on: database)
                .filter(\.$vkId == id)
                .first()
        }
    }
}

extension UserModel: TypedModel { typealias MyType = User }
