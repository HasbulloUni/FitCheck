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

    // The plan sent with "Go" and the day it was sent: it replaces the routine only on that day
    private(set) var goPlanId: UUID? = nil
    private(set) var goDate: Date? = nil

    // What Today shows: the plan of the rotation, the plan sent with Go, a rest day or nothing
    private var todayOutcome: TodayOutcome {
        TodayResolver.resolve(
            today: .now,
            trainingWeekdays: weekData.plannedWeekdays,
            rotation: savedWeekPlan?.rotation ?? [],
            plans: plans,
            goPlanId: goPlanId,
            goDate: goDate
        )
    }

    // Today's workout: nil when there is no plan to show (rest day or nothing chosen yet)
    var todayPlan: TodayPlan? {
        guard case let .workout(plan, fromGo) = todayOutcome else { return nil }
        return TodayPlan(
            name: plan.name,
            minutes: plan.minutes,
            exerciseCount: plan.exerciseCount,
            planId: plan.id,
            fromGo: fromGo
        )
    }

    // True when the routine says today is a rest day (and no plan was sent with Go)
    var isTodayRest: Bool {
        if case .rest = todayOutcome { return true }
        return false
    }

    // The swipe "Go" of a plan: today's activity is replaced by this plan (only today)
    func sendToToday(_ plan: PlanItem) {
        goPlanId = plan.id
        goDate = Calendar.current.startOfDay(for: .now)
        saveProfile()
    }

    // True when a plan sent with Go is active today
    private var isGoActiveToday: Bool {
        guard let goPlanId, let goDate else { return false }
        return Calendar.current.isDateInToday(goDate) && plans.contains(where: { $0.id == goPlanId })
    }

    // The goals of the week and of the month: the Home shows them, the numbers start at zero
    var goalsViewModel = GoalsViewModel()

    // Plans created by the user: empty at the start
    var plans: [PlanItem] = []

    // True while the screen "Add your plan" is open
    var isAddPlanOpen = false

    // The plan being changed in the editor: nil means the editor creates a new plan
    var planBeingEdited: PlanItem? = nil

    func openAddPlan() {
        planBeingEdited = nil
        isAddPlanOpen = true
    }

    // The pencil of a plan (or a tap on its row): the same screen opens with the plan filled in
    func openEditPlan(_ plan: PlanItem) {
        planBeingEdited = plan
        isAddPlanOpen = true
    }

    func closeAddPlan() {
        isAddPlanOpen = false
        planBeingEdited = nil
    }

    // The colors taken by the OTHER plans (the plan being edited keeps its own color)
    var takenColorIndexes: [Int] {
        plans.filter { $0.id != planBeingEdited?.id }.compactMap { $0.colorIndex }
    }

    // The names of the OTHER plans, for the "same name" warning
    var otherPlanNames: [String] {
        plans.filter { $0.id != planBeingEdited?.id }.map { $0.name }
    }

    // Save in the editor: a known plan is updated, a new one is added
    func savePlan(_ plan: PlanItem) {
        if plans.contains(where: { $0.id == plan.id }) {
            updatePlan(plan)
        } else {
            addPlan(plan)
        }
    }

    // Same id, new values: the list and the saved row are both updated
    private func updatePlan(_ plan: PlanItem) {
        if let position = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[position] = plan
        }
        if let context {
            let targetId = plan.id
            let descriptor = FetchDescriptor<PlanRecord>(predicate: #Predicate<PlanRecord> { $0.id == targetId })
            if let record = try? context.fetch(descriptor).first {
                record.update(from: plan)
                try? context.save()
            }
        }
        closeAddPlan()
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
            let descriptor = FetchDescriptor<PlanRecord>(predicate: #Predicate<PlanRecord> { $0.id == targetId })
            if let records = try? context.fetch(descriptor) {
                for record in records { context.delete(record) }
            }
            try? context.save()
        }

        // A deleted plan leaves its day of the rotation empty and cancels its "Go"
        if var saved = savedWeekPlan {
            for index in saved.rotation.indices where saved.rotation[index].planId == plan.id {
                saved.rotation[index].planId = nil
            }
            savedWeekPlan = saved
        }
        if goPlanId == plan.id {
            goPlanId = nil
            goDate = nil
        }
        saveProfile()
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
    var weekDays: [WeekDay] {
        var data = weekData
        data.hasGoToday = isGoActiveToday
        return data.days(weekOffset: weekOffset)
    }

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

        // "Go" counts only on the day it was sent: an old one is forgotten
        if let savedDate = record.goDate, Calendar.current.isDateInToday(savedDate) {
            goPlanId = UUID(uuidString: record.goPlanId)
            goDate = savedDate
        }

        if record.hasSavedWeekPlan {
            let reminders = zip(record.draftReminderWeekdays, record.draftReminderMinutes).map {
                DayReminder(weekday: $0, minutes: $1)
            }
            savedWeekPlan = EditWeekDraft(
                workoutWeekdays: record.draftWorkoutWeekdays,
                durationMinutes: record.draftDurationMinutes,
                remindMe: record.draftRemindMe,
                reminders: reminders,
                rotation: zip(record.draftRotationWeekdays, record.draftRotationPlanIds).map {
                    RotationSlot(weekday: $0, planId: UUID(uuidString: $1))
                }
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

        profile.goPlanId = goPlanId?.uuidString ?? ""
        profile.goDate = goDate

        if let draft = savedWeekPlan {
            profile.hasSavedWeekPlan = true
            profile.draftWorkoutWeekdays = draft.workoutWeekdays
            profile.draftDurationMinutes = draft.durationMinutes
            profile.draftRemindMe = draft.remindMe
            profile.draftReminderWeekdays = draft.reminders.map { $0.weekday }
            profile.draftReminderMinutes = draft.reminders.map { $0.minutes }
            profile.draftRotationWeekdays = draft.rotation.map { $0.weekday }
            profile.draftRotationPlanIds = draft.rotation.map { $0.planId?.uuidString ?? "" }
        }

        try? context?.save()
    }
}
