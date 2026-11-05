//
//  WorkoutSummary.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - What the end screen shows
// Only data: it is built by SessionSaver when the workout ends.
struct WorkoutSummary {

    // The heaviest weight used for one exercise, and the one of the last time
    struct LoadLine: Identifiable {
        let id: String              // id of the exercise
        let name: String
        let weight: Double          // kg used today
        let previous: Double?       // kg of the last time (nil the first time)

        // Today minus the last time (nil the first time)
        var change: Double? {
            guard let previous else { return nil }
            return weight - previous
        }
    }

    let minutes: Int
    let setsDone: Int
    let exercisesDone: Int
    let exercisesTotal: Int
    let isCompleted: Bool           // true when every set of every exercise was done
    let loads: [LoadLine]
}
