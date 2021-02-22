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

final class PlatformFileModel: Model, Content {
    static let schema = "platform_files"
    
    @ID(key: .id)
    var id: UUID?

    @Siblings(through: StylistPhoto.self, from: \.$photo, to: \.$stylist)
    var stylists: [StylistModel]

    @Siblings(through: MakeuperPhoto.self, from: \.$photo, to: \.$makeuper)
    var makeupers: [MakeuperModel]
    
    @Field(key: "platform_entries")
    var platformEntries: [PlatformFile.Entry]
    
    @Field(key: "type")
    var type: FileInfoType
}

extension PlatformFileModel: TypedModel { typealias MyType = PlatformFile }
