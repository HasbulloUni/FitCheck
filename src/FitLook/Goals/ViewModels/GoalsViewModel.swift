//
//  GoalsViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of the goals: it owns the data and the logic, the View only draws.
// Week goals: Sessions, Minutes, Strength days. Month goals: Week active, Plan completion, Muscle coverage.
// The goals are always these six. What changes is the progress, which starts at zero.
@Observable
final class GoalsViewModel {
    // What the user has done: starts at zero, the workouts will fill it
    var progress = GoalProgress()

    // The goals of the week, built from the progress
    var weekGoals: [GoalItem] {
        [
            GoalItem(
                title: "Sessions",
                centerText: "\(progress.sessionsDone)/\(progress.sessionsTarget)",
                subtitle: toGoText(done: progress.sessionsDone, target: progress.sessionsTarget),
                progress: fraction(progress.sessionsDone, progress.sessionsTarget)
            ),
            GoalItem(
                title: "Minutes",
                centerText: "\(progress.minutesDone)",
                subtitle: minutesText,
                progress: fraction(progress.minutesDone, progress.minutesTarget)
            ),
            GoalItem(
                title: "Strength days",
                centerText: "\(progress.strengthDaysDone)/\(progress.strengthDaysTarget)",
                subtitle: toGoText(done: progress.strengthDaysDone, target: progress.strengthDaysTarget),
                progress: fraction(progress.strengthDaysDone, progress.strengthDaysTarget)
            )
        ]
    }

    // The goals of the month, built from the progress
    var monthGoals: [GoalItem] {
        [
            GoalItem(
                title: "Week active",
                centerText: "\(percent(progress.weeksActive, progress.weeksActiveTarget))%",
                subtitle: "\(progress.weeksActive) of \(progress.weeksActiveTarget) weeks",
                progress: fraction(progress.weeksActive, progress.weeksActiveTarget)
            ),
            GoalItem(
                title: "Plan completion",
                centerText: "\(percent(progress.planWorkoutsDone, progress.planWorkoutsPlanned))%",
                subtitle: planLeftText,
                progress: fraction(progress.planWorkoutsDone, progress.planWorkoutsPlanned)
            ),
            GoalItem(
                title: "Muscle coverage",
                centerText: "\(percent(progress.musclesCovered, GoalRules.muscleGroups))%",
                subtitle: "\(progress.musclesCovered) of \(GoalRules.muscleGroups) muscles",
                progress: fraction(progress.musclesCovered, GoalRules.muscleGroups)
            )
        ]
    }

    // MARK: - Small helpers

    // Progress from 0 to 1. With a target of 0 it is 0, to avoid dividing by zero
    private func fraction(_ done: Int, _ target: Int) -> Double {
        if target <= 0 { return 0 }
        return min(Double(done) / Double(target), 1)
    }

    // Short text for the cards: "2 to go" or "Reached"
    private func toGoText(done: Int, target: Int) -> String {
        if target <= 0 { return "0 to go" }   // nothing planned
        let left = max(target - done, 0)
        if left == 0 { return "Reached" }
        return "\(left) to go"
    }

    // "95 min left" or "Reached"
    private var minutesText: String {
        if progress.minutesTarget <= 0 { return "0 min left" }   // nothing planned
        let left = max(progress.minutesTarget - progress.minutesDone, 0)
        if left == 0 { return "Reached" }
        return "\(left) min left"
    }

    // "6 left" or "Done": workouts of the plan still to do this month
    private var planLeftText: String {
        let left = max(progress.planWorkoutsPlanned - progress.planWorkoutsDone, 0)
        if progress.planWorkoutsPlanned > 0 && left == 0 { return "Done" }
        return "\(left) left"
    }

    // Percent from 0 to 100, rounded. Capped to 100, and 0 when the target is 0 (no NaN)
    private func percent(_ done: Int, _ target: Int) -> Int {
        Int((fraction(done, target) * 100).rounded())
    }
}
