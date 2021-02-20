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

    @Field(key: "platform")
    var platform: [PlatformFile.Entry]
}

extension PlatformFileModel: TypedModel { typealias MyType = PlatformFile }
