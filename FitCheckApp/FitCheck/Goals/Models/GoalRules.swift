//
//  GoalRules.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The numbers of the goals
// Change a number here and the whole Goals screen follows.
enum GoalRules {

    // Week goals
    static let sessionsPerWeek = 3        // Sessions: workouts to complete
    static let minutesPerWeek = 180       // Minutes: minutes of training
    static let strengthDaysPerWeek = 2    // Strength days: days with a strength session

    // Month goals
    static let weeksPerMonth = 4          // Week active: weeks in which the plan was done
    static let muscleGroups = 6           // Muscle coverage: chest, back, legs, shoulders, arms, core

    // What makes a workout a "strength session" (all three must be true)
    /* UNUSED (commented out, 4 Nov 2026) static let strengthMinExercises = 3   // at least 3 strength exercises, each with one set done */
    /* UNUSED (commented out, 4 Nov 2026) static let strengthMinMinutes = 15    // at least 15 minutes long */
    // Also: the workout must be finished, and two workouts in the same day count as one day
}
