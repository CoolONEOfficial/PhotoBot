//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.02.2021.
//

import Foundation
import Botter
import Fluent
import Vapor

typealias AttachableFileSiblings<From: Model, Through: Model> = SiblingsProperty<From, PlatformFileModel, Through>

final class PlatformFileModel: Model, PlatformFileProtocol {
    static let schema = "platform_files"
    
    typealias TwinType = PlatformFile
    
    @ID(key: .id)
    var id: UUID?

    @Siblings(through: StylistPhoto.self, from: \.$photo, to: \.$stylist)
    var stylists: [StylistModel]

    @Siblings(through: MakeuperPhoto.self, from: \.$photo, to: \.$makeuper)
    var makeupers: [MakeuperModel]
    
    @Field(key: "platform_entries")
    var platformEntries: [Entry]?
    
    @Field(key: "type")
    var type: FileInfoType?
    
    required init() {}
}
