//
//  AppProfile.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation
import SwiftData

// MARK: - The one row with everything about the Home, the week and the goals
// There is only ever one AppProfile: SummaryViewModel finds it (or creates it the first time)
// and keeps it updated whenever the user changes something, so nothing is lost when the app closes.
@Model
final class AppProfile {
    var userName: String = ""

    // Week (same fields as WeekData)
    var plannedWeekdays: [Int] = []
    var restWeekdays: [Int] = []
    var completedDays: [Date] = []
    var restDays: [Date] = []
    var previousPlannedWeekdays: [Int] = []
    var previousRestWeekdays: [Int] = []
    var ruleStartDate: Date? = nil

    // The last "Edit your week" draft saved (ignored until hasSavedWeekPlan is true)
    var hasSavedWeekPlan: Bool = false
    var draftWorkoutWeekdays: [Int] = []
    var draftDurationMinutes: Int = 60
    var draftRemindMe: Bool = false
    var draftReminderWeekdays: [Int] = []   // same order as draftReminderMinutes
    var draftReminderMinutes: [Int] = []
    // The rotation of the saved draft: the day and the plan id of each row, in the same order
    // (an empty text means the day has no plan yet)
    var draftRotationWeekdays: [Int] = []
    var draftRotationPlanIds: [String] = []
    // When the rotation started (saving a different order restarts it). nil = since the beginning.
    var rotationStartDate: Date? = nil

    // Today's workout (ignored until hasTodayPlan is true)
    var hasTodayPlan: Bool = false
    var todayPlanName: String = ""
    var todayPlanMinutes: Int = 0
    var todayPlanExerciseCount: Int = 0

    // The plan sent with "Go" and the day it was sent (it replaces the routine only on that day)
    var goPlanId: String = ""
    var goDate: Date? = nil

    // Goals progress (same fields as GoalProgress)
    var sessionsDone: Int = 0
    var minutesDone: Int = 0
    var strengthDaysDone: Int = 0
    var weeksActive: Int = 0
    var planWorkoutsDone: Int = 0
    var planWorkoutsPlanned: Int = 0
    var musclesCovered: Int = 0

    init() {}
}
