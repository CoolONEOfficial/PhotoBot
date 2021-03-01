//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 21.02.2021.
//

import Fluent

struct CreateStylistPhotos: CreatePhotos {
    typealias TwinType = Stylist
    
    var name: String { "stylist" }
}
