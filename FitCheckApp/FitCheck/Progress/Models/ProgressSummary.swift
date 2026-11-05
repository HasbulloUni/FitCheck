//
//  ProgressSummary.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// MARK: - The numbers of the Progress screen
// Only data, no logic. ProgressStatsBuilder fills them from the saved sessions.

// A slice of the "Sessions" donut: how many times a plan was done
struct PlanSlice: Identifiable {
    let id: String          // id of the plan
    let name: String
    let colorIndex: Int
    let count: Int

    // The color of the plan
    var color: Color {
        PlanPalette.colors[colorIndex % PlanPalette.colors.count]
    }
}

// The sets done for one muscle group in the period
struct MuscleSets: Identifiable {
    let group: MuscleGroup
    let sets: Int

    var id: String { group.rawValue }
}

// A weight increase: the weight the first time in the period and the last time
struct LoadGain: Identifiable {
    let id: String          // id of the exercise
    let name: String
    let fromKg: Double
    let toKg: Double

    var gainKg: Double { toKg - fromKg }
}

// The heaviest weight of an exercise in the period (used when there are no increases yet)
struct LoadTop: Identifiable {
    let id: String          // id of the exercise
    let name: String
    let kg: Double
}

// One state of the number stack (the card you swipe left and right)
struct StackNumber: Identifiable {
    let id: Int
    let title: String       // e.g. "Average session"
    let value: String       // e.g. "48"
    let unit: String        // e.g. "min" (can be empty)
    let detail: String      // e.g. "13 sessions"
}

// One bar of the wheel in "Choose a period"
struct PeriodWheelItem: Identifiable {
    let id: Int             // position in the list
    let label: String       // e.g. "Nov"
    let minutes: Int
}

// The photos of one month, for the gallery
struct PhotoGroup: Identifiable {
    let id: String          // e.g. "October 2026"
    let title: String
    let photos: [PhotoRecord]
}

// Everything the screen shows for the chosen period
struct ProgressSummary {
    let sessionCount: Int
    let minutes: Int
    let planSlices: [PlanSlice]
    let muscleSets: [MuscleSets]     // always the 6 groups, in the same order
    let mostMuscle: MuscleSets?      // nil when no set was done
    let leastMuscle: MuscleSets?
    let loadGains: [LoadGain]        // only the biggest increases (3 at most)
    let numbers: [StackNumber]       // the states of the number stack
    var topLoads: [LoadTop] = []     // the 3 heaviest weights of the period (shown when there is no increase yet)
}
