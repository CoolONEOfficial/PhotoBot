//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 16.03.2021.
//

import Foundation
import AnyCodable

protocol BuildableField {
    static func check(_ str: String) -> Bool
    static func value(_ str: String) -> AnyCodable
}

extension String: BuildableField {
    static func value(_ str: String) -> AnyCodable { .init(str) }
    
    static func check(_ str: String) -> Bool { !str.isEmpty }
}

extension Bool: BuildableField {
    static func value(_ str: String) -> AnyCodable { .init(str == "+") }
    
    static func check(_ str: String) -> Bool { str == "+" || str == "-" }
}

extension Optional: BuildableField where Wrapped: BuildableField {
    static func check(_ str: String) -> Bool { Wrapped.check(str) }
    
    static func value(_ str: String) -> AnyCodable { Wrapped.value(str) }
}
