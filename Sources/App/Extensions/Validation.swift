//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 07.01.2021.
//

import Foundation
import ValidatedPropertyKit
import Botter
import AnyCodable

public extension Validation where Value == String {
    /// The Letters Validation
    static var isLetters: Validation {
        return self.regularExpression("[A-z, А-я]+")
    }

}

public extension Validation where Value: StringProtocol {
    
    /// Validation with less `<` than comparable value
    ///
    /// - Parameter comparableValue: The Comparable value
    /// - Returns: The Validation
    static func less(_ comparableValue: Int) -> Validation {
        return .init { value in
            if value.count < comparableValue {
                return .success
            } else {
                return .failure("\(value) is not less than \(comparableValue)")
            }
        }
    }
    
    /// Validation with less or equal `<=` than comparable value
    ///
    /// - Parameter comparableValue: The Comparable value
    /// - Returns: The Validation
    static func lessOrEqual(_ comparableValue: Int) -> Validation {
        return .init { value in
            if value.count <= comparableValue {
                return .success
            } else {
                return .failure("\(value) is not less or equal than \(comparableValue)")
            }
        }
    }
    
    /// Validation with greater `>` than comparable value
    ///
    /// - Parameter comparableValue: The Comparable value
    /// - Returns: The Validation
    static func greater(_ comparableValue: Int) -> Validation {
        return .init { value in
            if value.count > comparableValue {
                return .success
            } else {
                return .failure("\(value) is not greater than \(comparableValue)")
            }
        }
    }
    
    /// Validation with greater or equal `>=` than comparable value
    ///
    /// - Parameter comparableValue: The Comparable value
    /// - Returns: The Validation
    static func greaterOrEqual(_ comparableValue: Int) -> Validation {
        return .init { value in
            if value.count >= comparableValue {
                return .success
            } else {
                return .failure("\(value) is not greater or equal than \(comparableValue)")
            }
        }
    }
}

extension Validation where Value: Collection {
    
    /// The nonEmpty Validation
    static var nonEmpty: Self {
        .init { value in
            if !value.isEmpty {
                return .success
            } else {
                return .failure("\(value) is empty")
            }
        }
    }

}

extension Validation where Value == [TypedPlatform<String>] {
    static func contains(_ platforms: TypedPlatform<AnyCodable>...) -> Validation {
        return contains(platforms)
    }

    static func contains(_ platforms: [TypedPlatform<AnyCodable>]) -> Validation {
        return .init { value in
            if value.map({ $0.convert(to: AnyCodable()) }).contains(where: { platform in platforms.contains { $0 == platform } }) {
                return .success
            } else {
                return .failure("\(value) is not contains all \(platforms)")
            }
        }
    }
}


// MARK: - Result+Success

fileprivate extension Result where Success == Void {
    
    /// The success Result case
    static var success: Result {
        return .success(())
    }
    
}
