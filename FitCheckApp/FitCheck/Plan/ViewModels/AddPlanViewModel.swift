//
//  AddPlanViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of "Add your plan": one plan is one training DAY (legs, chest + back, full body...).
// The user names it, picks a category, a color, a length (60 or 90 min) and the exercises.
// The View only draws.
@Observable
final class AddPlanViewModel {

    // MARK: The choices of the user
    var name = ""                       // empty = the suggested name is used
    var colorIndex: Int                 // position in PlanPalette.colors
    var minutes = EditWeekRules.defaultDuration   // 60 or 90
    private(set) var category: PlanCategory = .gym
    private(set) var chosen: [CatalogItem] = []   // the exercises of the day, in the order picked
    var isPickerShown = false           // true while "Pick your exercises" is open

    // Goal and level are fixed for now (the plan is built by hand, not by the generator).
    // Medium: the picker shows beginner and intermediate exercises.
    let goal: PlanGoal = .tone
    let level: PlanLevel = .medium

    // The exercises copied from the database. It is built once.
    private var catalog: ExerciseCatalog? = nil

    init(takenColorIndexes: [Int]) {
        colorIndex = PlanPalette.firstFree(taken: takenColorIndexes)
    }

    // MARK: Database

    // True when the exercises of the database are ready
    var isCatalogReady: Bool { catalog != nil }

    // Called with the exercises saved in the database. It does nothing if they are already loaded
    // or if the database is still empty.
    func loadCatalog(from exercises: [Exercise]) {
        if catalog != nil || exercises.isEmpty { return }
        catalog = CatalogBuilder.build(from: exercises)
    }

    // The safe exercises the user can pick for this category
    var pool: [CatalogItem] {
        guard let catalog = catalog else { return [] }
        return ExercisePool.filter(catalog: catalog, category: category, level: level, hasBar: true)
    }

    // MARK: Actions

    // Changing the category changes the pool: the exercises that are not in it are removed
    func selectCategory(_ newCategory: PlanCategory) {
        category = newCategory
        let allowedIds = pool.map { $0.id }
        chosen = chosen.filter { allowedIds.contains($0.id) }
    }

    // The user pressed Done in the picker
    func setExercises(_ items: [CatalogItem]) {
        chosen = items
    }

    func removeExercise(_ item: CatalogItem) {
        chosen = chosen.filter { $0.id != item.id }
    }

    // MARK: Texts and numbers

    private static let groupOrder = ["Legs", "Glutes", "Chest", "Back", "Shoulders", "Arms", "Core"]

    // The muscle groups of the chosen exercises, in a fixed order
    private var groups: [String] {
        Self.groupOrder.filter { group in chosen.contains(where: { $0.group == group }) }
    }

    // e.g. "Legs", "Chest + Back", or "Full body" with 3 or more groups
    var suggestedName: String {
        if groups.isEmpty { return "Your workout" }
        if groups.count >= 3 { return "Full body" }
        return groups.joined(separator: " + ")
    }

    // The name written by the user, or the suggested one
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? suggestedName : trimmed
    }

    // The SF Symbol of the plan, from its muscle groups
    var icon: String {
        if groups.count >= 3 { return "figure.mixed.cardio" }
        if groups == ["Legs"] || groups == ["Legs", "Glutes"] || groups == ["Glutes"] { return "figure.run" }
        if groups == ["Core"] { return "figure.core.training" }
        return "figure.strengthtraining.traditional"
    }

    // Time of the whole session: warm-up + exercises + cool-down
    var estimatedMinutes: Int {
        var total = SafetyRules.warmupMinutes + SafetyRules.cooldownMinutes
        let sets = Prescription.sets(for: level)
        for item in chosen {
            total += Prescription.minutes(isCompound: item.mechanic == "compound", sets: sets, goal: goal)
        }
        return Int(total.rounded())
    }

    // e.g. "Quadriceps · Compound"
    func detailText(_ item: CatalogItem) -> String {
        let kind = item.mechanic == "compound" ? "Compound" : "Isolation"
        return item.muscle.capitalized + " · " + kind
    }

    // A plan needs at least one exercise
    var canSave: Bool { !chosen.isEmpty }

    // The plan for the Home
    func makePlan() -> PlanItem {
        PlanItem(
            name: displayName,
            icon: icon,
            color: PlanPalette.colors[colorIndex],
            exerciseCount: chosen.count,
            minutes: minutes,
            exerciseIds: chosen.map { $0.id },
            colorIndex: colorIndex
        )
    }
}
