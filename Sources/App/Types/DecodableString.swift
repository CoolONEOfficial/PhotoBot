//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

typealias DecodableString = String

extension DecodableString {
    func decode<T: Decodable>() throws -> T {
        try JSONDecoder.snakeCased.decode(T.self, from: data(using: .utf8)!)
    }
}
