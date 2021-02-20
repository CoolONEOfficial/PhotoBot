//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 03.02.2021.
//

import Foundation

protocol BuildableModel: Codable {
    init<T: Buildable>(from buildable: T) throws
}

extension BuildableModel {
    init<T: Buildable>(from buildable: T) throws {
        self = try JSONDecoder.snakeCased.decode(Self.self, from: try JSONEncoder.snakeCased.encode(buildable))
    }
}

protocol Buildable: Codable {
    init()

    var modelType: BuildableModel.Type { get }
}

extension Buildable {
    func toModel() throws -> BuildableModel {
        try modelType.init(from: self)
    }
}
