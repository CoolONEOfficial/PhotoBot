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

final class MakeuperModel: Model, Content {
    static let schema = "makeupers"
    
    @ID(key: .id)
    var id: UUID?

    @OptionalField(key: "name")
    var name: String?

    @Siblings(through: MakeuperPhoto.self, from: \.$makeuper, to: \.$photo)
    var photos: [PlatformFileModel]
    
    init() { }

    init(id: UUID? = nil, name: String? = nil) throws {
        self.id = id
        self.name = name
    }
}

extension MakeuperModel: HumanModel { typealias MyType = Makeuper }
