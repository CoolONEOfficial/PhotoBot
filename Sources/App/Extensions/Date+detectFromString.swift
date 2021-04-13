//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 13.04.2021.
//

import SwiftyChrono
import Foundation

#if os(Linux)

extension Date {
    init?(detectFromString text: String) {
        guard let date = Chrono().parseDate(text: text) else { return nil }
        self = date
    }
}

#endif
