//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 22.02.2021.
//

import Foundation
import Fluent

protocol EmployeeModel: TypedModel where MyType: PhotoModeledType {
    
    var id: UUID? { get set }

    var name: String? { get set }

    var photos: [PlatformFileModel] { get set }

    typealias PhotoSiblings = SiblingsProperty<MyType.Model, PlatformFileModel, MyType.PhotoModel>
    
    var photoSiblings: PhotoSiblings { get }
    
}
