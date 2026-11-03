//
//  Progression.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

enum ProgressionAction {
    case lighterWeek        // after a long break: less load for one week
    case increaseLoad
    case harderVariant      // bodyweight exercises: a harder version instead of more load
    case sameLoad
}

struct ProgressionAdvice {
    let action: ProgressionAction
    let percent: Double         // how much more load (only for increaseLoad)
    let loadFactor: Double      // 0.8 = 20% less load (only for lighterWeek)
    let targetReps: Int
}

// MARK: - Step 8: double progression, with the safe limits
// - after a break of more than 14 days: 20% less load for one week;
// - the first sessions of a new plan: no increase;
// - more load (+5%, never more than +10%) only when ALL the sets reached the top of the
//   repetitions for 2 weeks in a row;
// - one thing at a time: more load OR more repetitions, never both.
enum Progression {

    static func nextTarget(results: [Int], repsMin: Int, repsMax: Int, isBodyweight: Bool,
                           weeksAtTop: Int, sessionsSinceStart: Int, daysSinceLast: Int) -> ProgressionAdvice {

        if daysSinceLast > SafetyRules.longBreakDays {
            return ProgressionAdvice(action: .lighterWeek, percent: 0,
                                     loadFactor: SafetyRules.longBreakLoadFactor, targetReps: repsMin)
        }

        let lowest = results.min() ?? 0
        let isAtTop = lowest >= repsMax

        if isAtTop && sessionsSinceStart > SafetyRules.sessionsWithoutIncrease
            && weeksAtTop >= SafetyRules.weeksAtTopBeforeIncrease {
            let percent = min(SafetyRules.loadIncreasePercent, SafetyRules.maxLoadIncreasePercent)
            return ProgressionAdvice(action: isBodyweight ? .harderVariant : .increaseLoad,
                                     percent: percent, loadFactor: 1, targetReps: repsMin)
        }

        if isAtTop {
            return ProgressionAdvice(action: .sameLoad, percent: 0, loadFactor: 1, targetReps: repsMax)
        }
        return ProgressionAdvice(action: .sameLoad, percent: 0, loadFactor: 1,
                                 targetReps: min(lowest + 1, repsMax))
    }

    // A warning (never a block) when the user sets a load more than 10% over the last one
    static func loadJumpWarning(previousLoad: Double, newLoad: Double) -> String? {
        let limit = previousLoad * (1 + SafetyRules.maxLoadIncreasePercent / 100)
        if previousLoad > 0 && newLoad > limit {
            return SafetyRules.bigLoadJumpWarning
        }
        return nil
    }

    // A lighter week is proposed (never forced) every 5 weeks
    static func isLightWeekDue(weeksSinceLastLightWeek: Int) -> Bool {
        weeksSinceLastLightWeek >= SafetyRules.lightWeekEveryWeeks
    }
}
