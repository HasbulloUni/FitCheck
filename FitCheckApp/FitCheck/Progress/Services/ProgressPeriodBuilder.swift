//
//  ProgressPeriodBuilder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - The calendar maths of the periods
// Builds the periods (this week, last month, this year...), the previous period used for the
// comparison, and the texts shown in the capsule and in the wheel.
enum ProgressPeriodBuilder {

    // MARK: Calendar

    // Gregorian calendar where the week starts on Monday
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return calendar
    }()

    static func today() -> Date {
        calendar.startOfDay(for: .now)
    }

    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    static func addDays(_ date: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func addMonths(_ date: Date, _ months: Int) -> Date {
        calendar.date(byAdding: .month, value: months, to: date) ?? date
    }

    static func isSameDay(_ first: Date, _ second: Date) -> Bool {
        calendar.isDate(first, inSameDayAs: second)
    }

    // Days from one day to another (both are the start of a day)
    static func daysBetween(_ start: Date, _ end: Date) -> Int {
        calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    // The first day of the month of a date
    static func monthStart(of date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? date
    }

    // MARK: Periods

    // How many bars the wheel has for each unit (the current one is the last)
    static func wheelCount(for unit: ProgressUnit) -> Int {
        switch unit {
        case .week:    return 26
        case .month:   return 18
        case .quarter: return 8
        case .year:    return 3
        case .custom:  return 0
        }
    }

    // The periods of the wheel, from the oldest to the current one
    static func periods(unit: ProgressUnit) -> [ProgressPeriod] {
        let count = wheelCount(for: unit)
        return (0..<count).reversed().map { period(unit: unit, offset: -$0) }
    }

    // One period: offset 0 is the current one, -1 the one before, and so on
    static func period(unit: ProgressUnit, offset: Int) -> ProgressPeriod {
        let now = today()
        let start: Date
        let naturalEnd: Date

        switch unit {
        case .week:
            let monday = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            start = addDays(monday, 7 * offset)
            naturalEnd = addDays(start, 6)
        case .month:
            start = addMonths(monthStart(of: now), offset)
            naturalEnd = addDays(addMonths(start, 1), -1)
        case .quarter:
            start = addMonths(quarterStart(of: now), 3 * offset)
            naturalEnd = addDays(addMonths(start, 3), -1)
        case .year:
            let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
            start = addMonths(yearStart, 12 * offset)
            naturalEnd = addDays(addMonths(start, 12), -1)
        case .custom:
            start = now
            naturalEnd = now
        }
        return makePeriod(unit: unit, start: start, naturalEnd: naturalEnd)
    }

    // A period chosen with the calendar: the two days can be in any order
    static func custom(from first: Date, to second: Date) -> ProgressPeriod {
        makePeriod(unit: .custom, start: min(first, second), naturalEnd: max(first, second))
    }

    // The period to compare with.
    // Finished period: the whole previous one (this week against the week before).
    // Period still going (e.g. 4 days of November): only the same number of days of the previous one,
    // so a new month is not always "worse" than the full month before.
    static func previous(of period: ProgressPeriod) -> ProgressPeriod {
        let start: Date
        let naturalEnd: Date

        switch period.unit {
        case .week:
            start = addDays(period.start, -7)
            naturalEnd = addDays(start, 6)
        case .month:
            start = addMonths(period.start, -1)
            naturalEnd = addDays(period.start, -1)
        case .quarter:
            start = addMonths(period.start, -3)
            naturalEnd = addDays(period.start, -1)
        case .year:
            start = addMonths(period.start, -12)
            naturalEnd = addDays(period.start, -1)
        case .custom:
            start = addDays(period.start, -period.dayCount)
            naturalEnd = addDays(period.start, -1)
        }

        let end: Date
        if period.isInProgress {
            end = min(addDays(start, period.dayCount - 1), naturalEnd)
        } else {
            end = naturalEnd
        }
        return ProgressPeriod(
            unit: period.unit,
            start: start,
            end: end,
            naturalEnd: naturalEnd,
            dayCount: daysBetween(start, end) + 1
        )
    }

    // True when the day is inside the period
    static func contains(_ period: ProgressPeriod, _ date: Date) -> Bool {
        date >= period.start && date < addDays(period.end, 1)
    }

    // MARK: Texts

    // The text of the capsule, e.g. "Nov 2026" or "27 Oct – 2 Nov"
    static func title(of period: ProgressPeriod) -> String {
        switch period.unit {
        case .week:
            return "\(ProgressFormat.dayMonth(period.start)) – \(ProgressFormat.dayMonth(period.end))"
        case .month:
            return ProgressFormat.monthYear(period.start)
        case .quarter:
            return "\(ProgressFormat.monthShort(period.start)) – \(ProgressFormat.monthShort(period.naturalEnd)) \(ProgressFormat.year(period.start))"
        case .year:
            return ProgressFormat.year(period.start)
        case .custom:
            let thisYear = ProgressFormat.year(today())
            let showYear = ProgressFormat.year(period.end) != thisYear || ProgressFormat.year(period.start) != thisYear
            let first = showYear ? ProgressFormat.dayMonthYear(period.start) : ProgressFormat.dayMonth(period.start)
            if isSameDay(period.start, period.end) { return first }
            let last = showYear ? ProgressFormat.dayMonthYear(period.end) : ProgressFormat.dayMonth(period.end)
            return "\(first) – \(last)"
        }
    }

    // The small text under a bar of the wheel, e.g. "27 Oct" or "Nov"
    static func wheelLabel(of period: ProgressPeriod) -> String {
        switch period.unit {
        case .week:
            return ProgressFormat.dayMonth(period.start)
        case .month:
            return ProgressFormat.monthShort(period.start)
        case .quarter:
            return "\(ProgressFormat.monthShort(period.start))–\(ProgressFormat.monthShort(period.naturalEnd))"
        case .year:
            return ProgressFormat.year(period.start)
        case .custom:
            return ""
        }
    }

    // MARK: Calendar of the custom range

    // The cells of a month: empty cells (nil) before the 1st so the days start under the right weekday
    static func calendarCells(for month: Date) -> [Date?] {
        let first = monthStart(of: month)
        let dayCount = calendar.range(of: .day, in: .month, for: first)?.count ?? 30
        let weekdayIndex = ProgressFormat.weekdayIndex(first)   // Monday = 0
        var cells: [Date?] = Array(repeating: nil, count: weekdayIndex)
        for day in 0..<dayCount {
            cells.append(addDays(first, day))
        }
        return cells
    }

    // MARK: Small helpers

    private static func quarterStart(of date: Date) -> Date {
        let month = calendar.component(.month, from: date)
        let firstMonthOfQuarter = ((month - 1) / 3) * 3 + 1
        var parts = calendar.dateComponents([.year], from: date)
        parts.month = firstMonthOfQuarter
        parts.day = 1
        return calendar.date(from: parts) ?? date
    }

    private static func makePeriod(unit: ProgressUnit, start: Date, naturalEnd: Date) -> ProgressPeriod {
        let end = min(naturalEnd, today())
        return ProgressPeriod(
            unit: unit,
            start: start,
            end: end,
            naturalEnd: naturalEnd,
            dayCount: max(daysBetween(start, end) + 1, 1)
        )
    }
}
