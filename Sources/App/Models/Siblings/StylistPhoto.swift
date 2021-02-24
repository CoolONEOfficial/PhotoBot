//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.02.2021.
//

import Foundation
import Fluent
import Vapor

final class StylistPhoto: SchemedModel {
    static let schema = "stylists+platform_files"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "stylist_id")
    var stylist: StylistModel

    @Parent(key: "photo_id")
    var photo: PlatformFileModel

    init() { }

    init(id: UUID? = nil, stylist: StylistModel, photo: PlatformFileModel) throws {
        self.id = id
        self.$stylist.id = try stylist.requireID()
        self.$photo.id = try photo.requireID()
    }
}
