//
//  File.swift
//  
//
//  Created by Nickolay Truhin on 10.03.2021.
//

import Foundation
import DateHelper

extension DateComponents {
    static func create(timeZone: TimeZone? = nil, era: Int? = nil, year: Int? = nil, month: Int? = nil, day: Int? = nil, hour: Int? = nil, minute: Int? = nil, second: Int? = nil, nanosecond: Int? = nil, weekday: Int? = nil, weekdayOrdinal: Int? = nil, quarter: Int? = nil, weekOfMonth: Int? = nil, weekOfYear: Int? = nil, yearForWeekOfYear: Int? = nil) -> Self {
        .init(calendar: .current, timeZone: timeZone, era: era, year: year, month: month, day: day, hour: hour, minute: minute, second: second, nanosecond: nanosecond, weekday: weekday, weekdayOrdinal: weekdayOrdinal, quarter: quarter, weekOfMonth: weekOfMonth, weekOfYear: weekOfYear, yearForWeekOfYear: yearForWeekOfYear)
    }
}

extension ClosedRange where Bound == Date {
    func intervalDates(_ dateComponent: DateComponentType, _ offset: Int) -> [Date] {
        let interval = Date(timeIntervalSince1970: 0).adjust(dateComponent, offset: offset).timeIntervalSince1970
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
