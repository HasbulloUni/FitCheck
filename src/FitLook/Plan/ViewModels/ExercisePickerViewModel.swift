//
//  ExercisePickerViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of "Add exercises": search, filter by muscle group, and the choice.
// It also keeps the safe limits: no more than 12 exercises, no more than 4 for one muscle.
// While the user is only browsing (no search, no group), the list is grouped into
// "in the plan", "suggested" (muscles not trained yet) and "all". It also gives the texts
// and the data the preview sheet needs for one exercise.
@Observable
final class ExercisePickerViewModel {

    let pool: [CatalogItem]
    private let goal: PlanGoal
    private let level: PlanLevel
    let planName: String                    // e.g. "Leg day": used in texts and in "Add to ..."
    private let detailsById: [String: ExercisePickerDetails]

    var searchText = ""
    var selectedGroup: String? = nil        // nil = all the groups
    private(set) var selectedIds: [String]

    // The exercise shown in the preview sheet (nil = no sheet)
    var previewItem: CatalogItem? = nil

    // The last exercise added or removed with a tap on its button: the screen shows "Undo"
    // while it is not nil
    private(set) var recentChange: (item: CatalogItem, added: Bool)? = nil

    init(pool: [CatalogItem], selectedIds: [String], goal: PlanGoal, level: PlanLevel,
         planName: String = "your plan", details: [String: ExercisePickerDetails] = [:]) {
        self.pool = pool
        self.selectedIds = selectedIds
        self.goal = goal
        self.level = level
        self.planName = planName
        self.detailsById = details
    }

    // MARK: What the screen shows

    private static let groupOrder = ["Legs", "Glutes", "Chest", "Back", "Shoulders", "Arms", "Core"]

    // The groups that have at least one exercise, in a fixed order
    var groups: [String] {
        Self.groupOrder.filter { group in pool.contains(where: { $0.group == group }) }
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

    // True while browsing: no search, no group filter. The "in the plan" and "suggested"
    // sections are shown only then, so the list stays short while the user is searching.
    var isBrowsing: Bool { searchText.isEmpty && selectedGroup == nil }

    func name(of item: CatalogItem) -> String {
        item.variants[level.rawValue] ?? item.name
    }

    // e.g. "Quadriceps · Kettlebell"
    func detailText(_ item: CatalogItem) -> String {
        item.muscle.capitalized + " · " + item.equipment
    }

    // Why an exercise cannot be added now, e.g. "Quadriceps is full · max 4" (nil = it can be added)
    func blockedText(_ item: CatalogItem) -> String? {
        if canToggle(item) { return nil }
        return item.muscle.capitalized + " is full · max \(SafetyRules.maxExercisesPerMuscle)"
    }

    // MARK: The choice

    var selectedCount: Int { selectedIds.count }

    // e.g. "5 selected"
    var selectedText: String { "\(selectedCount) selected" }

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
        return picked(forMuscle: item.muscle) < SafetyRules.maxExercisesPerMuscle
    }

    func toggle(_ item: CatalogItem) {
        if let position = selectedIds.firstIndex(of: item.id) {
            selectedIds.remove(at: position)
            recentChange = (item, false)
        } else if canToggle(item) {
            selectedIds.append(item.id)
            recentChange = (item, true)
        }
    }

    // "Undo" on the toast: adds the exercise back, or removes it again
    func undoRecentChange() {
        guard let change = recentChange else { return }
        toggle(change.item)
        recentChange = nil
    }

    func clearRecentChange() {
        recentChange = nil
    }

    private func picked(forMuscle muscle: String) -> Int {
        selectedItems.filter { $0.muscle == muscle }.count
    }

    // True when no more exercises can be added
    /* UNUSED (commented out, 4 Nov 2026) var isLimitReached: Bool {
        selectedIds.count >= SafetyRules.maxExercisesPerSession
    } */

    // MARK: "Suggested · not trained yet"

    private var trainedMuscles: [String] {
        var muscles: [String] = []
        for item in selectedItems where !muscles.contains(item.muscle) { muscles.append(item.muscle) }
        return muscles
    }

    // One exercise for each muscle the day does not train yet (up to 3), to fill a gap.
    // Empty until the user has picked at least one exercise.
    var suggestedItems: [CatalogItem] {
        guard !selectedItems.isEmpty else { return [] }

        var muscles: [String] = []
        for item in pool where !muscles.contains(item.muscle) { muscles.append(item.muscle) }
        let untrained = muscles.filter { !trainedMuscles.contains($0) }

        var result: [CatalogItem] = []
        for muscle in untrained {
            guard let candidate = pool.first(where: { $0.muscle == muscle && !isSelected($0) }) else { continue }
            result.append(candidate)
            if result.count >= 3 { break }
        }
        return result
    }

    // MARK: When a search finds nothing

    // A looser match: any word of the search (longer than 2 letters) found in the name
    var alternativeItems: [CatalogItem] {
        let words = searchText.lowercased().split(separator: " ").map(String.init).filter { $0.count > 2 }
        guard !words.isEmpty else { return [] }
        let matches = pool.filter { item in
            let lowerName = name(of: item).lowercased()
            return words.contains { lowerName.contains($0) }
        }
        return Array(matches.sorted { name(of: $0) < name(of: $1) }.prefix(4))
    }

    // Why nothing matched, when it is worth explaining (nil = no special reason)
    var noResultsNote: String? {
        searchText.lowercased().contains("barbell")
            ? "Heavy barbell lifts are not included in FitLook."
            : nil
    }

    // MARK: The banner when a muscle (or the whole day) is full

    // Shown above the list when every visible exercise is blocked
    var fullBanner: String? {
        guard !visibleItems.isEmpty, visibleItems.allSatisfy({ blockedText($0) != nil }) else { return nil }

        var muscles: [String] = []
        for item in visibleItems where !muscles.contains(item.muscle) { muscles.append(item.muscle) }
        let maximum = SafetyRules.maxExercisesPerMuscle
        if muscles.count == 1, let muscle = muscles.first {
            return "\(muscle.capitalized) is full: \(maximum) of \(maximum). Each muscle has a limit per day: remove one to add another."
        }
        return "These exercises are full for today. Remove one to add another."
    }

    // MARK: The preview sheet

    func details(for item: CatalogItem) -> ExercisePickerDetails? {
        detailsById[item.id]
    }

    // "3 × 10-12 · rest 75 s", built the same way the generator builds it (nil = not in the plan)
    func planLineText(_ item: CatalogItem) -> String? {
        guard isSelected(item) else { return nil }
        let sets = Prescription.sets(for: level)
        let planned = Prescription.make(item: item, goal: goal, level: level, sets: sets, slotKey: item.group)
        if let hold = planned.holdSeconds {
            return "\(planned.sets) × \(hold) s hold · rest \(planned.restSeconds) s"
        }
        return "\(planned.sets) × \(planned.repsMin ?? 0)-\(planned.repsMax ?? 0) · rest \(planned.restSeconds) s"
    }
}
