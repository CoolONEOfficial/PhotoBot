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

final class StylistModel: Model, Content {
    static let schema = "stylists"
    
    @ID(key: .id)
    var id: UUID?

    @OptionalField(key: "name")
    var name: String?

    @Siblings(through: StylistPhoto.self, from: \.$stylist, to: \.$photo)
    var photos: [PlatformFileModel]
    
    init() { }

    init(id: UUID? = nil, name: String? = nil) throws {
        self.id = id
        self.name = name
        //self.avatar = avatar
    }
}

extension StylistModel: TypedModel { typealias MyType = Stylist }
