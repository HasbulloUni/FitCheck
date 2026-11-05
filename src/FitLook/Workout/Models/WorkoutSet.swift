//
//  WorkoutSet.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - One set of an exercise
// The numbers the user sees and changes. isDone becomes true with "Complete set".
struct WorkoutSet: Codable {
    var reps: Int
    var weight: Double      // in kg, 0 means no weight (body only or not chosen yet)
    var isDone = false
}
