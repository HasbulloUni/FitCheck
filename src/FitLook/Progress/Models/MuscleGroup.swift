//
//  MuscleGroup.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - The 6 muscle groups shown in "Muscle balance"
// The exercise database has many muscles (lats, quadriceps...): here they become 6 groups.
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest
    case back
    case legs
    case shoulders
    case arms
    case core

    var id: String { rawValue }

    // Name shown on the screen, e.g. "Chest"
    var title: String { rawValue.capitalized }

    // The group of a muscle of the database (nil if the muscle is not counted)
    init?(databaseMuscle: String) {
        switch databaseMuscle.lowercased() {
        case "chest":
            self = .chest
        case "lats", "middle back", "lower back", "traps":
            self = .back
        case "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors":
            self = .legs
        case "shoulders", "neck":
            self = .shoulders
        case "biceps", "triceps", "forearms":
            self = .arms
        case "abdominals":
            self = .core
        default:
            return nil
        }
    }
}
