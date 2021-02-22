//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation

protocol HumanModel: TypedModel {
    
    var id: UUID? { get set }

    var name: String? { get set }

    var photos: [PlatformFileModel] { get set }

}
