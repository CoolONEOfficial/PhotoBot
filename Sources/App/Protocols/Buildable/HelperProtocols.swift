//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 16.03.2021.
//

import Foundation

protocol ArrayProtocol {
    static var elementType: Any.Type { get }
    var elements: [Any] { get }
}

extension Array: ArrayProtocol {
    static var elementType: Any.Type { Element.self }
    var elements: [Any] { self }
}

protocol OptionalProtocol {
    var myWrappedType: Any.Type { get }
    var myWrapped: Any? { get }
}

extension Optional: OptionalProtocol {
    var myWrappedType: Any.Type {
        Wrapped.self
    }
    
    var myWrapped: Any? {
        wrapped
    }
}
