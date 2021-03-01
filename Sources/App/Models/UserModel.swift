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

final class UserModel: Model, UserProtocol {
    typealias TwinType = User
    
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "history")
    var history: [UserHistoryEntry]?
    
    @OptionalParent(key: "node_id")
    var node: NodeModel?
    
    var nodeId: UUID? {
        get { self.$node.id }
        set { self.$node.id = newValue }
    }
    
    @OptionalField(key: "node_payload")
    var nodePayload: NodePayload?
    
    @ID(custom: "vk_id")
    var vkId: Int64?
    
    @ID(custom: "tg_id")
    var tgId: Int64?

    @OptionalField(key: "name")
    var name: String?
    
    required init() { }
    
//    init(id: UUID? = nil, node: NodeModel? = nil, history: [User.HistoryEntry] = [], tgId: Int64? = nil, vkId: Int64? = nil, name: String? = nil) throws {
//        self.id = id
//        self.vkId = vkId
//        self.tgId = tgId
//        self.name = name
//        if let node = node {
//            self.$node.id = try node.requireID()
//        }
//        self.history = history
//    }
//
}

//extension UserModel: TypedModel { typealias MyType = User }

extension UserModel {
    
    static func create(from user: Botter.User, app: Application) throws -> Future<UserModel> {
        let name = user.firstName
        switch user.platform {
        case .tg:
            return try UserModel.create(tgId: user.id, name: name, app: app)
        case .vk:
            return try UserModel.create(vkId: user.id, name: name, app: app)
        }
    }
    
    public static func findOrCreate<T: PlatformObject & Replyable & UserFetchable>(
        from instance: T,
        bot: Bot,
        on database: Database,
        app: Application
    ) -> Future<UserModel> {
        find(instance, on: database).flatMap { model in
            if let model = model {
                return app.eventLoopGroup.next().makeSucceededFuture(model)
            } else {
                return try! bot.getUser(from: instance, app: app)!.throwingFlatMap { botterUser -> Future<UserModel> in
                    try UserModel.create(from: botterUser, app: app).flatMap {
                        $0.save(on: database).transform(to: $0)
                    }
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
