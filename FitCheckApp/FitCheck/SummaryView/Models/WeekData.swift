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
    case today          // today, not decided yet (no workout and no rest day): black dashed circle
    case todayWorkout   // today is a training day: green dashed circle
    case todayRest      // today is a rest day: purple dashed circle
    case planned    // scheduled workout (future): filled gray circle
    case upcoming   // every other day: outline only

    // True for the three "today" states
    var isToday: Bool {
        self == .today || self == .todayWorkout || self == .todayRest
    }
}

// MARK: - A day to display
// Data only, no logic.
struct WeekDay: Identifiable {
    let id = UUID()
    let letter: String   // "M", "T", "W"...
    let date: Date       // the actual date
    let state: DayState  // how it should be drawn
    var colorIndex: Int? = nil   // for a day done: the color of the plan (position in PlanPalette.colors)

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
    // The days of the completed workouts and the color of each plan: the same position in the two arrays
    // goes together (sessionDays[0] has the color sessionColorIndexes[0])
    var sessionDays: [Date] = []
    var sessionColorIndexes: [Int] = []
    // Rest days already recorded (dates at midnight)
    var restDays: [Date] = []
    // The current day
    var today: Date = .now
    // True when a plan was sent with "Go" today: today is a training day even if the routine says rest
    var hasGoToday = false

    // The days chosen BEFORE the last change. They are used for the days before
    // "ruleStartDate", so the past never changes when the user edits the week.
    var previousPlannedWeekdays: [Int] = []
    var previousRestWeekdays: [Int] = []
    // The day (at midnight) from which the current days are valid: nil until the first change
    var ruleStartDate: Date? = nil

    // Saves a new choice of training days. It is valid from today on (today included).
    mutating func changeWeek(plannedWeekdays newPlanned: [Int]) {
        let todayStart = Calendar.current.startOfDay(for: today)

        // The old choice is kept for the past. If the user changes the week twice in the
        // same day, the choice kept is still the one of before that day.
        if ruleStartDate != todayStart {
            previousPlannedWeekdays = plannedWeekdays
            previousRestWeekdays = restWeekdays
        }
        ruleStartDate = todayStart

        plannedWeekdays = newPlanned
        // Rest days are all the other days (Monday first, 1 = Sunday)
        restWeekdays = [2, 3, 4, 5, 6, 7, 1].filter { !newPlanned.contains($0) }
    }

    // Empties the week from today on (today included). The old choice is kept for the past,
    // exactly like in changeWeek, so the days before today never change.
    mutating func resetWeek() {
        let todayStart = Calendar.current.startOfDay(for: today)
        if ruleStartDate != todayStart {
            previousPlannedWeekdays = plannedWeekdays
            previousRestWeekdays = restWeekdays
        }
        ruleStartDate = todayStart
        plannedWeekdays = []
        restWeekdays = []
    }

    // The training weekdays that were valid on a date: days before "ruleStartDate"
    // keep the old choice, from "ruleStartDate" on the current choice is used.
    func plannedWeekdays(on date: Date) -> [Int] {
        let day = Calendar.current.startOfDay(for: date)
        if let start = ruleStartDate, day < start {
            return previousPlannedWeekdays
        }
        return plannedWeekdays
    }

    // Builds the 7 days of a week, Monday through Sunday.
    // weekOffset: 0 = the week containing "today", 1 = the next one, and so on.
    func days(weekOffset: Int = 0) -> [WeekDay] {
        var cal = Calendar.current
        cal.firstWeekday = 2   // the week always starts on Monday

        // The Monday of the week that contains today
        guard let thisMonday = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }
        // Move forward by whole weeks
        guard let start = cal.date(byAdding: .day, value: 7 * weekOffset, to: thisMonday) else { return [] }

        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        let todayStart = cal.startOfDay(for: today)

        var result: [WeekDay] = []
        for (offset, letter) in letters.enumerated() {
            // Monday + offset days = the date of this day
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else { continue }

            // Which day of the week it is (1 = Sunday ... 7 = Saturday)
            let weekday = cal.component(.weekday, from: date)

            let dayState = state(of: date, weekday: weekday, todayStart: todayStart)
            let item = WeekDay(
                letter: letter,
                date: date,
                state: dayState,
                colorIndex: dayState == .done ? planColorIndex(on: date) : nil
            )
            result.append(item)
        }

        return result
    }

    // The color of the plan done on this day (the last one if there are two), nil if it is not known
    private func planColorIndex(on date: Date) -> Int? {
        let day = Calendar.current.startOfDay(for: date)
        guard let position = sessionDays.lastIndex(of: day),
              sessionColorIndexes.indices.contains(position) else { return nil }
        return sessionColorIndexes[position]
    }

    // The state of a day: the first check that matches wins.
    private func state(of date: Date, weekday: Int, todayStart: Date) -> DayState {
        let day = Calendar.current.startOfDay(for: date)

        // Days before the last change keep the choice that was valid then
        var planned = plannedWeekdays(on: day)
        var rest = restWeekdays
        if let start = ruleStartDate, day < start {
            rest = previousRestWeekdays
        }

        if day == todayStart {
            // A workout finished today: the circle of today turns green
            if completedDays.contains(day) {
                return .done
            }
            if hasGoToday {
                return .todayWorkout
            }
            // Today keeps the dashed circle, but its color tells if it is a training or a rest day
            if planned.contains(weekday) {
                return .todayWorkout
            }
            if rest.contains(weekday) || restDays.contains(day) {
                return .todayRest
            }
            return .today
        }
        if completedDays.contains(day) {
            return .done
        }
        if day > todayStart && planned.contains(weekday) {
            return .planned
        }
        // A rest day turns purple only when its day has come: future rest days stay outlined
        if restDays.contains(day) || (day < todayStart && rest.contains(weekday)) {
            return .rest
        }
        return .upcoming
    }
}
