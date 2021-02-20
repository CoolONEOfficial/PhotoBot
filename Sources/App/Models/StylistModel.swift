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

    //var avatar: BotterFile
    
    init() { }

    init(id: UUID? = nil, name: String? = nil) throws {
        self.id = id
        self.name = name
    }
}

extension StylistModel: TypedModel { typealias MyType = Stylist }
