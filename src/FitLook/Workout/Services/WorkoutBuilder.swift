//
//  WorkoutBuilder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - Builds the steps of a workout from a plan
// Order: warm-up moves (if the plan has a warm-up), the exercises, the cool-down (if on).
enum WorkoutBuilder {

    static func makeSteps(plan: PlanItem, exercises: [Exercise]) -> [WorkoutStep] {
        var byId: [String: Exercise] = [:]
        for exercise in exercises {
            byId[exercise.id] = exercise
        }

        var steps: [WorkoutStep] = []

        // 1. Warm-up
        if plan.hasWarmup {
            for id in plan.warmupMoves {
                guard let exercise = byId[id] else { continue }
                let seconds = id == CatalogBuilder.treadmillWarmupId
                    ? WorkoutRules.treadmillSeconds
                    : WorkoutRules.warmupMoveSeconds
                steps.append(step(id: steps.count, kind: .warmup, exercise: exercise,
                                  setCount: 0, seconds: seconds))
            }
        }

        // 2. The exercises of the plan, with the sets chosen by the user
        for (index, id) in plan.exerciseIds.enumerated() {
            guard let exercise = byId[id] else { continue }
            let sets = index < plan.exerciseSets.count ? plan.exerciseSets[index] : SafetyRules.minSets
            steps.append(step(id: steps.count, kind: .exercise, exercise: exercise,
                              setCount: sets, seconds: 0))
        }

        // 3. Cool-down: one step of stretching
        if plan.hasCooldown {
            steps.append(WorkoutStep(
                id: steps.count,
                kind: .cooldown,
                exerciseId: "",
                name: "Cool-down stretching",
                muscles: "Whole body",
                muscleGroup: "",
                imagePaths: [],
                instructions: [
                    "Walk slowly for one minute to bring your breathing down.",
                    "Stretch the muscles you trained. Hold each stretch for about 30 seconds.",
                    "Never force a stretch: stop if you feel pain."
                ],
                setCount: 0,
                durationSeconds: WorkoutRules.cooldownSeconds
            ))
        }

        return steps
    }

    // One step from an exercise of the database
    private static func step(id: Int, kind: WorkoutStep.Kind, exercise: Exercise,
                             setCount: Int, seconds: Int) -> WorkoutStep {
        let main = exercise.primaryMuscles.first ?? ""
        let group = MuscleGroup(databaseMuscle: main)
        let groupTitle = group?.title ?? ""
        let muscles = [groupTitle, main.capitalized].filter { !$0.isEmpty }.joined(separator: " · ")

        return WorkoutStep(
            id: id,
            kind: kind,
            exerciseId: exercise.id,
            name: exercise.name,
            muscles: muscles,
            muscleGroup: group?.rawValue ?? "",
            imagePaths: exercise.images,
            instructions: exercise.instructions,
            setCount: setCount,
            durationSeconds: seconds
        )
    }
}
