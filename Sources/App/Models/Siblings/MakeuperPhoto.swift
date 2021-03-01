//
//  File.swift
//
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation
import Fluent
import Vapor

final class MakeuperPhoto: Model {
    static let schema = "makeupers+platform_files"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "makeuper_id")
    var makeuper: MakeuperModel

    @Parent(key: "photo_id")
    var photo: PlatformFileModel

    init() { }

    init(id: UUID? = nil, stylist: MakeuperModel, photo: PlatformFileModel) throws {
        self.id = id
        self.$makeuper.id = try makeuper.requireID()
        self.$photo.id = try photo.requireID()
    }
}
