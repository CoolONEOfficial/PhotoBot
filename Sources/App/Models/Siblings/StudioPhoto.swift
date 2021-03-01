//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation
import Fluent
import Vapor

final class StudioPhoto: Model {
    static let schema = "studios+platform_files"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "studio_id")
    var studio: StudioModel

    @Parent(key: "photo_id")
    var photo: PlatformFileModel

    init() { }

    init(id: UUID? = nil, stylist: StudioModel, photo: PlatformFileModel) throws {
        self.id = id
        self.$studio.id = try studio.requireID()
        self.$photo.id = try photo.requireID()
    }
}
