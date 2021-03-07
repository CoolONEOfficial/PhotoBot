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
    var history: [UserHistoryEntry]
    
    @OptionalParent(key: "node_id")
    var node: NodeModel?
    
    var nodeId: UUID? {
        get { self.$node.id }
        set { self.$node.id = newValue }
    }
    
    @OptionalField(key: "node_payload")
    var nodePayload: NodePayload?

    @Field(key: "platform_ids")
    var platformIds: [TypedPlatform<UserPlatformId>]

    @OptionalField(key: "name")
    var name: String?
    
    required init() { }

}

extension UserModel {    
    private static func filterQuery<T: Encodable>(_ platform: AnyPlatform, _ field: String,  _ value: T) throws -> String {
        """
            EXISTS (
                SELECT FROM unnest(platform_ids) AS elem WHERE (to_jsonb(elem)::json#>'{\(platform.name), \(field)}')::text = '\(try value.encodeToString()!)'
            )
        """
    }
    
    public static func find<T: PlatformObject & Replyable>(
        _ platformReplyable: T,
        on database: Database
    ) throws -> Future<UserModel?> {
        guard let destination = platformReplyable.destination else { throw PhotoBotError.destinationNotFound }
        let platform = platformReplyable.platform.any
        return try Self.find(destination: destination, platform: platform, on: database)
    }
    
    public static func find(
        destination: SendDestination,
        platform: AnyPlatform,
        on database: Database
    ) throws -> Future<UserModel?> {
        let filterQuery: String
       
        switch destination {
        case let .chatId(id), let .userId(id):
            filterQuery = try UserModel.filterQuery(platform, "id", id)
            
        case let .username(username):
            filterQuery = try UserModel.filterQuery(platform, "username", username)
        }
        
        return query(on: database).filter(.sql(raw: filterQuery)).first()
    }
}

extension Array {
    func first<Tg, Vk>(platform: AnyPlatform) -> Element? where Element == Platform<Tg, Vk> {
        first { $0.any == platform }
    }
    
    func firstValue<T>(platform: AnyPlatform) -> T? where Element == TypedPlatform<T> {
        first(platform: platform)?.value
    }
}
