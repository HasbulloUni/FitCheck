//
//  PlanEditorViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// Which day the user is adding exercises to (it opens the picker)
struct PickerRequest: Identifiable {
    let dayIndex: Int
    var id: Int { dayIndex }
}

// The ViewModel of "Your plan": it holds the days of the plan and changes them when the user
// removes or adds exercises. After every change the warm-up, the cool-down and the time
// of the day are calculated again.
@Observable
final class PlanEditorViewModel {

    var days: [GeneratedDay]
    let notices: [String]
    var pickerRequest: PickerRequest? = nil

    // The safe exercises the user can add. The picker shows only these.
    let pool: [CatalogItem]

    private let stretches: [StretchItem]
    private let goal: PlanGoal
    private let level: PlanLevel

    // The picker needs them to calculate the time and the names
    var goalForPicker: PlanGoal { goal }
    var levelForPicker: PlanLevel { level }

    init(week: GeneratedWeek, catalog: ExerciseCatalog, category: PlanCategory,
         goal: PlanGoal, level: PlanLevel, minutes: Int) {
        days = week.days
        notices = week.notices
        stretches = catalog.stretches
        self.goal = goal
        self.level = level
        pool = ExercisePool.filter(catalog: catalog, category: category, level: level, hasBar: true)
    }

    // MARK: Changes

    // Swipe to delete in the list
    func removeExercises(at offsets: IndexSet, inDay dayIndex: Int) {
        var remaining = days[dayIndex].exercises
        remaining.remove(atOffsets: offsets)
        replaceExercises(remaining, inDay: dayIndex)
    }

    // The user pressed Done in the picker: these are now the exercises of the day.
    // Exercises that were already there keep their sets and repetitions.
    func setExercises(_ items: [CatalogItem], inDay dayIndex: Int) {
        let oldOnes = days[dayIndex].exercises
        var result: [PlannedExercise] = []

        for item in items {
            if let existing = oldOnes.first(where: { $0.id == item.id }) {
                result.append(existing)
            } else {
                result.append(Prescription.make(
                    item: item, goal: goal, level: level,
                    sets: Prescription.sets(for: level), slotKey: item.group
                ))
            }
        }
        replaceExercises(sortedInSessionOrder(result), inDay: dayIndex)
    }

    // Big muscles first, compound before isolation (same order as the generator)
    private func sortedInSessionOrder(_ exercises: [PlannedExercise]) -> [PlannedExercise] {
        let order = exercises.indices.sorted { first, second in
            let blockFirst = DayBuilder.blockOrder.firstIndex(of: exercises[first].muscle) ?? 99
            let blockSecond = DayBuilder.blockOrder.firstIndex(of: exercises[second].muscle) ?? 99
            if blockFirst != blockSecond { return blockFirst < blockSecond }
            let compoundFirst = exercises[first].isCompound ? 0 : 1
            let compoundSecond = exercises[second].isCompound ? 0 : 1
            if compoundFirst != compoundSecond { return compoundFirst < compoundSecond }
            return first < second
        }
        return order.map { exercises[$0] }
    }

    // Puts the new exercises in the day and calculates again the warm-up, cool-down and time
    private func replaceExercises(_ exercises: [PlannedExercise], inDay dayIndex: Int) {
        var central = 0.0
        for exercise in exercises {
            central += Prescription.minutes(isCompound: exercise.isCompound, sets: exercise.sets, goal: goal)
        }
        days[dayIndex] = GeneratedDay(
            label: days[dayIndex].label,
            warmup: WarmupCooldownBuilder.warmup(for: exercises),
            exercises: exercises,
            cooldown: WarmupCooldownBuilder.cooldown(for: exercises, stretches: stretches, seed: 0),
            centralMinutes: central,
            skipped: []
        )
    }

    // MARK: Texts

    // e.g. "3 x 8-10 · Quadriceps"
    func detailText(_ exercise: PlannedExercise) -> String {
        let muscle = exercise.muscle.capitalized
        if let hold = exercise.holdSeconds {
            return "\(exercise.sets) x \(hold) s · \(muscle)"
        }
        let low = exercise.repsMin ?? 0
        let high = exercise.repsMax ?? 0
        return "\(exercise.sets) x \(low)-\(high) · \(muscle)"
    }
}
