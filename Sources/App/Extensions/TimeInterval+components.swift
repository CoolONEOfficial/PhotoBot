//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.03.2021.
//

import Foundation

extension TimeInterval {
    var components: (hours: Int, minutes: Int, seconds: Int) {
        let (hr,  minf) = modf (self / 3600)
        let (min, secf) = modf (60 * minf)
        return (hours: Int(hr), minutes: Int(min), seconds: Int(60 * secf))
    }
}
