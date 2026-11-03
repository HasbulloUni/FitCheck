//
//  SafetyRules.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The safety numbers and texts of the plan generator
// Only data, no logic. Every number lives here, so the team can change it in one place.
// ESTIMATE = our own choice, not validated by studies. Write who decided it and why.
// The reasons are in coach/numeri-sicurezza-schede.md.
enum SafetyRules {

    // MARK: Time
    static let sessionMinutesOptions = [60, 90]
    static let daysOptions = [2, 3, 4, 5]
    static let warmupMinutes = 8.0              // ESTIMATE
    static let cooldownMinutes = 5.0            // ESTIMATE
    static let durationTolerance = 0.15         // ESTIMATE: only on the main part
    static let secondsPerSet = 40.0             // ESTIMATE
    static let holdSeconds = 30                 // for static exercises (plank...)

    // MARK: Limits of one session
    static let maxExercisesPerSession = 12      // ESTIMATE
    static let maxExercisesPerMuscle = 4        // ESTIMATE
    static let minSets = 3
    static let maxSets = 4
    static let easyMinReps = 6                  // ESTIMATE
    static let minRestCompound = 45             // ESTIMATE, in seconds
    static let minRestIsolation = 30            // ESTIMATE, in seconds
    // A muscle with this weight (or more) must get at least one exercise
    static let requiredMuscleWeight = 0.9

    // MARK: Limit of sets in a week, for each muscle (ESTIMATE, source to check)
    static func weeklySetCap(for level: PlanLevel) -> Int {
        switch level {
        case .easy: return 12
        case .medium: return 16
        case .hard: return 20
        }
    }

    // MARK: Recovery
    static let minRecoveryHours = 48            // ESTIMATE, source to check (ACSM 2009)
    static let maxConsecutiveDays = 3
    static let minRestDays = 2

    // MARK: Progression
    static let loadIncreasePercent = 5.0        // ESTIMATE
    static let maxLoadIncreasePercent = 10.0
    static let weeksAtTopBeforeIncrease = 2     // Peppino decision
    static let sessionsWithoutIncrease = 2      // the first sessions of a new plan
    static let longBreakDays = 14               // Peppino decision
    static let longBreakLoadFactor = 0.8        // -20% for one week, Peppino decision
    static let lightWeekEveryWeeks = 5          // ESTIMATE: it is only a proposal
    static let lightWeekLoadFactor = 0.9

    // MARK: Warm-up and cool-down
    static let maxStretches = 6

    // MARK: Texts
    static let noticeSplitChanged = "We changed the split so each muscle can rest 48 hours."
    static let noticeDaysClose = "Your days are close together: some muscles may not get 48 hours of rest."
    static let noticeSimplified = "We kept it simple to keep it safe."
    static let bigLoadJumpWarning = "That's a big jump. Make sure you can keep good form."
    static let stopText = "Stop right away if you feel sharp pain, dizziness, or chest pain. If it does not pass, call a doctor or emergency services. Feeling the muscle burn is normal; pain in a joint is not."
}
