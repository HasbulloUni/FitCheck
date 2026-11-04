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
                centerText: "\(progress.sessionsDone)/\(GoalRules.sessionsPerWeek)",
                subtitle: toGoText(done: progress.sessionsDone, target: GoalRules.sessionsPerWeek),
                progress: fraction(progress.sessionsDone, GoalRules.sessionsPerWeek),
                color: AppColors.muscleBlue
            ),
            GoalItem(
                title: "Minutes",
                centerText: "\(progress.minutesDone)",
                subtitle: minutesText,
                progress: fraction(progress.minutesDone, GoalRules.minutesPerWeek),
                color: AppColors.greenSoft
            ),
            GoalItem(
                title: "Strength days",
                centerText: "\(progress.strengthDaysDone)/\(GoalRules.strengthDaysPerWeek)",
                subtitle: toGoText(done: progress.strengthDaysDone, target: GoalRules.strengthDaysPerWeek),
                progress: fraction(progress.strengthDaysDone, GoalRules.strengthDaysPerWeek),
                color: AppColors.musclePurple
            )
        ]
    }

    // The goals of the month, built from the progress
    var monthGoals: [GoalItem] {
        [
            GoalItem(
                title: "Week active",
                centerText: "\(progress.weeksActive)/\(GoalRules.weeksPerMonth)",
                subtitle: toGoText(done: progress.weeksActive, target: GoalRules.weeksPerMonth),
                progress: fraction(progress.weeksActive, GoalRules.weeksPerMonth),
                color: AppColors.muscleOrange
            ),
            GoalItem(
                title: "Plan completion",
                centerText: "\(planPercent)%",
                subtitle: planLeftText,
                progress: fraction(progress.planWorkoutsDone, progress.planWorkoutsPlanned),
                color: AppColors.muscleRed
            ),
            GoalItem(
                title: "Muscle coverage",
                centerText: "\(progress.musclesCovered)/\(GoalRules.muscleGroups)",
                subtitle: toGoText(done: progress.musclesCovered, target: GoalRules.muscleGroups),
                progress: fraction(progress.musclesCovered, GoalRules.muscleGroups),
                color: AppColors.muscleYellow
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
        let left = max(target - done, 0)
        if left == 0 { return "Reached" }
        return "\(left) to go"
    }

    // "95 min left" or "Reached"
    private var minutesText: String {
        let left = max(GoalRules.minutesPerWeek - progress.minutesDone, 0)
        if left == 0 { return "Reached" }
        return "\(left) min left"
    }

    // "6 left" or "Done": workouts of the plan still to do this month
    private var planLeftText: String {
        let left = max(progress.planWorkoutsPlanned - progress.planWorkoutsDone, 0)
        if progress.planWorkoutsPlanned > 0 && left == 0 { return "Done" }
        return "\(left) left"
    }

    // Percent of the plan completed, rounded
    private var planPercent: Int {
        Int((fraction(progress.planWorkoutsDone, progress.planWorkoutsPlanned) * 100).rounded())
    }
}
