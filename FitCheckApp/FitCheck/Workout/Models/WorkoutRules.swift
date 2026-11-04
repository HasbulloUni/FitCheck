//
//  WorkoutRules.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - The numbers of the workout screen in one place
// To change a rule, change it here.
enum WorkoutRules {
    static let defaultReps = 10            // first value of the reps of a new set
    static let minReps = 1
    static let maxReps = 50

    static let weightStep = 2.5            // kg for each tap on + or -
    static let maxWeight = 300.0

    static let restSeconds = 90            // rest after a set
    static let restExtraSeconds = 15       // the "+15 s" button

    static let warmupMoveSeconds = 60      // a warm-up move (arm circles...)
    static let treadmillSeconds = 8 * 60   // Walking Treadmill: 8 minutes (it can go to 10)
    static let cooldownSeconds = 5 * 60    // the stretching at the end
}
