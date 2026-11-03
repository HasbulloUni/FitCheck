//
//  ExercisePicker.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - Step 1: the exercises this user can get
// Keeps only safe exercises with a level that fits the user.
enum ExercisePool {

    // Words that remove an exercise: technical, power or with a doubtful label. To review by hand.
    private static let excludedWords = [
        "pullover", "sprint", "rotation", "windmill", "clean", "jerk", "snatch", "swing",
        "pirate", "hip flexion", "pistol", "bradford", "jump", "pass through"
    ]

    static func filter(catalog: ExerciseCatalog, category: PlanCategory, level: PlanLevel,
                       hasBar: Bool) -> [CatalogItem] {
        var pool: [CatalogItem] = []

        for item in catalog.items {
            if CatalogBuilder.excludedIds.contains(item.id) { continue }
            if !level.allowedExerciseLevels.contains(item.level) { continue }

            let lowerName = item.name.lowercased()
            var hasExcludedWord = false
            for word in excludedWords where lowerName.contains(word) {
                hasExcludedWord = true
            }
            if hasExcludedWord { continue }

            // Calisthenics: only exercises with no equipment
            if category == .calisthenics && item.equipment != "Bodyweight" { continue }

            pool.append(item)
        }

        // Calisthenics also gets the exercises added by hand
        if category == .calisthenics {
            for extra in CatalogBuilder.calisthenicsExtras {
                if !level.allowedExerciseLevels.contains(extra.level) { continue }
                if extra.needsBar && !hasBar { continue }
                pool.append(extra)
            }
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
