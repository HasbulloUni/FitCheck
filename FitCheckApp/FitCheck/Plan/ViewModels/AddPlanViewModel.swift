//
//  AddPlanViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of "Add your plan": one plan is one training DAY (legs, chest + back, full body...).
// The day has three parts, like the plans of the generator:
//  1. warm-up: 8 min, always on, the user picks 1 of the 5 safe moves (mandatory)
//  2. main part: at least 4 exercises, picked by the user (sets can be changed)
//  3. cool-down: 5 min, it can be switched off
// The View only draws.
@Observable
final class AddPlanViewModel {

    // MARK: The choices of the user
    var name = ""                       // empty = the suggested name is used
    var colorIndex: Int                 // position in PlanPalette.colors
    var minutes = EditWeekRules.defaultDuration   // 60 or 90
    private(set) var chosen: [ChosenExercise] = []   // the main part, in order
    private(set) var warmupMoves: [String] = []      // 0 or 1 exercise id (mandatory once picked)
    var hasCooldown = true

    // MARK: What is open on the screen
    var isPickerShown = false                       // "Add exercises"
    var isWarmupShown = false                       // "Warm-up"
    var detailExercise: ChosenExercise? = nil       // the exercise shown in the details sheet

    // The last exercise removed with the × button: the screen shows "Undo" while it is not nil
    private(set) var lastRemoved: ChosenExercise? = nil
    private var lastRemovedPosition = 0

    // Goal and level are fixed for now (the plan is built by hand, not by the generator).
    // Medium: the picker shows beginner and intermediate exercises.
    let goal: PlanGoal = .tone
    let level: PlanLevel = .medium

    // The exercises copied from the database. It is built once.
    private var catalog: ExerciseCatalog? = nil
    // The photo paths of each exercise, e.g. "Goblet_Squat/0.jpg"
    private var imagesById: [String: [String]] = [:]
    // Photos, secondary muscles and steps: only needed in "Add exercises"
    private var detailsById: [String: ExercisePickerDetails] = [:]

    // When the user edits a saved plan (pencil of My plans): its id stays the same
    // and the plan waits here until the exercises of the database are loaded
    private let editingId: UUID?
    private var planToLoad: PlanItem?

    // True while a saved plan is edited ("Edit plan"), false for a new plan
    var isEditing: Bool { editingId != nil }

    // The names of the OTHER plans: only used to warn about a name that is already taken
    private let otherPlanNames: [String]

    init(takenColorIndexes: [Int], otherPlanNames: [String] = [], editing plan: PlanItem? = nil) {
        self.otherPlanNames = otherPlanNames
        editingId = plan?.id
        planToLoad = plan
        if let plan {
            name = plan.name
            colorIndex = plan.colorIndex ?? PlanPalette.firstFree(taken: takenColorIndexes)
            minutes = plan.minutes
            warmupMoves = plan.warmupMoves
            hasCooldown = plan.hasCooldown
        } else {
            colorIndex = PlanPalette.firstFree(taken: takenColorIndexes)
        }
    }

    // Puts the exercises and the sets of the saved plan back.
    private func applySavedPlan() {
        guard let plan = planToLoad else { return }
        planToLoad = nil

        var list: [ChosenExercise] = []
        for (position, id) in plan.exerciseIds.enumerated() {
            guard let item = pool.first(where: { $0.id == id }) else { continue }
            let sets = position < plan.exerciseSets.count ? plan.exerciseSets[position] : Prescription.sets(for: level)
            list.append(ChosenExercise(item: item, sets: sets))
        }
        chosen = list
    }

    // MARK: Database

    // True when the exercises of the database are ready
    var isCatalogReady: Bool { catalog != nil }

    // Called with the exercises saved in the database. It does nothing if they are already loaded
    // or if the database is still empty.
    func loadCatalog(from exercises: [Exercise]) {
        if catalog != nil || exercises.isEmpty { return }
        catalog = CatalogBuilder.build(from: exercises)
        warmupItems = CatalogBuilder.warmupItems(from: exercises)
        for exercise in exercises {
            imagesById[exercise.id] = exercise.images
            detailsById[exercise.id] = ExercisePickerDetails(
                images: exercise.images,
                secondaryMuscles: exercise.secondaryMuscles,
                instructions: exercise.instructions
            )
        }
        applySavedPlan()
    }

    // What "Add exercises" needs to show the preview of each exercise
    var pickerDetails: [String: ExercisePickerDetails] { detailsById }

    // The 5 safe warm-up exercises, built once in loadCatalog
    private(set) var warmupItems: [CatalogItem] = []

    // The safe exercises the user can pick (for the level)
    var pool: [CatalogItem] {
        guard let catalog = catalog else { return [] }
        return ExercisePool.filter(catalog: catalog, level: level)
    }

    // MARK: Actions

    // The user pressed Done in "Add exercises".
    // The exercises already in the plan keep their sets, the new ones get the default sets.
    func setExercises(_ items: [CatalogItem]) {
        var newList: [ChosenExercise] = []
        for item in items {
            if let old = chosen.first(where: { $0.id == item.id }) {
                newList.append(old)
            } else {
                newList.append(ChosenExercise(item: item, sets: Prescription.sets(for: level)))
            }
        }
        chosen = newList
        lastRemoved = nil
        keepValidWarmup()
    }

    // The × button: the exercise goes away, "Undo" can bring it back
    func removeExercise(_ exercise: ChosenExercise) {
        guard let position = chosen.firstIndex(where: { $0.id == exercise.id }) else { return }
        lastRemoved = chosen[position]
        lastRemovedPosition = position
        chosen.remove(at: position)
        if detailExercise?.id == exercise.id {
            detailExercise = nil
        }
    }

    // "Undo": the last removed exercise goes back to its place
    func undoRemove() {
        guard let exercise = lastRemoved else { return }
        let position = min(lastRemovedPosition, chosen.count)
        chosen.insert(exercise, at: position)
        lastRemoved = nil
    }

    // The "Undo" message disappears after a few seconds
    func hideUndo() {
        lastRemoved = nil
    }

    // The + and − buttons of the sets (never below the minimum or above the maximum)
    func changeSets(of exercise: ChosenExercise, by step: Int) {
        guard let position = chosen.firstIndex(where: { $0.id == exercise.id }) else { return }
        let newSets = chosen[position].sets + step
        chosen[position].sets = max(SafetyRules.minSets, min(SafetyRules.maxSets, newSets))
    }

    func canChangeSets(of exercise: ChosenExercise, by step: Int) -> Bool {
        let newSets = exercise.sets + step
        return newSets >= SafetyRules.minSets && newSets <= SafetyRules.maxSets
    }

    // The user pressed Done in "Warm-up"
    func setWarmupMoves(_ ids: [String]) {
        warmupMoves = Array(ids.prefix(SafetyRules.maxWarmupMoves))
    }

    // The exercise with this id, as it is now (nil if it was removed)
    func exercise(withId id: String) -> ChosenExercise? {
        chosen.first(where: { $0.id == id })
    }

    // The warm-up pool is fixed (the 5 ids of CatalogBuilder.warmupExerciseIds), so nothing
    // to drop when the exercises of the day change. Kept so setExercises can call it.
    private func keepValidWarmup() {}

    // MARK: Name, icon and color

    private static let groupOrder = ["Legs", "Glutes", "Chest", "Back", "Shoulders", "Arms", "Core"]

    // The muscle groups of the chosen exercises, in a fixed order
    private var groups: [String] {
        Self.groupOrder.filter { group in chosen.contains(where: { $0.item.group == group }) }
    }

    // e.g. "Legs", "Chest + Back", or "Full body" with 3 or more groups
    var suggestedName: String {
        if groups.isEmpty { return "Name the day" }
        if groups.count >= 3 { return "Full body" }
        return groups.joined(separator: " + ")
    }

    // The name written by the user, or the suggested one
    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { return trimmed }
        return groups.isEmpty ? "New plan" : suggestedName
    }

    // The SF Symbol of the plan, from its muscle groups
    var icon: String {
        if groups.count >= 3 { return "figure.mixed.cardio" }
        if groups == ["Legs"] || groups == ["Legs", "Glutes"] || groups == ["Glutes"] { return "figure.run" }
        if groups == ["Core"] { return "figure.core.training" }
        return "figure.strengthtraining.traditional"
    }

    // True when another plan already has this name (it is allowed, the screen only warns)
    var hasDuplicateName: Bool {
        let mine = displayName.lowercased()
        return otherPlanNames.contains { $0.lowercased() == mine }
    }

    // The color of this plan: the big header and the picked exercises use it
    var color: Color { PlanPalette.colors[colorIndex] }

    // e.g. "NEW PLAN · 60 MIN"
    var headerLabel: String {
        "\(isEditing ? "EDIT PLAN" : "NEW PLAN") · \(minutes) MIN"
    }

    // MARK: Warm-up
    // The warm-up is mandatory (no on/off switch): 1 to 3 moves out of warmupItems.

    // The exercises picked for the warm-up, in the order they were picked
    var selectedWarmupItems: [CatalogItem] {
        warmupMoves.compactMap { id in warmupItems.first(where: { $0.id == id }) }
    }

    // At least 1 move must be picked before the plan can be saved
    var isWarmupReady: Bool { warmupMoves.count >= SafetyRules.minWarmupMoves }

    // The treadmill walk is longer than the other moves and counted on its own;
    // counted only when the plan has exercises
    var warmupMinutes: Int {
        if warmupMoves.isEmpty || chosen.isEmpty { return 0 }
        let hasTreadmill = warmupMoves.contains(CatalogBuilder.treadmillWarmupId)
        let otherCount = hasTreadmill ? warmupMoves.count - 1 : warmupMoves.count
        let treadmillTime = hasTreadmill ? SafetyRules.treadmillWarmupMinutes : 0
        return treadmillTime + otherCount * SafetyRules.minutesPerWarmupMove
    }

    var warmupSummary: String {
        let items = selectedWarmupItems
        if items.isEmpty { return "Pick your warm-up" }
        let names = items.map { displayName(of: $0) }.joined(separator: ", ")
        if chosen.isEmpty { return names + " · counted with exercises" }
        return names + " · \(warmupMinutes) min"
    }

    // The ViewModel of the "Warm-up" screen, with the moves picked so far
    func makeWarmupPicker() -> WarmupPickerViewModel {
        WarmupPickerViewModel(items: warmupItems, details: pickerDetails, selected: warmupMoves)
    }

    // MARK: Main part: texts of one exercise

    // The three parts of the plan as the generator builds them
    private func planned(_ exercise: ChosenExercise) -> PlannedExercise {
        Prescription.make(item: exercise.item, goal: goal, level: level, sets: exercise.sets,
                          slotKey: exercise.item.group)
    }

    // The name to show (calisthenics exercises have an easier or harder version)
    func displayName(of item: CatalogItem) -> String {
        item.variants[level.rawValue] ?? item.name
    }

    // e.g. "10-12" or "30 s hold"
    func repsText(_ exercise: ChosenExercise) -> String {
        let plan = planned(exercise)
        if let hold = plan.holdSeconds { return "\(hold) s hold" }
        return "\(plan.repsMin ?? 0)-\(plan.repsMax ?? 0)"
    }

    // e.g. "75 s"
    func restText(_ exercise: ChosenExercise) -> String {
        "\(planned(exercise).restSeconds) s"
    }

    // e.g. "Stop with 2-3 reps still in the tank"
    func effortText(_ exercise: ChosenExercise) -> String {
        planned(exercise).effortText
    }

    // e.g. "3 × 10-12 · rest 75 s · Quadriceps"
    func rowDetail(_ exercise: ChosenExercise) -> String {
        let plan = planned(exercise)
        let amount = plan.holdSeconds.map { "\($0) s" } ?? "\(plan.repsMin ?? 0)-\(plan.repsMax ?? 0)"
        return "\(plan.sets) × \(amount) · rest \(plan.restSeconds) s · \(exercise.item.muscle.capitalized)"
    }

    // e.g. "Quadriceps · Compound"
    func kindText(_ item: CatalogItem) -> String {
        let kind = item.mechanic == "compound" ? "Compound" : "Isolation"
        return item.muscle.capitalized + " · " + kind
    }

    // The photo paths of an exercise (empty if the database has none)
    func images(of exercise: ChosenExercise) -> [String] {
        imagesById[exercise.id] ?? []
    }

    // MARK: Ramp-up sets
    // The generator adds 2 lighter sets before the first compound exercise (or the first one).

    private var rampUpExercise: ChosenExercise? {
        chosen.first(where: { $0.item.mechanic == "compound" }) ?? chosen.first
    }

    func hasRampUp(_ exercise: ChosenExercise) -> Bool {
        rampUpExercise?.id == exercise.id
    }

    // e.g. "50% × 8-10, then 75% × 4-6"
    var rampUpText: String {
        let warmup = WarmupCooldownBuilder.warmup(for: chosen.map { planned($0) })
        let parts = warmup.approachSets.map { "\(Int($0.loadShare * 100))% × \($0.reps)" }
        return parts.joined(separator: ", then ")
    }

    // MARK: Cool-down

    // How many stretches the cool-down has with the exercises of today
    private var stretchCount: Int {
        guard let catalog = catalog, !chosen.isEmpty else { return 0 }
        let part = WarmupCooldownBuilder.cooldown(for: chosen.map { planned($0) },
                                                  stretches: catalog.stretches, seed: 0)
        return part.stretches.count
    }

    var cooldownSummary: String {
        let length = "\(Int(SafetyRules.cooldownMinutes)) min"
        if !hasCooldown { return length + " · off today" }
        let count = stretchCount
        if count == 0 { return length + " · slow walk + stretches" }
        return length + " · slow walk + \(count) " + (count == 1 ? "stretch" : "stretches")
    }

    // MARK: Time

    // Time of the whole session: warm-up + exercises + cool-down (if it is on)
    var estimatedMinutes: Int {
        if chosen.isEmpty { return 0 }
        var total = Double(warmupMinutes)
        if hasCooldown {
            total += SafetyRules.cooldownMinutes
        }
        for exercise in chosen {
            total += Prescription.minutes(isCompound: exercise.item.mechanic == "compound",
                                          sets: exercise.sets, goal: goal)
        }
        return Int(total.rounded())
    }

    // From 0 to 1: how much of the 60 or 90 minutes is used
    var timeShare: Double {
        min(1, Double(estimatedMinutes) / Double(minutes))
    }

    // e.g. "about 42 of 60 min"
    var timeText: String { "about \(estimatedMinutes) of \(minutes) min" }

    // MARK: Count and save

    var hasEnoughExercises: Bool { chosen.count >= SafetyRules.minExercisesPerPlan }

    // The chosen 60 or 90 minutes are the maximum: the plan can be shorter, never longer
    var isWithinTime: Bool { estimatedMinutes <= minutes }

    // e.g. "5 exercises"
    var exerciseCountText: String {
        chosen.count == 1 ? "1 exercise" : "\(chosen.count) exercises"
    }

    // "3 / 4" while there are too few exercises, "5 · min 4" when there are enough
    var mainCountText: String {
        let minimum = SafetyRules.minExercisesPerPlan
        return hasEnoughExercises ? "\(chosen.count) · min \(minimum)" : "\(chosen.count) / \(minimum)"
    }

    // The button works only with at least 4 exercises and close enough to the chosen minutes
    var isSaveEnabled: Bool { hasEnoughExercises && isWithinTime }

    // The text of the big button says what is still missing
    var saveTitle: String {
        if !hasEnoughExercises { return "Save to My plans" }
        if !isWarmupReady { return "Pick your warm-up" }
        if !isWithinTime { return "Over \(minutes) min: remove something" }
        return isEditing ? "Save changes" : "Save to My plans"
    }

    // The big button: it gives the plan, or opens the warm-up if no move is picked yet
    func pressSave() -> PlanItem? {
        if !hasEnoughExercises { return nil }
        if !isWarmupReady {
            isWarmupShown = true
            return nil
        }
        if !isWithinTime { return nil }
        return makePlan()
    }

    // The plan for the Home
    private func makePlan() -> PlanItem {
        PlanItem(
            id: editingId ?? UUID(),
            name: displayName,
            icon: icon,
            color: color,
            exerciseCount: chosen.count,
            minutes: minutes,
            exerciseIds: chosen.map { $0.id },
            colorIndex: colorIndex,
            exerciseSets: chosen.map { $0.sets },
            warmupMoves: warmupMoves,
            hasCooldown: hasCooldown,
            hasWarmup: true
        )
    }
}
