//
//  SessionSaver.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation
import SwiftData

// MARK: - Saves the finished workout (SessionRecord) and builds the end screen data
// Progress reads the SessionRecord rows, so this is what makes the workout appear there.
// A workout stopped early is saved too (the sets done are real), but isCompleted is false.
enum SessionSaver {

    // The number of sets done, so the caller can skip saving an empty workout
    static func setsDone(in sets: [[WorkoutSet]]) -> Int {
        sets.reduce(0) { $0 + $1.filter { $0.isDone }.count }
    }

    // Inserts a SessionRecord in the database and returns the summary to show.
    static func save(plan: PlanItem,
                     steps: [WorkoutStep],
                     sets: [[WorkoutSet]],
                     minutes: Int,
                     previousWeights: [String: Double],
                     context: ModelContext?) -> WorkoutSummary {

        var muscleNames: [String] = []
        var muscleSets: [Int] = []
        var loadIds: [String] = []
        var loadNames: [String] = []
        var loadWeights: [Double] = []
        var lines: [WorkoutSummary.LoadLine] = []

        var exercisesTotal = 0
        var exercisesDone = 0
        var allDone = true

        for step in steps where step.kind == .exercise {
            exercisesTotal += 1
            let stepSets = step.id < sets.count ? sets[step.id] : []
            let done = stepSets.filter { $0.isDone }

            if !stepSets.isEmpty && done.count == stepSets.count {
                exercisesDone += 1
            } else {
                allDone = false
            }
            if done.isEmpty { continue }

            // Sets done for each muscle group (the same position in both arrays belongs together)
            if !step.muscleGroup.isEmpty {
                if let position = muscleNames.firstIndex(of: step.muscleGroup) {
                    muscleSets[position] += done.count
                } else {
                    muscleNames.append(step.muscleGroup)
                    muscleSets.append(done.count)
                }
            }

            // The heaviest weight of the exercise (only exercises done with a weight)
            let heaviest = done.map { $0.weight }.max() ?? 0
            if heaviest > 0 {
                loadIds.append(step.exerciseId)
                loadNames.append(step.name)
                loadWeights.append(heaviest)
                lines.append(WorkoutSummary.LoadLine(
                    id: step.exerciseId,
                    name: step.name,
                    weight: heaviest,
                    previous: previousWeights[step.exerciseId]
                ))
            }
        }

        let record = SessionRecord(
            date: .now,
            planId: plan.id.uuidString,
            planName: plan.name,
            colorIndex: plan.colorIndex ?? 0,
            minutes: minutes,
            muscleNames: muscleNames,
            muscleSets: muscleSets,
            loadExerciseIds: loadIds,
            loadExerciseNames: loadNames,
            loadWeights: loadWeights,
            isCompleted: allDone
        )
        context?.insert(record)
        try? context?.save()

        return WorkoutSummary(
            minutes: minutes,
            setsDone: setsDone(in: sets),
            exercisesDone: exercisesDone,
            exercisesTotal: exercisesTotal,
            isCompleted: allDone,
            loads: lines
        )
    }
}
