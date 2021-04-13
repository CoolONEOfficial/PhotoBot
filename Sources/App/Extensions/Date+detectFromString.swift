//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 13.04.2021.
//

import SwiftyChrono

#if os(Linux)

extension Date {
    init(detectFromString str: String) {
        Chrono().parseDate(text: text)
    }
}

#endif
