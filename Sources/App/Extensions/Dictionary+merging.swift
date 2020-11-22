//
//  Dictionary+merging.swift
//  
//
//  Created by Nickolay Truhin on 22.11.2020.
//

import Foundation

public extension Dictionary {
    func merging(_ dict: [Key: Value]) -> [Key: Value] {
        merging(dict) { _, new in new }
    }
}
