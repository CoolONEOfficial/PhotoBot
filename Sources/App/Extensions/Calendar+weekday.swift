//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.03.2021.
//

import Foundation

extension Calendar {
    func weekday(date: Date) -> Int {
        var weekday = component(.weekday, from: date) - firstWeekday
        if weekday <= 0 {
            weekday += 7
        }
        return weekday - 1
    }
}
