//
//  WorkoutStep.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - One step of a workout
// A workout is a list of steps in this order: warm-up moves, exercises, cool-down.
// Only data, no logic. The Views read it, the ViewModel moves from one step to the next.
struct WorkoutStep: Identifiable {

    enum Kind {
        case warmup
        case exercise
        case cooldown
    }

    let id: Int                  // position in the list (0, 1, 2...)
    let kind: Kind
    let exerciseId: String       // id of the exercise in the database ("" for the cool-down)
    let name: String             // e.g. "Back squat"
    let muscles: String          // e.g. "Legs · Quadriceps"
    let muscleGroup: String      // MuscleGroup raw value, e.g. "legs" ("" if not counted)
    let imagePaths: [String]     // photos of the exercise (the first one is shown)
    let instructions: [String]   // how to do it, one text for each step
    let setCount: Int            // sets of an exercise (0 for warm-up and cool-down)
    let durationSeconds: Int     // time of a warm-up or cool-down step (0 for exercises)

    // True for the steps done against the clock (no sets, no weight)
    var isTimed: Bool { kind != .exercise }
}
