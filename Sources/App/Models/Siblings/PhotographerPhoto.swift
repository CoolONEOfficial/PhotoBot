//
//  File.swift
//
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation
import Fluent
import Vapor

final class PhotographerPhoto: Model {
    static let schema = "photographers+platform_files"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "photographer_id")
    var photographer: PhotographerModel

    @Parent(key: "photo_id")
    var photo: PlatformFileModel

    init() { }

    init(id: UUID? = nil, stylist: PhotographerModel, photo: PlatformFileModel) throws {
        self.id = id
        self.$photographer.id = try photographer.requireID()
        self.$photo.id = try photo.requireID()
    }
}
