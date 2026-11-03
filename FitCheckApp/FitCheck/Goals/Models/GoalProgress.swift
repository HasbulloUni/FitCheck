//
//  GoalProgress.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - What the user has done so far
// Only data, no logic. Everything starts at zero: the real numbers will come from the workouts.
struct GoalProgress {
    // This week
    var sessionsDone = 0        // finished workouts
    var minutesDone = 0         // minutes of training
    var strengthDaysDone = 0    // different days with a strength session

    // This month
    var weeksActive = 0         // weeks in which the plan was done
    var planWorkoutsDone = 0    // workouts of the plan completed
    var planWorkoutsPlanned = 0 // workouts of the plan planned
    var musclesCovered = 0      // muscle groups trained enough
}
