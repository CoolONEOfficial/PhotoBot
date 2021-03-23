//
//  File.swift
//
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Fluent

struct CreatePhotographerPhotos: CreateSiblingPhotos {
    typealias TwinType = Photographer
    
    var name: String { "photographer" }
}
