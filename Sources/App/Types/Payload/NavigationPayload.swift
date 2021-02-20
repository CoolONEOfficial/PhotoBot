//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.01.2021.
//

import Foundation

enum NavigationPayload: AutoCodable {
    case back
    case toNode(UUID)
    case previousPage
    case nextPage
}
