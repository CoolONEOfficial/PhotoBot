//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 14.02.2021.
//

import Foundation
import Fluent
import Vapor
import Botter
import ValidatedPropertyKit

final class StylistModel: Model, StylistProtocol {

    typealias TwinType = Stylist
    
    static var schema: String  = "stylists"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalField(key: "name")
    var name: String?
    
    @Siblings(through: StylistPhoto.self, from: \.$stylist, to: \.$photo)
    var _photos: [PlatformFileModel]

    @Field(key: "price")
    var price: Int

    var photos: [PlatformFileModel] {
        get { _photos }
        set { fatalError("Siblings must be attached manually") }
    }

    var photosSiblings: AttachableFileSiblings<StylistModel, StylistPhoto>? { $_photos }
    
    required init() {}
}

extension StylistModel {
    
    typealias PhotoModel = StylistPhoto
}
