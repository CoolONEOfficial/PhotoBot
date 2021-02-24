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

final class StylistModel: SchemedModel, Content {
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
    }
}

extension StylistModel: EmployeeModel {
    typealias MyType = Stylist
    typealias PhotoModel = StylistPhoto
    
    var photoSiblings: PhotoSiblings { $photos }
}
