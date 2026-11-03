//
//  WarmupCooldownBuilder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The warm-up (before) and the cool-down (after) of a day
// The warm-up is always there and cannot be skipped. The cool-down can be skipped.
// The movements are written by hand (to review): none of them goes over the head.
enum WarmupCooldownBuilder {

    private static let generalWarmups = [
        "Brisk walk", "Light stationary bike", "March on the spot", "Side steps, arms in front"
    ]

    private static let mobilityOfGroup: [String: [String]] = [
        "Legs": ["Hip circles", "Ankle circles", "Leg swings front to back (holding a support)"],
        "Glutes": ["Hip circles", "Ankle circles", "Glute bridge, slow"],
        "Chest": ["Shoulder rolls forward and back", "Chest opener (arms at shoulder height)"],
        "Shoulders": ["Shoulder rolls forward and back", "Arm circles (arms at shoulder height)"],
        "Arms": ["Wrist circles", "Arm circles (arms at shoulder height)"],
        "Back": ["Cat-camel", "Scapular squeezes"],
        "Core": ["Cat-camel", "Bird dog, slow"]
    ]

    private static let groupOrder = ["Legs", "Glutes", "Chest", "Shoulders", "Back", "Arms", "Core"]

    private static let genericMobility = [
        "Shoulder rolls forward and back", "Hip circles", "Ankle circles", "Cat-camel"
    ]

    // Stretches that force the body into a deep or risky position are never used
    private static let forcedStretchWords = [
        "neck", "bridge", "wheel", "plow", "split", "behind", "overhead", "headstand",
        "yoga", "hurdler", "superman", "rotation", "twist"
    ]

    // MARK: Moves the user picks by hand ("Add your plan": 1 or 2 moves, see SafetyRules)

    // About how long the general warm-up lasts, in minutes
    static let generalMinutes = 4

    // The general moves to get warm (walk, bike...)
    static var generalMoves: [String] { generalWarmups }

    // The mobility moves for the muscle groups of the day, each one once (max 6).
    // With less than 4 moves, a few general mobility moves are added.
    static func mobilityMoves(for groups: [String]) -> [String] {
        var moves: [String] = []
        for group in groupOrder where groups.contains(group) {
            for move in mobilityOfGroup[group] ?? [] where !moves.contains(move) {
                moves.append(move)
            }
        }
        for move in genericMobility {
            if moves.count >= 4 { break }
            if !moves.contains(move) { moves.append(move) }
        }
        return Array(moves.prefix(6))
    }

    // MARK: Warm-up
    static func warmup(for exercises: [PlannedExercise]) -> WarmupPart {
        var groups: [String] = []
        for exercise in exercises where !groups.contains(exercise.group) {
            groups.append(exercise.group)
        }

        // Mobility for the groups of the day, then a few general moves if there are less than 4
        let moves = mobilityMoves(for: groups)

        // The general warm-up is chosen with the hash: same day, same choice
        let seed = Fnv1aHash.hash(exercises.map { $0.id }.joined())
        let general = generalWarmups[Int(seed) % generalWarmups.count]

        // Approach sets on the first compound exercise: half, then three quarters of the load
        var approach: [ApproachSet] = []
        let first = exercises.first(where: { $0.isCompound }) ?? exercises.first
        if let first = first {
            approach.append(ApproachSet(exerciseName: first.name, loadShare: 0.5, reps: "8-10"))
            approach.append(ApproachSet(exerciseName: first.name, loadShare: 0.75, reps: "4-6"))
        }

        return WarmupPart(
            minutes: SafetyRules.warmupMinutes,
            generalName: general,
            generalMinutes: generalMinutes,
            mobility: Array(moves.prefix(6)),
            approachSets: approach
        )
    }

    // MARK: Cool-down
    static func cooldown(for exercises: [PlannedExercise], stretches: [StretchItem], seed: Int) -> CooldownPart {
        // The muscles of the day, in session order, each one once
        let inOrder = exercises.indices.sorted { first, second in
            let blockFirst = DayBuilder.blockOrder.firstIndex(of: exercises[first].muscle) ?? 99
            let blockSecond = DayBuilder.blockOrder.firstIndex(of: exercises[second].muscle) ?? 99
            if blockFirst != blockSecond { return blockFirst < blockSecond }
            return first < second
        }

        var muscles: [String] = []
        for position in inOrder {
            let muscle = exercises[position].muscle
            if muscle == "neck" { continue }                  // no stretch for the neck
            let target = (muscle == "traps") ? "middle back" : muscle
            if !muscles.contains(target) { muscles.append(target) }
        }

        var steps: [StretchStep] = []
        for muscle in muscles.prefix(SafetyRules.maxStretches) {
            var best: StretchItem? = nil
            var bestKey: (UInt32, String) = (0, "")

            for stretch in stretches where stretch.muscle == muscle {
                let lowerName = stretch.name.lowercased()
                var isForced = false
                for word in forcedStretchWords where lowerName.contains(word) {
                    isForced = true
                }
                if isForced { continue }

                let key = (Fnv1aHash.hash(String(seed) + stretch.id), stretch.id)
                if best == nil || key < bestKey {
                    best = stretch
                    bestKey = key
                }
            }
            if let best = best {
                steps.append(StretchStep(name: best.name, muscle: muscle, holdSeconds: 25))
            }
        }

        return CooldownPart(minutes: SafetyRules.cooldownMinutes, walkMinutes: 2, stretches: steps)
    }
}
