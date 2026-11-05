//
//  GoalRules.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The numbers of the goals
// The targets of Sessions, Minutes and Week active now come from the plan the user
// saved in Edit week (see GoalProgressBuilder). The fixed numbers below are only defaults.
enum GoalRules {

    // Minutes of a planned day that has no plan assigned yet
    static let defaultMinutesPerSession = 60

    // Week goals (Sessions and Minutes: not used as targets anymore, the targets come from the planned days)
    static let sessionsPerWeek = 3        // Sessions: workouts to complete
    static let minutesPerWeek = 180       // Minutes: minutes of training
    static let strengthDaysPerWeek = 2    // Strength days: ALWAYS the target, whatever the planned days

    // Month goals (weeksPerMonth is not used as a target anymore; muscleGroups still is)
    static let weeksPerMonth = 4          // Week active: weeks in which the plan was done
    static let muscleGroups = 6           // Muscle coverage: chest, back, legs, shoulders, arms, core

    // What makes a workout a "strength session" (all three must be true)
    /* UNUSED (commented out, 4 Nov 2026) static let strengthMinExercises = 3   // at least 3 strength exercises, each with one set done */
    /* UNUSED (commented out, 4 Nov 2026) static let strengthMinMinutes = 15    // at least 15 minutes long */
    // Also: the workout must be finished, and two workouts in the same day count as one day
}
