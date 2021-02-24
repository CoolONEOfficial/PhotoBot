//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Fluent
import Vapor
import Botter

final class StudioModel: SchemedModel, Content {
    static let schema = "studios"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "address")
    var address: String
    
    @Siblings(through: StudioPhoto.self, from: \.$studio, to: \.$photo)
    var photos: [PlatformFileModel]
    
    @Field(key: "coords")
    var coords: Coords

    init() { }

    init(id: UUID? = nil, name: String, address: String, coords: Coords) {
        self.id = id
        self.name = name
        self.address = address
        self.coords = coords
    }
}

extension StudioModel: TypedModel { typealias MyType = Studio }
