// Types removed from PlanTypes.swift on 5 Nov 2026 because nothing uses them.
// Outside the Xcode project on purpose.

import Foundation

// The way the muscles are shared between the training days
enum SplitStyle: String, CaseIterable, Identifiable {
    case fullBody
    case upperLower
    case pushPullLegs
    case pushPullLegsUpperLower
    case bodyPart

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullBody: return "Full body"
        case .upperLower: return "Upper / Lower"
        case .pushPullLegs: return "Push / Pull / Legs"
        case .pushPullLegsUpperLower: return "Push / Pull / Legs + Upper / Lower"
        case .bodyPart: return "One muscle group per day"
        }
    }
}


// MARK: - A muscle of a training day
// "weight" says how much the muscle counts in the day. "types" is the kind of the 1st, 2nd,
// 3rd... exercise for this muscle (its length is the maximum for the muscle).
enum MoveType {
    case compound
    case isolation
}

struct MuscleSlot {
    let group: String
    let muscle: String?     // nil = the whole group
    let weight: Double
    let types: [MoveType]

    // The name used to count the sets of the week, e.g. "Chest" or "Arms:biceps"
    var key: String {
        if let muscle = muscle {
            return group + ":" + muscle
        }
        return group
    }
}

struct SplitDay {
    let label: String
    let slots: [MuscleSlot]
}

struct SplitOption {
    let style: SplitStyle
    let days: [SplitDay]
}


struct GeneratedDay: Identifiable {
    let id = UUID()
    let label: String
    let warmup: WarmupPart
    let exercises: [PlannedExercise]
    let cooldown: CooldownPart
    let centralMinutes: Double
    let skipped: [String]       // muscles that did not fit (for the team, not for the user)

    // Total time of the three parts, in minutes
    var estimatedMinutes: Int {
        Int((warmup.minutes + centralMinutes + cooldown.minutes).rounded())
    }
}


/* UNUSED (commented out, 4 Nov 2026)
struct GeneratedWeek {
    let days: [GeneratedDay]
    let weeklySets: [String: Int]   // sets of the week for each muscle key
    let weeklyCap: Int
    let style: SplitStyle
    let notices: [String]           // short messages for the user
    let isSimplified: Bool
    let violations: [String]        // empty = the plan respects every rule
}
*/
