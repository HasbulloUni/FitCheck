//
//  WeeklyPlanGenerator.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The entry point: builds the plan of a whole week
// Same input and same seed always give the same plan (no randomness).
// Steps: safe exercises, split and rest, time, days, warm-up and cool-down, last safety check.
// If the check finds a broken rule, the generator REMOVES exercises (it never adds) and builds
// a simpler plan: one exercise for each muscle.
enum WeeklyPlanGenerator {

    static func generate(catalog: ExerciseCatalog, category: PlanCategory, goal: PlanGoal,
                         level: PlanLevel, days: Int, minutes: Int,
                         preferredStyle: SplitStyle? = nil, previousIds: [String] = [],
                         seed: Int = 0, weekdays: [Int] = [], hasBar: Bool = true) -> GeneratedWeek {

        let daysPerWeek = max(2, min(5, days))
        // Only 60 and 90 minutes exist: anything else becomes 60
        let sessionMinutes = SafetyRules.sessionMinutesOptions.contains(minutes) ? minutes : 60

        let pool = ExercisePool.filter(catalog: catalog, category: category, level: level, hasBar: hasBar)
        let choice = RecoveryPlanner.chooseStyle(daysPerWeek: daysPerWeek, preferred: preferredStyle,
                                                 weekdays: weekdays)
        let options = PlanSplits.options(forDays: daysPerWeek)
        let splitDays = options.first(where: { $0.style == choice.style })?.days ?? options[0].days

        var built = buildWeek(pool: pool, splitDays: splitDays, stretches: catalog.stretches, goal: goal,
                              level: level, minutes: sessionMinutes, previousIds: previousIds,
                              seed: seed, perMuscleCap: SafetyRules.maxExercisesPerMuscle)
        var problems = SafetyChecker.check(days: built.days, weeklySets: built.weeklySets,
                                           weeklyCap: built.cap, level: level, minutes: sessionMinutes)
        var isSimplified = false
        if !problems.isEmpty {
            built = buildWeek(pool: pool, splitDays: splitDays, stretches: catalog.stretches, goal: goal,
                              level: level, minutes: sessionMinutes, previousIds: previousIds,
                              seed: seed, perMuscleCap: 1)
            problems = SafetyChecker.check(days: built.days, weeklySets: built.weeklySets,
                                           weeklyCap: built.cap, level: level, minutes: sessionMinutes)
            isSimplified = true
        }

        var notices: [String] = []
        if let notice = choice.notice { notices.append(notice) }
        for issue in RecoveryPlanner.scheduleIssues(weekdays: weekdays) {
            notices.append("Schedule: " + issue)
        }
        if isSimplified { notices.append(SafetyRules.noticeSimplified) }

        return GeneratedWeek(days: built.days, weeklySets: built.weeklySets, weeklyCap: built.cap,
                             style: choice.style, notices: notices, isSimplified: isSimplified,
                             violations: problems)
    }

    private struct BuiltWeek {
        let days: [GeneratedDay]
        let weeklySets: [String: Int]
        let cap: Int
    }

    private static func buildWeek(pool: [CatalogItem], splitDays: [SplitDay], stretches: [StretchItem],
                                  goal: PlanGoal, level: PlanLevel, minutes: Int, previousIds: [String],
                                  seed: Int, perMuscleCap: Int) -> BuiltWeek {
        let cap = SafetyRules.weeklySetCap(for: level)

        // In how many days of the week each muscle is trained
        var occurrences: [String: Int] = [:]
        for day in splitDays {
            var keysOfDay: [String] = []
            for slot in day.slots where !keysOfDay.contains(slot.key) {
                keysOfDay.append(slot.key)
            }
            for key in keysOfDay { occurrences[key, default: 0] += 1 }
        }

        var seen: [String: Int] = [:]          // days already built for each muscle
        var usedSets: [String: Int] = [:]      // sets already given to each muscle
        var usedThisWeek: [String] = []
        var result: [GeneratedDay] = []

        for day in splitDays {
            // The weekly limit is given a little at a time: day k can use up to k/n of it
            var allowance: [String: Int] = [:]
            for slot in day.slots where allowance[slot.key] == nil {
                seen[slot.key, default: 0] += 1
                let total = occurrences[slot.key] ?? 1
                allowance[slot.key] = (cap * (seen[slot.key] ?? 1)) / total - (usedSets[slot.key] ?? 0)
            }

            let built = DayBuilder.build(
                pool: pool, slots: day.slots, goal: goal, level: level, minutes: minutes,
                usedThisWeek: usedThisWeek, previousIds: previousIds, seed: seed,
                allowance: allowance, perMuscleCap: perMuscleCap
            )
            for exercise in built.exercises {
                usedSets[exercise.slotKey, default: 0] += exercise.sets
                usedThisWeek.append(exercise.id)
            }

            result.append(GeneratedDay(
                label: day.label,
                warmup: WarmupCooldownBuilder.warmup(for: built.exercises),
                exercises: built.exercises,
                cooldown: WarmupCooldownBuilder.cooldown(for: built.exercises, stretches: stretches, seed: seed),
                centralMinutes: built.centralMinutes,
                skipped: built.skipped
            ))
        }
        return BuiltWeek(days: result, weeklySets: usedSets, cap: cap)
    }
}
