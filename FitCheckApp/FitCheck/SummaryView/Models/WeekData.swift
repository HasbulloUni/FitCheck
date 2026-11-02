//
//  WeekData.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// MARK: - State of a day
// Decides how the circle is drawn.
enum DayState {
    case done       // workout done: green circle
    case rest       // rest day: purple circle
    case today      // today: dashed circle
    case planned    // scheduled workout (future): filled gray circle
    case upcoming   // every other day: outline only
}

// MARK: - A day to display
// Data only, no logic.
struct WeekDay: Identifiable {
    let id = UUID()
    let letter: String   // "M", "T", "W"...
    let date: Date       // the actual date
    let state: DayState  // how it should be drawn

    // The day of the month (e.g. 29), written inside the circle.
    var number: Int {
        Calendar.current.component(.day, from: date)
    }
}

// MARK: - Week data
// Starts empty: the only thing it has is "today".
struct WeekData {
    // Training days chosen by the user (1 = Sunday, 2 = Monday ... 7 = Saturday)
    var plannedWeekdays: [Int] = []
    // Rest days chosen by the user (same numbers)
    var restWeekdays: [Int] = []
    // Completed workouts (dates at midnight)
    var completedDays: [Date] = []
    // Rest days already recorded (dates at midnight)
    var restDays: [Date] = []
    // The current day
    var today: Date = .now

    // Builds the 7 days of the week containing "today", Monday through Sunday.
    func days() -> [WeekDay] {
        var cal = Calendar.current
        cal.firstWeekday = 2   // the week always starts on Monday

        // The Monday of the week that contains today
        guard let start = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }

        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        let todayStart = cal.startOfDay(for: today)

        var result: [WeekDay] = []
        for (offset, letter) in letters.enumerated() {
            // Monday + offset days = the date of this day
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else { continue }

            // Which day of the week it is (1 = Sunday ... 7 = Saturday)
            let weekday = cal.component(.weekday, from: date)

            let item = WeekDay(
                letter: letter,
                date: date,
                state: state(of: date, weekday: weekday, todayStart: todayStart)
            )
            result.append(item)
        }

        return result
    }

    // The state of a day: the first check that matches wins.
    private func state(of date: Date, weekday: Int, todayStart: Date) -> DayState {
        let day = Calendar.current.startOfDay(for: date)

        if day == todayStart {
            return .today
        }
        if completedDays.contains(day) {
            return .done
        }
        if day > todayStart && plannedWeekdays.contains(weekday) {
            return .planned
        }
        if restWeekdays.contains(weekday) || restDays.contains(day) {
            return .rest
        }
        return .upcoming
    }
}
