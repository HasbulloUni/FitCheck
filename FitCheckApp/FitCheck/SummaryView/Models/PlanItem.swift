//
//  PlanItem.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// MARK: - The data of one plan
// Only data, no logic. Later it will come from the plans created by the user.
// A plan is one training DAY: legs, chest, shoulders + legs, full body...
// Each plan has its own color, chosen by the user when the plan is created.
struct PlanItem: Identifiable {
    let id: UUID
    let name: String          // e.g. "Legs" or "Full body"
    let icon: String          // SF Symbol of the plan, e.g. "figure.run"
    let color: Color          // the color of this plan
    let exerciseCount: Int    // e.g. 11
    let minutes: Int          // 60 or 90 (EditWeekRules.durations)

    // The ids of the exercises of the day (from the database), in order
    var exerciseIds: [String] = []
    // The position of the color in PlanPalette.colors: it tells which colors are taken
    var colorIndex: Int? = nil
    // The sets of each exercise, in the same order as exerciseIds
    var exerciseSets: [Int] = []
    // The 1 or 2 warm-up moves picked by the user
    var warmupMoves: [String] = []
    // False when the user switched the cool-down off
    var hasCooldown = true
    // False when the user switched the warm-up off
    var hasWarmup = true

    // The summary shown under the name, e.g. "11 exercises · 60 min"
    var details: String {
        "\(exerciseCount) exercises · \(minutes) min"
    }
}
