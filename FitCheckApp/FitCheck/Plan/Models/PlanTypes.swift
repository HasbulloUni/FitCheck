//
//  PlanTypes.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The choices of the user
// Only data. The numbers of each goal and level are here, close to the name.

enum PlanGoal: String, CaseIterable, Identifiable {
    case strength
    case tone
    case endurance

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    // Repetitions (min, max) for a compound or an isolation exercise. ESTIMATE
    func reps(isCompound: Bool) -> (min: Int, max: Int) {
        switch self {
        case .strength: return isCompound ? (5, 8) : (8, 12)
        case .tone: return isCompound ? (10, 12) : (12, 15)
        case .endurance: return (15, 20)
        }
    }

    // Rest between sets, in seconds. ESTIMATE
    func restSeconds(isCompound: Bool) -> Int {
        switch self {
        case .strength: return isCompound ? 120 : 75
        case .tone: return isCompound ? 75 : 60
        case .endurance: return isCompound ? 45 : 30
        }
    }
}

enum PlanLevel: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    // The levels of the exercise database this user can get. "expert" is never used.
    var allowedExerciseLevels: [String] {
        self == .easy ? ["beginner"] : ["beginner", "intermediate"]
    }

    // The preferred level of the exercises (the highest allowed one)
    var preferredExerciseLevel: String { allowedExerciseLevels.last ?? "beginner" }

    // Sets for each exercise: never less than 3 (the first set teaches the movement). ESTIMATE
    var sets: Int { self == .hard ? 4 : 3 }

    // Easy has 2 reps less (never below SafetyRules.easyMinReps)
    var repShift: Int { self == .easy ? -2 : 0 }

    var loadText: String {
        switch self {
        case .easy: return "light: learn the movement"
        case .medium: return "moderate: the last reps are hard but clean"
        case .hard: return "heavy: the last reps are close to the limit"
        }
    }

    // How far from failure the user must stop. No set is ever to failure.
    var effortText: String {
        switch self {
        case .easy: return "Stop with 3-4 reps still in the tank"
        case .medium: return "Stop with 2-3 reps still in the tank"
        case .hard: return "Stop with 1-2 reps still in the tank"
        }
    }
}

// MARK: - The exercise as the generator sees it
// A plain copy of the data: the generator does not need SwiftData.
struct CatalogItem: Identifiable {
    let id: String
    let name: String
    let level: String           // "beginner" or "intermediate"
    let mechanic: String        // "compound", "isolation" or ""
    let force: String           // "static", "push", "pull" or ""
    let equipment: String       // "Barbell", "Dumbbell", "Bodyweight"...
    let muscle: String          // the main muscle, e.g. "quadriceps"
    let group: String           // "Legs", "Chest", "Back", "Shoulders", "Arms", "Core", "Glutes"
    let variants: [String: String]   // name to show for easy / medium / hard (calisthenics only)
    let needsBar: Bool          // needs a pull-up bar or similar
}

// A stretching exercise, used in the cool-down
struct StretchItem {
    let id: String
    let name: String
    let muscle: String
}

// Everything the generator needs from the database
struct ExerciseCatalog {
    let items: [CatalogItem]
    let stretches: [StretchItem]
}

// MARK: - The result: a plan with three parts for each day

struct PlannedExercise: Identifiable {
    var id: String          // id of the exercise in the database
    let name: String
    let equipment: String
    let muscle: String
    let group: String
    let isCompound: Bool
    let slotKey: String
    let sets: Int
    let repsMin: Int?       // nil for static exercises
    let repsMax: Int?
    let holdSeconds: Int?   // only for static exercises
    let restSeconds: Int
    let loadText: String?   // nil for static exercises
    let effortText: String
}

struct ApproachSet {
    let exerciseName: String
    let loadShare: Double   // 0.5 = half of the working load
    let reps: String
}

struct WarmupPart {
    let minutes: Double
    let generalName: String
    let generalMinutes: Int
    let mobility: [String]
    let approachSets: [ApproachSet]
    let canSkip = false     // the warm-up can never be skipped
}

struct StretchStep {
    let name: String
    let muscle: String
    let holdSeconds: Int
}

struct CooldownPart {
    let minutes: Double
    let walkMinutes: Int
    let stretches: [StretchStep]
    let canSkip = true      // the cool-down can be skipped with one tap
}
