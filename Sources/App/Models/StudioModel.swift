//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Fluent
import Vapor
import Botter

final class StudioModel: Model, StudioProtocol {
    static let schema = "studios"
    
    typealias TwinType = Studio
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String?
    
    @Field(key: "description")
    var description: String?
    
    @Field(key: "address")
    var address: String?
    
    @Siblings(through: StudioPhoto.self, from: \.$studio, to: \.$photo)
    var _photos: [PlatformFileModel]
    
    var photos: [PlatformFileModel] {
        get { _photos }
        set { fatalError("Siblings must be attached manually") }
    }
    
    var photosSiblings: AttachableFileSiblings<StudioModel, StudioPhoto>? { $_photos }
    
    @Field(key: "prices")
    var _prices: [String: Float]
    
    @Field(key: "coords")
    var coords: Coords?
    
    // Platform identifiable
    
    @Field(key: "platform_ids")
    var platformIds: [TypedPlatform<UserPlatformId>]
    
    @Children(for: \.$_studio)
    var users: [UserModel]
    
    var user: UserModel! {
        get { users.first }
        set { fatalError() }
    }
    
    var usersProperty: ChildrenProperty<StudioModel, UserModel>? { $users }

    required init() { }
}
