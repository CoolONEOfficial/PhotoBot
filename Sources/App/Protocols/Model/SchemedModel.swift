//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 23.02.2021.
//

import Fluent

protocol SchemedModel: Model {
    static var schema: String { get }
}
