//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 23.02.2021.
//

import Fluent

struct CreateStudioPhotos: CreateSiblingPhotos {
    typealias TwinType = Studio
    
    var name: String { "studio" }
}
