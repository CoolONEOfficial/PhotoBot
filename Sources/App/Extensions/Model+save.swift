//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 13.01.2021.
//

import FluentKit
import Botter

extension Model {
    public func saveWithId(on database: Database) -> Future<Self.IDValue> {
        save(on: database).map { self.id! }
    }
}
