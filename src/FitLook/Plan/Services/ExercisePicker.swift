//
//  ExercisePicker.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - Step 1: the exercises this user can get
// The unsafe exercises are already removed from exercises.json.
// Here we keep only the ones with a level that fits the user.
enum ExercisePool {

    static func filter(catalog: ExerciseCatalog, level: PlanLevel) -> [CatalogItem] {
        var pool: [CatalogItem] = []

        for item in catalog.items {
            if !level.allowedExerciseLevels.contains(item.level) { continue }

            pool.append(item)
        }

        return pool
    }
}

// MARK: - Step 4: choose ONE exercise for a slot
// Order of preference (the first rule wins):
// right kind, not in the previous plan, not used earlier this week, preferred level,
// then a fixed hash. Never the same exercise twice in one day.
enum ExercisePicker {

    static func pick(pool: [CatalogItem], group: String, muscle: String?, wantCompound: Bool,
                     level: PlanLevel, usedToday: [String], usedThisWeek: [String],
                     previousIds: [String], seed: Int) -> CatalogItem? {
        let wantedMechanic = wantCompound ? "compound" : "isolation"

        var best: CatalogItem? = nil
        var bestKey: (Int, Int, Int, Int, UInt32) = (0, 0, 0, 0, 0)

        for item in pool {
            if item.group != group { continue }
            if usedToday.contains(item.id) { continue }
            if let muscle = muscle, item.muscle != muscle { continue }

            let key = (
                item.mechanic == wantedMechanic ? 0 : 1,
                previousIds.contains(item.id) ? 1 : 0,
                usedThisWeek.contains(item.id) ? 1 : 0,
                item.level == level.preferredExerciseLevel ? 0 : 1,
                Fnv1aHash.hash(String(seed) + item.id)
            )

            // Strictly smaller: on a tie the first one in the list stays
            if best == nil || key < bestKey {
                best = item
                bestKey = key
            }
        }
        return best
    }
}
