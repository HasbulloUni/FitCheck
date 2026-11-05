//
//  ProgressFormat.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - Dates and numbers as text
// All the texts of the Progress screen are made here, always in English.
enum ProgressFormat {

    // One formatter for each pattern, created once
    private static func makeFormatter(_ pattern: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.calendar = ProgressPeriodBuilder.calendar
        formatter.dateFormat = pattern
        return formatter
    }

    private static let dayMonthFormatter = makeFormatter("d MMM")
    private static let dayMonthYearFormatter = makeFormatter("d MMM yyyy")
    private static let monthYearFormatter = makeFormatter("MMM yyyy")
    private static let monthNameYearFormatter = makeFormatter("MMMM yyyy")
    private static let monthShortFormatter = makeFormatter("MMM")
    private static let yearFormatter = makeFormatter("yyyy")

    static func dayMonth(_ date: Date) -> String { dayMonthFormatter.string(from: date) }          // "27 Oct"
    static func dayMonthYear(_ date: Date) -> String { dayMonthYearFormatter.string(from: date) }  // "27 Oct 2026"
    static func monthYear(_ date: Date) -> String { monthYearFormatter.string(from: date) }        // "Oct 2026"
    static func monthNameYear(_ date: Date) -> String { monthNameYearFormatter.string(from: date) } // "October 2026"
    static func monthShort(_ date: Date) -> String { monthShortFormatter.string(from: date) }      // "Oct"
    static func year(_ date: Date) -> String { yearFormatter.string(from: date) }                  // "2026"

    // Monday = 0 ... Sunday = 6
    static func weekdayIndex(_ date: Date) -> Int {
        (ProgressPeriodBuilder.calendar.component(.weekday, from: date) + 5) % 7
    }

    // "Mon", "Tue"...
    static func weekdayShort(_ index: Int) -> String {
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return names[index % names.count]
    }

    // A weight in kg without useless decimals: 20 stays "20", 2.5 stays "2.5"
    static func kg(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        }
        return String(format: "%.1f", value)
    }

    // "Today", "1 day ago", "10 days ago"
    static func daysAgo(from date: Date) -> String {
        let days = ProgressPeriodBuilder.daysBetween(
            ProgressPeriodBuilder.startOfDay(date),
            ProgressPeriodBuilder.today()
        )
        if days <= 0 { return "Today" }
        if days == 1 { return "1 day ago" }
        return "\(days) days ago"
    }
}
