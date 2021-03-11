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

final class MakeuperModel: Model, MakeuperProtocol {
    typealias TwinType = Makeuper

    static var schema: String  = "makeupers"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalField(key: "name")
    var name: String?
    
    @Field(key: "platform_ids")
    var platformIds: [TypedPlatform<UserPlatformId>]
    
    @Siblings(through: MakeuperPhoto.self, from: \.$makeuper, to: \.$photo)
    var _photos: [PlatformFileModel]
    
    var photosSiblings: AttachableFileSiblings<MakeuperModel, MakeuperPhoto>? { $_photos }

    var photos: [PlatformFileModel] {
        get { _photos }
        set { _photos = newValue.compactMap { $0 } }
    }
    
    @Field(key: "price")
    var price: Int
    
    required init() {}
}
