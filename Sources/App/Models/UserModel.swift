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

}

extension UserModel {
    
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
