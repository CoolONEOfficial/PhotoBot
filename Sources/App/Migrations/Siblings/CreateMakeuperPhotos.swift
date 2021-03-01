//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Fluent

struct CreateMakeuperPhotos: CreatePhotos {
    typealias TwinType = Makeuper
    
    var name: String { "makeuper" }
}
