//
//  RecoveryPlanner.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - Rest between the sessions
// Two sessions that train the same muscle need 48 hours between them. The user picks the days
// in "Edit your week"; here we check them. The weekdays are the ones of the app:
// 1 = Sunday, 2 = Monday ... 7 = Saturday.
enum RecoveryPlanner {

    // Monday first: Monday = 0 ... Sunday = 6
    private static func mondayFirst(_ weekdays: [Int]) -> [Int] {
        var result: [Int] = []
        for weekday in weekdays {
            let position = (weekday + 5) % 7
            if !result.contains(position) { result.append(position) }
        }
        return result.sorted()
    }

    // MARK: Problems of the chosen days (only warnings, they never block)
    static func scheduleIssues(weekdays: [Int]) -> [String] {
        let days = mondayFirst(weekdays)
        if days.isEmpty { return [] }
        var issues: [String] = []

        if 7 - days.count < SafetyRules.minRestDays {
            issues.append("Less than \(SafetyRules.minRestDays) rest days a week.")
        }

        // The longest run of days in a row (the week is a circle: Sunday is followed by Monday)
        let sequence = days + days.map { $0 + 7 }
        var run = 1
        var best = 1
        for index in 1..<sequence.count {
            if sequence[index] - sequence[index - 1] == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, min(run, days.count))
        }
        if best > SafetyRules.maxConsecutiveDays {
            issues.append("More than \(SafetyRules.maxConsecutiveDays) training days in a row.")
        }
        return issues
    }

    // MARK: Pairs of training days that are one next to the other
    // The numbers are positions in the list of training days (0 = the first one of the week).
    private static func adjacentPairs(_ days: [Int]) -> [(Int, Int)] {
        var pairs: [(Int, Int)] = []
        if days.count < 2 { return pairs }
        for index in days.indices {
            let nextIndex = (index + 1) % days.count
            let gap = ((days[nextIndex] - days[index]) % 7 + 7) % 7
            if gap == 1 { pairs.append((index, nextIndex)) }
        }
        return pairs
    }

    // The muscles a day trains. The core is not counted: it recovers quickly. ESTIMATE
    private static func keys(of day: SplitDay) -> [String] {
        var result: [String] = []
        for slot in day.slots where slot.group != "Core" {
            if !result.contains(slot.key) { result.append(slot.key) }
        }
        return result
    }

    // True when two days train the same muscle (the same key, or a whole group and a part of it)
    private static func overlap(_ first: [String], _ second: [String]) -> Bool {
        for x in first {
            for y in second {
                if x == y { return true }
                let groupX = x.split(separator: ":").first.map(String.init) ?? x
                let groupY = y.split(separator: ":").first.map(String.init) ?? y
                let oneIsWholeGroup = !x.contains(":") || !y.contains(":")
                if groupX == groupY && oneIsWholeGroup && groupX != "Arms" { return true }
            }
        }
        return false
    }

    private static func respectsRecovery(_ option: SplitOption, days: [Int]) -> Bool {
        for pair in adjacentPairs(days) {
            if pair.0 >= option.days.count || pair.1 >= option.days.count { continue }
            if overlap(keys(of: option.days[pair.0]), keys(of: option.days[pair.1])) {
                return false
            }
        }
        return true
    }

    // MARK: The split to use
    // Keeps the style the user wants. It changes the style only if the chosen days do not give
    // 48 hours of rest, and it says so.
    static func chooseStyle(daysPerWeek: Int, preferred: SplitStyle?,
                            weekdays: [Int]) -> (style: SplitStyle, notice: String?) {
        let options = PlanSplits.options(forDays: daysPerWeek)
        var chosen = options[0]
        if let preferred = preferred, let found = options.first(where: { $0.style == preferred }) {
            chosen = found
        }

        let days = mondayFirst(weekdays)
        if days.isEmpty { return (chosen.style, nil) }
        if respectsRecovery(chosen, days: days) { return (chosen.style, nil) }

        for option in options where option.style != chosen.style {
            if respectsRecovery(option, days: days) {
                return (option.style, SafetyRules.noticeSplitChanged)
            }
        }
        return (chosen.style, SafetyRules.noticeDaysClose)
    }
}
