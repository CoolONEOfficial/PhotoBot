//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.03.2021.
//

import Foundation

extension ClosedRange where Bound == Date {
    func intervalDates(with interval: TimeInterval = 60 * 60 * 24) -> [Date] {
        guard interval > 0 else { return [] }

        var dates:[Date] = []
        var currentDate = lowerBound

        dates.append(currentDate)
        while currentDate < upperBound {
            currentDate = currentDate.addingTimeInterval(interval)
            dates.append(currentDate)
        }

        return dates
    }
}
