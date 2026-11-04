//
//  PlanRecord.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation
import SwiftData

// MARK: - A plan saved with SwiftData
// PlanItem (the struct the Views use) keeps a SwiftUI Color, which SwiftData cannot save.
// This is the saved version: only plain data, with the color as colorIndex.
@Model
final class PlanRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorIndex: Int
    var exerciseCount: Int
    var minutes: Int
    var exerciseIds: [String]
    var exerciseSets: [Int]
    var warmupMoves: [String]
    var hasCooldown: Bool
    var hasWarmup: Bool

    init(from plan: PlanItem) {
        id = plan.id
        name = plan.name
        icon = plan.icon
        colorIndex = plan.colorIndex ?? 0
        exerciseCount = plan.exerciseCount
        minutes = plan.minutes
        exerciseIds = plan.exerciseIds
        exerciseSets = plan.exerciseSets
        warmupMoves = plan.warmupMoves
        hasCooldown = plan.hasCooldown
        hasWarmup = plan.hasWarmup
    }

    // Copies the latest values of a plan onto this saved row (used when the sets or the
    // exercises of a plan change after it was already saved)
    func update(from plan: PlanItem) {
        name = plan.name
        icon = plan.icon
        colorIndex = plan.colorIndex ?? 0
        exerciseCount = plan.exerciseCount
        minutes = plan.minutes
        exerciseIds = plan.exerciseIds
        exerciseSets = plan.exerciseSets
        warmupMoves = plan.warmupMoves
        hasCooldown = plan.hasCooldown
        hasWarmup = plan.hasWarmup
    }
}

extension PlanItem {
    // Rebuilds the plan the Views use from the saved row (the color comes back from colorIndex)
    init(from record: PlanRecord) {
        self.init(
            id: record.id,
            name: record.name,
            icon: record.icon,
            color: PlanPalette.colors[record.colorIndex],
            exerciseCount: record.exerciseCount,
            minutes: record.minutes,
            exerciseIds: record.exerciseIds,
            colorIndex: record.colorIndex,
            exerciseSets: record.exerciseSets,
            warmupMoves: record.warmupMoves,
            hasCooldown: record.hasCooldown,
            hasWarmup: record.hasWarmup
        )
    }
}
