//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 03.04.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

protocol ReviewProtocol: Twinable where TwinType: ReviewProtocol {
    
    var id: UUID? { get set }
    var screenshot: PlatformFileModel! { get set }

    init()
    static func create(id: UUID?, screenshot: PlatformFileModel, app: Application) -> Future<Self>
}

extension ReviewProtocol {
    static func create(other: TwinType, app: Application) -> Future<Self> {
        Self.create(id: other.id, screenshot: other.screenshot, app: app)
    }
    
    static func create(id: UUID? = nil, screenshot: PlatformFileModel, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.screenshot = screenshot
        return instance.saveIfNeeded(app: app)
    }
}
