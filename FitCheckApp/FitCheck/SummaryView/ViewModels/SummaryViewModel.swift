//
//  SummaryViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI
import SwiftData

// The ViewModel of the Home: it owns the data and the logic, the View only draws.
// Everything is saved with SwiftData, through one AppProfile row (and one PlanRecord row
// for each plan): configure(context:) loads it when the Home appears, and every change
// below is written back right away, so nothing is lost when the app closes.
@Observable
final class SummaryViewModel {
    // Week data: starts empty, it only knows the current day
    var weekData = WeekData()

    private var context: ModelContext?
    private var profile: AppProfile?

    // The name of the user: empty until the user sets it
    var userName = ""

    // Today's workout: nil means the user has not added one yet
    var todayPlan: TodayPlan? = nil

    // The goals of the week and of the month: the Home shows them, the numbers start at zero
    var goalsViewModel = GoalsViewModel()

    // Plans created by the user: empty at the start
    var plans: [PlanItem] = []

    // True while the screen "Add your plan" is open
    var isAddPlanOpen = false

    func openAddPlan() {
        isAddPlanOpen = true
    }

    func closeAddPlan() {
        isAddPlanOpen = false
    }

    // Save plan: the new plan goes to My plans and the Home is shown again
    func addPlan(_ plan: PlanItem) {
        plans.append(plan)
        if let context {
            context.insert(PlanRecord(from: plan))
            try? context.save()
        }
        closeAddPlan()
    }

    // Delete a plan from My plans (the Home asks the user first)
    func deletePlan(_ plan: PlanItem) {
        plans.removeAll { $0.id == plan.id }
        if let context {
            let targetId = plan.id
            let descriptor = FetchDescriptor<PlanRecord>(predicate: #Predicate { $0.id == targetId })
            if let records = try? context.fetch(descriptor) {
                for record in records { context.delete(record) }
            }
            try? context.save()
        }
    }

    // What the user saved in "Edit your week" (days, duration, reminders): nil until the first save
    var savedWeekPlan: EditWeekDraft? = nil

    // True while the screen "Edit your week" is open
    var isEditWeekOpen = false

    // Which week the card shows: 0 = this week, 1 = next week... (the user swipes to change it)
    var weekOffset = 0

    // How many weeks ahead the user can swipe
    static let maxWeeksAhead = 8

    // The 7 days shown in the week card
    var weekDays: [WeekDay] { weekData.days(weekOffset: weekOffset) }

    // The title of the card
    var weekTitle: String {
        switch weekOffset {
        case 0:  return "This week"
        case 1:  return "Next week"
        default: return "In \(weekOffset) weeks"
        }
    }

    // Swipe to the next week
    func showNextWeek() {
        if weekOffset < Self.maxWeeksAhead {
            weekOffset += 1
        }
    }

    // Swipe back: never before this week, because the past cannot be trained
    func showPreviousWeek() {
        if weekOffset > 0 {
            weekOffset -= 1
        }
    }

    // Workouts done / planned this week, shown in the header
    var doneThisWeek: Int { weekData.days().filter { $0.state == .done }.count }
    var plannedThisWeek: Int { weekData.plannedWeekdays.count }

    // The pencil of the week card: opens "Edit your week"
    func openEditWeek() {
        isEditWeekOpen = true
    }

    // Save changes: the chosen days go to the week card, the rest is kept for the next time
    func saveWeek(_ draft: EditWeekDraft) {
        // Valid from today on: the days before today keep what they had
        weekData.changeWeek(plannedWeekdays: draft.workoutWeekdays)

        savedWeekPlan = draft
        saveProfile()

        // The reminders are updated in the background: the permission is asked now
        Task { await ReminderScheduler.updateReminders(for: draft) }

        closeEditWeek()
    }

    // Back (or Save): closes "Edit your week" and the Home is shown again
    func closeEditWeek() {
        isEditWeekOpen = false
    }

    // MARK: - SwiftData

    // Called once when the Home appears: loads everything that was saved, or creates the
    // single AppProfile row the first time the app ever runs.
    func configure(context: ModelContext) {
        guard self.context == nil else { return }
        self.context = context

        let saved = (try? context.fetch(FetchDescriptor<AppProfile>()))?.first
        let record = saved ?? {
            let created = AppProfile()
            context.insert(created)
            return created
        }()
        profile = record

        userName = record.userName

        weekData.plannedWeekdays = record.plannedWeekdays
        weekData.restWeekdays = record.restWeekdays
        weekData.completedDays = record.completedDays
        weekData.restDays = record.restDays
        weekData.previousPlannedWeekdays = record.previousPlannedWeekdays
        weekData.previousRestWeekdays = record.previousRestWeekdays
        weekData.ruleStartDate = record.ruleStartDate

        if record.hasTodayPlan {
            todayPlan = TodayPlan(
                name: record.todayPlanName,
                minutes: record.todayPlanMinutes,
                exerciseCount: record.todayPlanExerciseCount
            )
        }

        if record.hasSavedWeekPlan {
            let reminders = zip(record.draftReminderWeekdays, record.draftReminderMinutes).map {
                DayReminder(weekday: $0, minutes: $1)
            }
            savedWeekPlan = EditWeekDraft(
                workoutWeekdays: record.draftWorkoutWeekdays,
                durationMinutes: record.draftDurationMinutes,
                remindMe: record.draftRemindMe,
                reminders: reminders
            )
        }

        goalsViewModel.progress = GoalProgress(
            sessionsDone: record.sessionsDone,
            minutesDone: record.minutesDone,
            strengthDaysDone: record.strengthDaysDone,
            weeksActive: record.weeksActive,
            planWorkoutsDone: record.planWorkoutsDone,
            planWorkoutsPlanned: record.planWorkoutsPlanned,
            musclesCovered: record.musclesCovered
        )

        let savedPlans = (try? context.fetch(FetchDescriptor<PlanRecord>())) ?? []
        plans = savedPlans.map { PlanItem(from: $0) }
    }

    // Copies weekData and savedWeekPlan onto the AppProfile row and saves it
    private func saveProfile() {
        guard let profile else { return }

        profile.plannedWeekdays = weekData.plannedWeekdays
        profile.restWeekdays = weekData.restWeekdays
        profile.completedDays = weekData.completedDays
        profile.restDays = weekData.restDays
        profile.previousPlannedWeekdays = weekData.previousPlannedWeekdays
        profile.previousRestWeekdays = weekData.previousRestWeekdays
        profile.ruleStartDate = weekData.ruleStartDate

        if let draft = savedWeekPlan {
            profile.hasSavedWeekPlan = true
            profile.draftWorkoutWeekdays = draft.workoutWeekdays
            profile.draftDurationMinutes = draft.durationMinutes
            profile.draftRemindMe = draft.remindMe
            profile.draftReminderWeekdays = draft.reminders.map { $0.weekday }
            profile.draftReminderMinutes = draft.reminders.map { $0.minutes }
        }

        try? context?.save()
    }
}
