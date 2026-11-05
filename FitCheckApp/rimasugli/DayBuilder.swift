//
//  DayBuilder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// What the builder returns for one day
struct DayBuildResult {
    let exercises: [PlannedExercise]
    let centralMinutes: Double
    let skipped: [String]
}

// MARK: - Step 3: fill the main part of one training day
// Phase 1 (coverage): every important muscle (weight 0.9 or more) gets one exercise,
//   the heaviest muscle first.
// Phase 2 (volume): with the time that is left, one exercise at a time goes to the muscle with
//   the highest score: weight / (exercises already given + 1).
// It stops at the first limit it meets: the time, 12 exercises, 4 exercises for a muscle,
// or the sets still allowed this week for the muscle ("allowance").
enum DayBuilder {

    // The order of the blocks in a session: big muscles first
    static let blockOrder = [
        "quadriceps", "hamstrings", "glutes", "calves", "adductors", "abductors",
        "chest", "lats", "middle back", "lower back", "traps",
        "shoulders", "neck", "biceps", "triceps", "forearms", "abdominals"
    ]

    // Minutes of the main part. The tolerance is only on this part.
    static func centralLimit(minutes: Int) -> Double {
        let free = Double(minutes) - SafetyRules.warmupMinutes - SafetyRules.cooldownMinutes
        return free * (1 + SafetyRules.durationTolerance)
    }

    private enum AddResult {
        case added
        case noFit
        case noExercise
    }

    static func build(pool: [CatalogItem], slots: [MuscleSlot], goal: PlanGoal, level: PlanLevel,
                      minutes: Int, usedThisWeek: [String], previousIds: [String], seed: Int,
                      allowance: [String: Int], perMuscleCap: Int) -> DayBuildResult {

        let limit = centralLimit(minutes: minutes)
        let sets = Prescription.sets(for: level)

        var counts = Array(repeating: 0, count: slots.count)
        var spent = 0.0
        var usedToday: [String] = []
        var chosen: [CatalogItem] = []
        var chosenKeys: [String] = []
        var skipped: [String] = []
        var setsLeft = allowance

        // Tries to add the next exercise of the muscle number "index"
        func tryAdd(_ index: Int) -> AddResult {
            let slot = slots[index]
            let key = slot.key

            // The week allows no more sets for this muscle
            if (setsLeft[key] ?? 0) < sets { return .noFit }

            let type = slot.types[counts[index]]
            guard let item = ExercisePicker.pick(
                pool: pool, group: slot.group, muscle: slot.muscle,
                wantCompound: type == .compound, level: level,
                usedToday: usedToday, usedThisWeek: usedThisWeek,
                previousIds: previousIds, seed: seed
            ) else { return .noExercise }

            let cost = Prescription.minutes(isCompound: item.mechanic == "compound", sets: sets, goal: goal)
            if spent + cost > limit { return .noFit }

            spent += cost
            setsLeft[key] = (setsLeft[key] ?? 0) - sets
            counts[index] += 1
            usedToday.append(item.id)
            chosen.append(item)
            chosenKeys.append(key)
            return .added
        }

        // Phase 1: coverage, the heaviest muscle first
        let byWeight = slots.indices.sorted { first, second in
            if slots[first].weight != slots[second].weight {
                return slots[first].weight > slots[second].weight
            }
            return first < second
        }
        for index in byWeight {
            if slots[index].weight >= SafetyRules.requiredMuscleWeight
                && chosen.count < SafetyRules.maxExercisesPerSession {
                if tryAdd(index) != .added {
                    let slot = slots[index]
                    skipped.append("missing \(slot.group)/\(slot.muscle ?? "-") (time, limit or exercises)")
                }
            }
        }

        // Phase 2: volume
        var blocked: [Int] = []
        while chosen.count < SafetyRules.maxExercisesPerSession {
            let candidates = slots.indices.filter { index in
                !blocked.contains(index)
                    && counts[index] < min(slots[index].types.count, perMuscleCap)
            }
            let ordered = candidates.sorted { first, second in
                let scoreFirst = slots[first].weight / Double(counts[first] + 1)
                let scoreSecond = slots[second].weight / Double(counts[second] + 1)
                if scoreFirst != scoreSecond { return scoreFirst > scoreSecond }
                return first < second
            }

            var placed = false
            for index in ordered {
                if tryAdd(index) == .added {
                    placed = true
                    break
                }
                blocked.append(index)
            }
            if !placed { break }
        }

        // Put the exercises in session order: one block for each muscle, compound first
        let inOrder = chosen.indices.sorted { first, second in
            let blockFirst = blockOrder.firstIndex(of: chosen[first].muscle) ?? blockOrder.count
            let blockSecond = blockOrder.firstIndex(of: chosen[second].muscle) ?? blockOrder.count
            if blockFirst != blockSecond { return blockFirst < blockSecond }
            let compoundFirst = chosen[first].mechanic == "compound" ? 0 : 1
            let compoundSecond = chosen[second].mechanic == "compound" ? 0 : 1
            if compoundFirst != compoundSecond { return compoundFirst < compoundSecond }
            return first < second
        }

        var planned: [PlannedExercise] = []
        for position in inOrder {
            planned.append(Prescription.make(
                item: chosen[position], goal: goal, level: level, sets: sets,
                slotKey: chosenKeys[position]
            ))
        }

        return DayBuildResult(exercises: planned, centralMinutes: spent, skipped: skipped)
    }
}
