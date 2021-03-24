//
//  File.swift
//
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation
import Fluent
import Vapor
import Botter
import ValidatedPropertyKit

final class PhotographerModel: Model, PhotographerProtocol {
    typealias TwinType = Photographer

    static var schema: String  = "photographers"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalField(key: "name")
    var name: String?
    
    @Field(key: "platform_ids")
    var platformIds: [TypedPlatform<UserPlatformId>]
    
    @Field(key: "prices")
    var _prices: [String: Float]

    @Siblings(through: PhotographerPhoto.self, from: \.$photographer, to: \.$photo)
    var _photos: [PlatformFileModel]
    
    var photosSiblings: AttachableFileSiblings<PhotographerModel, PhotographerPhoto>? { $_photos }

    var photos: [PlatformFileModel] {
        get { _photos }
        set { _photos = newValue.compactMap { $0 } }
    }
    
    @Children(for: \.$_photographer)
    var users: [UserModel]
    
    var user: UserModel! {
        get { users.first }
        set { fatalError() }
    }
    
    var usersProperty: ChildrenProperty<PhotographerModel, UserModel>? { $users }
    
    required init() {}
}
