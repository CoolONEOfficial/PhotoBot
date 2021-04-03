//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 03.04.2021.
//

import Foundation
import Fluent
import Vapor
import Botter
import ValidatedPropertyKit

final class ReviewModel: Model, ReviewProtocol {
    typealias TwinType = Review
    
    static let schema = "reviews"
    
    @ID(key: .id)
    var id: UUID?
    
    @OptionalParent(key: "screenshot")
    var _screenshot: PlatformFileModel!
    
    var screenshot: PlatformFileModel! {
        get { _screenshot }
        set { $_screenshot.id = newValue.id }
    }
    
    required init() { }
    
}
