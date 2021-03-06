//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 26.02.2021.
//

import Foundation
import Vapor
import Fluent
import Botter

protocol PlatformFileProtocol: Cloneable where TwinType: PlatformFileProtocol {
    typealias Entry = Platform<String, String>
    
    var id: UUID? { get set }
    var platformEntries: [Entry]? { get set }
    var type: FileInfoType? { get set }
    
    init()
    static func create(id: UUID?, platformEntries: [Entry]?, type: FileInfoType?, app: Application) -> Future<Self>
}

extension PlatformFileProtocol {
    static func create(other: TwinType, app: Application) -> Future<Self> {
        Self.create(id: other.id, platformEntries: other.platformEntries, type: other.type, app: app)
    }
    
    static func create(id: UUID? = nil, platformEntries: [Entry]?, type: FileInfoType?, app: Application) -> Future<Self> {
        let instance = Self.init()
        instance.id = id
        instance.platformEntries = platformEntries
        instance.type = type
        return instance.saveIfNeeded(app: app)
    }
}