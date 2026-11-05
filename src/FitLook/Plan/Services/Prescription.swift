//
//  Prescription.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - Step 5: sets, repetitions and rest of one exercise
enum Prescription {

    // Sets: from the level, always between the minimum and the maximum
    static func sets(for level: PlanLevel) -> Int {
        max(SafetyRules.minSets, min(SafetyRules.maxSets, level.sets))
    }

    // Rest in seconds: the one of the goal, but never below the safe minimum
    static func restSeconds(goal: PlanGoal, isCompound: Bool) -> Int {
        let minimum = isCompound ? SafetyRules.minRestCompound : SafetyRules.minRestIsolation
        return max(minimum, goal.restSeconds(isCompound: isCompound))
    }

    // Minutes an exercise takes: sets x (work + rest)
    static func minutes(isCompound: Bool, sets: Int, goal: PlanGoal) -> Double {
        let rest = Double(restSeconds(goal: goal, isCompound: isCompound))
        return Double(sets) * (SafetyRules.secondsPerSet + rest) / 60.0
    }

    static func make(item: CatalogItem, goal: PlanGoal, level: PlanLevel, sets: Int,
                     slotKey: String) -> PlannedExercise {
        let isCompound = item.mechanic == "compound"
        let rest = restSeconds(goal: goal, isCompound: isCompound)
        // Calisthenics exercises have an easier or harder version for each level
        let shownName = item.variants[level.rawValue] ?? item.name

        // Static exercises (plank...): seconds instead of repetitions
        if item.force == "static" {
            return PlannedExercise(
                id: item.id, name: shownName, equipment: item.equipment, muscle: item.muscle,
                group: item.group, isCompound: isCompound, slotKey: slotKey, sets: sets,
                repsMin: nil, repsMax: nil, holdSeconds: SafetyRules.holdSeconds,
                restSeconds: rest, loadText: nil, effortText: level.effortText
            )
        }

        var repsMin = goal.reps(isCompound: isCompound).min
        var repsMax = goal.reps(isCompound: isCompound).max
        let shift = level.repShift
        if shift != 0 {
            repsMin = max(SafetyRules.easyMinReps, repsMin + shift)
            repsMax = max(repsMin + 2, repsMax + shift)
        }

        return PlannedExercise(
            id: item.id, name: shownName, equipment: item.equipment, muscle: item.muscle,
            group: item.group, isCompound: isCompound, slotKey: slotKey, sets: sets,
            repsMin: repsMin, repsMax: repsMax, holdSeconds: nil,
            restSeconds: rest, loadText: level.loadText, effortText: level.effortText
        )
    }
}
