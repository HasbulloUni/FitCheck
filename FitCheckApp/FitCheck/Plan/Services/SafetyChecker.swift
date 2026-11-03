//
//  SafetyChecker.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The last check before a plan is shown
// Returns the rules that are broken. An empty list means the plan is safe.
enum SafetyChecker {

    static func check(days: [GeneratedDay], weeklySets: [String: Int], weeklyCap: Int,
                      level: PlanLevel, minutes: Int) -> [String] {
        var problems: [String] = []

        for day in days {
            let label = day.label

            if day.warmup.minutes <= 0 || day.cooldown.minutes <= 0 {
                problems.append("\(label): warm-up or cool-down is missing")
            }
            if day.exercises.count > SafetyRules.maxExercisesPerSession {
                problems.append("\(label): too many exercises")
            }
            if day.centralMinutes > DayBuilder.centralLimit(minutes: minutes) + 0.000001 {
                problems.append("\(label): the main part is over the time limit")
            }

            var perMuscle: [String: Int] = [:]
            for exercise in day.exercises {
                perMuscle[exercise.muscle, default: 0] += 1

                if CatalogBuilder.excludedIds.contains(exercise.id) {
                    problems.append("\(label): excluded exercise \(exercise.name)")
                }
                if exercise.sets < SafetyRules.minSets || exercise.sets > SafetyRules.maxSets {
                    problems.append("\(label): sets out of limits in \(exercise.name)")
                }
                let minimumRest = exercise.isCompound ? SafetyRules.minRestCompound : SafetyRules.minRestIsolation
                if exercise.restSeconds < minimumRest {
                    problems.append("\(label): rest too short in \(exercise.name)")
                }
                if level == .easy, let repsMin = exercise.repsMin, repsMin < SafetyRules.easyMinReps {
                    problems.append("\(label): reps below the minimum in \(exercise.name)")
                }
            }
            for (muscle, count) in perMuscle where count > SafetyRules.maxExercisesPerMuscle {
                problems.append("\(label): too many exercises for \(muscle)")
            }
        }

        for (key, total) in weeklySets where total > weeklyCap {
            problems.append("sets of the week over the limit for \(key) (\(total))")
        }
        return problems
    }
}
