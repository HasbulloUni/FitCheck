//
//  ReadyMadeProgram.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - The ready-made plans, as they are written in ReadyMadePrograms.json
// Only data. 24 programs: 3 levels x 4 frequencies (2-5 days) x 2 styles = 84 plans.
// Readable list of the same plans: /plan/schede-prefatte.md in the project files.

// The level of the user for the ready-made plans
enum ReadyMadeLevel: String, CaseIterable, Identifiable, Codable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

// The whole file
struct ReadyMadeFile: Codable {
    let programs: [ReadyMadeProgram]
}

// One program: the plans for one level, one number of days and one style
struct ReadyMadeProgram: Codable {
    let level: ReadyMadeLevel
    let days: Int                    // 2, 3, 4 or 5
    let style: String                // "fullBody" or "muscleGroups" (ReadyMadeStyle.rawValue)
    let plans: [ReadyMadePlan]       // one plan for each training day, in rotation order
}

// One plan (one training day)
struct ReadyMadePlan: Codable {
    let name: String                 // e.g. "Full body A", "Push", "Upper B"
    let icon: String                 // SF Symbol
    let minutes: Int                 // sum of warm-up + sets x (work + rest) of each exercise + cool-down, same formula as Add plan
    let warmup: [String]             // exercise ids: the treadmill walk + 2 mobility moves
    let exercises: [ReadyMadeExercise]
}

// One exercise of the main part
struct ReadyMadeExercise: Codable {
    let id: String                   // id of exercises.json
    let sets: Int                    // never more than 4
    let reps: String                 // e.g. "10-12" or "30 s" (shown in the list, not saved yet)
}
