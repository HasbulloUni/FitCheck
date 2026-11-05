//
//  ProgressStatsBuilder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - From the saved sessions to the numbers of the screen
// Pure functions: they get the sessions and the period, and give back the numbers.
// A rest day is never counted as zero: only days with a workout are used in the averages.
enum ProgressStatsBuilder {

    // The sessions done inside a period
    static func sessions(in period: ProgressPeriod, from all: [SessionRecord]) -> [SessionRecord] {
        all.filter { ProgressPeriodBuilder.contains(period, $0.date) }
    }

    // Total minutes of a period (used by the bars of the wheel)
    static func minutes(in period: ProgressPeriod, from all: [SessionRecord]) -> Int {
        sessions(in: period, from: all).reduce(0) { $0 + $1.minutes }
    }

    // All the numbers of the screen for one period
    static func summary(sessions all: [SessionRecord], period: ProgressPeriod) -> ProgressSummary {
        let current = sessions(in: period, from: all)
        let totalMinutes = current.reduce(0) { $0 + $1.minutes }
        let previousMinutes = minutes(in: ProgressPeriodBuilder.previous(of: period), from: all)

        let muscles = muscleSets(from: current)
        let mostSets = muscles.map { $0.sets }.max() ?? 0
        let most = mostSets > 0 ? muscles.max(by: { $0.sets < $1.sets }) : nil
        let least = mostSets > 0 ? muscles.min(by: { $0.sets < $1.sets }) : nil

        return ProgressSummary(
            sessionCount: current.count,
            minutes: totalMinutes,
            planSlices: planSlices(from: current),
            muscleSets: muscles,
            mostMuscle: most,
            leastMuscle: least,
            loadGains: loadGains(from: current),
            numbers: numbers(
                current: current,
                minutes: totalMinutes,
                previousMinutes: previousMinutes,
                period: period
            ),
            topLoads: topLoads(from: current)
        )
    }

    // MARK: - Sessions per plan

    private static func planSlices(from list: [SessionRecord]) -> [PlanSlice] {
        var slices: [PlanSlice] = []
        for session in list {
            if let index = slices.firstIndex(where: { $0.id == session.planId }) {
                let old = slices[index]
                slices[index] = PlanSlice(id: old.id, name: old.name, colorIndex: old.colorIndex, count: old.count + 1)
            } else {
                slices.append(PlanSlice(id: session.planId, name: session.planName, colorIndex: session.colorIndex, count: 1))
            }
        }
        return slices.sorted { $0.count > $1.count }
    }

    // MARK: - Sets per muscle group

    private static func muscleSets(from list: [SessionRecord]) -> [MuscleSets] {
        MuscleGroup.allCases.map { group in
            var total = 0
            for session in list {
                for (index, name) in session.muscleNames.enumerated() where name == group.rawValue && index < session.muscleSets.count {
                    total += session.muscleSets[index]
                }
            }
            return MuscleSets(group: group, sets: total)
        }
    }

    // MARK: - Biggest weight increases
    // For each exercise: the weight the first time in the period against the last time.
    // Only increases count, and only the 3 biggest are kept.

    private static func loadGains(from list: [SessionRecord]) -> [LoadGain] {
        let ordered = list.sorted { $0.date < $1.date }
        var firstWeight: [String: Double] = [:]
        var lastWeight: [String: Double] = [:]
        var names: [String: String] = [:]
        var order: [String] = []

        for session in ordered {
            for (index, id) in session.loadExerciseIds.enumerated()
            where index < session.loadWeights.count && index < session.loadExerciseNames.count {
                let weight = session.loadWeights[index]
                if firstWeight[id] == nil {
                    firstWeight[id] = weight
                    order.append(id)
                }
                lastWeight[id] = weight
                names[id] = session.loadExerciseNames[index]
            }
        }

        var gains: [LoadGain] = []
        for id in order {
            if let from = firstWeight[id], let to = lastWeight[id], to > from {
                gains.append(LoadGain(id: id, name: names[id] ?? id, fromKg: from, toKg: to))
            }
        }
        return Array(gains.sorted { $0.gainKg > $1.gainKg }.prefix(3))
    }

    // MARK: - The heaviest weights
    // For each exercise: the heaviest weight of the period. The 3 heaviest are kept.
    // The card shows them while there are no increases yet (for example after the first workout).

    private static func topLoads(from list: [SessionRecord]) -> [LoadTop] {
        var heaviest: [String: Double] = [:]
        var names: [String: String] = [:]

        for session in list {
            for (index, id) in session.loadExerciseIds.enumerated()
            where index < session.loadWeights.count && index < session.loadExerciseNames.count {
                let weight = session.loadWeights[index]
                if weight > (heaviest[id] ?? 0) {
                    heaviest[id] = weight
                }
                names[id] = session.loadExerciseNames[index]
            }
        }

        let all = heaviest.map { LoadTop(id: $0.key, name: names[$0.key] ?? $0.key, kg: $0.value) }
        return Array(all.sorted { $0.kg > $1.kg }.prefix(3))
    }

    // MARK: - The number stack
    // 4 states: vs the previous period, average session, longest session, busiest day.

    private static func numbers(
        current: [SessionRecord],
        minutes: Int,
        previousMinutes: Int,
        period: ProgressPeriod
    ) -> [StackNumber] {

        // 1. Current period against the previous one (a subtraction of minutes)
        let versus: StackNumber
        let versusTitle = "Vs previous \(period.unit.previousWord)"
        if previousMinutes == 0 {
            versus = StackNumber(id: 0, title: versusTitle, value: "—", unit: "", detail: "No earlier data")
        } else {
            let difference = minutes - previousMinutes
            let percent = Int((Double(abs(difference)) / Double(previousMinutes) * 100).rounded())
            let sameDays = (period.isInProgress && period.unit != .custom) ? "same days " : ""
            if difference == 0 {
                versus = StackNumber(id: 0, title: versusTitle, value: "0", unit: "min", detail: "No change")
            } else {
                let sign = difference > 0 ? "+" : "−"
                let moreOrLess = difference > 0 ? "more" : "less"
                versus = StackNumber(
                    id: 0,
                    title: versusTitle,
                    value: "\(sign)\(abs(difference))",
                    unit: "min",
                    detail: "\(percent)% \(moreOrLess) than \(sameDays)\(period.unit.lastWord)"
                )
            }
        }

        // 2. Average session
        let average: StackNumber
        if current.isEmpty {
            average = StackNumber(id: 1, title: "Average session", value: "—", unit: "", detail: "No sessions")
        } else {
            let value = Int((Double(minutes) / Double(current.count)).rounded())
            average = StackNumber(id: 1, title: "Average session", value: "\(value)", unit: "min", detail: "\(current.count) sessions")
        }

        // 3. Longest session
        let longest: StackNumber
        if let session = current.max(by: { $0.minutes < $1.minutes }) {
            let day = "\(ProgressFormat.weekdayShort(ProgressFormat.weekdayIndex(session.date))) \(ProgressFormat.dayMonth(session.date))"
            longest = StackNumber(id: 2, title: "Longest session", value: "\(session.minutes)", unit: "min", detail: day)
        } else {
            longest = StackNumber(id: 2, title: "Longest session", value: "—", unit: "", detail: "No sessions")
        }

        // 4. Busiest day of the week
        var perWeekday = [Int](repeating: 0, count: 7)
        for session in current {
            perWeekday[ProgressFormat.weekdayIndex(session.date)] += 1
        }
        let busiest: StackNumber
        if let top = perWeekday.max(), top > 0, let index = perWeekday.firstIndex(of: top) {
            busiest = StackNumber(
                id: 3,
                title: "Busiest day",
                value: ProgressFormat.weekdayShort(index),
                unit: "",
                detail: "\(top) sessions on this day"
            )
        } else {
            busiest = StackNumber(id: 3, title: "Busiest day", value: "—", unit: "", detail: "No sessions")
        }

        return [versus, average, longest, busiest]
    }
}
