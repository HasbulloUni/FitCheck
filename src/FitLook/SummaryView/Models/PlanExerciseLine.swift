//
//  PlanExerciseLine.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import Foundation

// MARK: - One line of the dropdown of a plan in My plans
// Only data, no logic: the name on the left and the sets x reps on the right.
struct PlanExerciseLine: Identifiable {
    let id: String             // position + exercise id, so the same exercise twice still has two ids
    let name: String           // e.g. "Goblet squat"
    let setsRepsText: String   // e.g. "3 × 8-12" (or "3 × 30 s" for a static exercise)
}
