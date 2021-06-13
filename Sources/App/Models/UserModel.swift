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

    @Field(key: "is_admin")
    var isAdmin: Bool
    
    @OptionalField(key: "first_name")
    var firstName: String?
    
    @OptionalField(key: "last_name")
    var lastName: String?
    
    @OptionalParent(key: "makeuper_id")
    var _makeuper: MakeuperModel?

    var makeuper: MakeuperModel? {
        get { _makeuper }
        set { $_makeuper.id = newValue?.id }
    }
    
    var makeuperId: UUID? { $_makeuper.id }
    
    @OptionalParent(key: "stylist_id")
    var _stylist: StylistModel?

    var stylist: StylistModel? {
        get { _stylist }
        set { $_stylist.id = newValue?.id }
    }
    
    var stylistId: UUID? { $_stylist.id }

    @OptionalParent(key: "photographer_id")
    var _photographer: PhotographerModel?

    var photographer: PhotographerModel? {
        get { _photographer }
        set { $_photographer.id = newValue?.id }
    }
    
    var photographerId: UUID? { $_photographer.id }
    
    @OptionalParent(key: "studio_id")
    var _studio: StudioModel?
    
    var studio: StudioModel? {
        get { _studio }
        set { $_studio.id = newValue?.id }
    }
    
    var studioId: UUID? { $_studio.id }
    
    @Children(for: \.$owner)
    var payloads: [EventPayloadModel]

    @OptionalField(key: "last_destination")
    var lastDestination: UserDestination?

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
