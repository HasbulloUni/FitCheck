//
//  ExercisePickerViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of "Pick your exercises": search, filter by muscle group, and the choice.
// It also keeps the safe limits: no more than 12 exercises, no more than 4 for one muscle.
@Observable
final class ExercisePickerViewModel {

    let pool: [CatalogItem]
    private let goal: PlanGoal
    private let level: PlanLevel

    var searchText = ""
    var selectedGroup: String? = nil        // nil = all the groups
    private(set) var selectedIds: [String]

    init(pool: [CatalogItem], selectedIds: [String], goal: PlanGoal, level: PlanLevel) {
        self.pool = pool
        self.selectedIds = selectedIds
        self.goal = goal
        self.level = level
    }

    // MARK: What the screen shows

    // The groups that have at least one exercise, in a fixed order
    var groups: [String] {
        let order = ["Legs", "Glutes", "Chest", "Back", "Shoulders", "Arms", "Core"]
        return order.filter { group in pool.contains(where: { $0.group == group }) }
    }

    // The exercises that match the group and the search
    var visibleItems: [CatalogItem] {
        let words = searchText.lowercased()
        let matching = pool.filter { item in
            if let group = selectedGroup, item.group != group { return false }
            if words.isEmpty { return true }
            return name(of: item).lowercased().contains(words)
        }
        return matching.sorted { name(of: $0) < name(of: $1) }
    }

    func name(of item: CatalogItem) -> String {
        item.variants[level.rawValue] ?? item.name
    }

    // e.g. "Quadriceps · Compound"
    func detailText(_ item: CatalogItem) -> String {
        let kind = item.mechanic == "compound" ? "Compound" : "Isolation"
        return item.muscle.capitalized + " · " + kind
    }

    // MARK: The choice

    var selectedCount: Int { selectedIds.count }

    // The exercises picked, in the order of the list
    var selectedItems: [CatalogItem] {
        selectedIds.compactMap { id in pool.first(where: { $0.id == id }) }
    }

    func isSelected(_ item: CatalogItem) -> Bool {
        selectedIds.contains(item.id)
    }

    // A new exercise can be added only below the safe limits. A picked one can always be removed.
    func canToggle(_ item: CatalogItem) -> Bool {
        if isSelected(item) { return true }
        if selectedIds.count >= SafetyRules.maxExercisesPerSession { return false }
        return picked(forMuscle: item.muscle) < SafetyRules.maxExercisesPerMuscle
    }

    func toggle(_ item: CatalogItem) {
        if let position = selectedIds.firstIndex(of: item.id) {
            selectedIds.remove(at: position)
        } else if canToggle(item) {
            selectedIds.append(item.id)
        }
    }

    private func picked(forMuscle muscle: String) -> Int {
        selectedItems.filter { $0.muscle == muscle }.count
    }

    // True when no more exercises can be added
    var isLimitReached: Bool {
        selectedIds.count >= SafetyRules.maxExercisesPerSession
    }

    // Time of the whole session: warm-up + exercises + cool-down
    var estimatedMinutes: Int {
        var total = SafetyRules.warmupMinutes + SafetyRules.cooldownMinutes
        let sets = Prescription.sets(for: level)
        for item in selectedItems {
            total += Prescription.minutes(isCompound: item.mechanic == "compound", sets: sets, goal: goal)
        }
        return Int(total.rounded())
    }
}
