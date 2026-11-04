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
            result: todayResult(of: plan.id),
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

    // The plan being trained now: not nil while the workout screen is open
    var workoutPlan: PlanItem? = nil

    // The Start button of the Today card: opens the workout of today's plan
    func startToday() {
        guard let id = todayPlan?.planId,
              let plan = plans.first(where: { $0.id == id }) else { return }
        workoutPlan = plan
    }

    // Back from the workout screen
    func closeWorkout() {
        workoutPlan = nil
        loadTodaySessions()
    }

    // The completed workouts saved today: the Today card shows the numbers of its plan
    private var todaySessions: [SessionRecord] = []

    private func loadTodaySessions() {
        let start = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.date >= start && $0.isCompleted },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        todaySessions = (try? context?.fetch(descriptor)) ?? []
    }

    // The numbers of the last completed workout of this plan today (nil = not done yet)
    private func todayResult(of planId: UUID) -> TodayResult? {
        guard let session = todaySessions.first(where: { $0.planId == planId.uuidString }) else { return nil }
        return TodayResult(
            minutes: session.minutes,
            sets: session.muscleSets.reduce(0, +),
            topWeight: session.loadWeights.max()
        )
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

    // True while the "Ready-made" sheet is open
    var isReadyMadeOpen = false

    // "+ New plan" > Ready-made: the sheet rises from the bottom
    func openReadyMade() {
        readyMadeStyle = .fullBody
        isReadyMadeOpen = true
    }

    // Ready-made needs the week: the training days must be saved in "Edit your week" first
    var hasSavedWeek: Bool {
        !(savedWeekPlan?.workoutWeekdays.isEmpty ?? true)
    }

    // True when "Set week" was tapped: Edit week opens as soon as the sheet is closed
    private var opensEditWeekAfterReadyMade = false

    // True while Edit week is open because of "Set week": after Save the sheet comes back
    private var resumesReadyMadeAfterWeek = false

    // The style chosen in the sheet: it is still chosen when the sheet comes back
    var readyMadeStyle: ReadyMadeStyle = .fullBody

    // "Set week" in the sheet: the sheet closes, then Edit week opens
    func setWeekFromReadyMade(_ style: ReadyMadeStyle) {
        readyMadeStyle = style
        opensEditWeekAfterReadyMade = true
        resumesReadyMadeAfterWeek = true
        isReadyMadeOpen = false
    }

    // Called when the sheet is gone (also after a drag down)
    func readyMadeSheetClosed() {
        if opensEditWeekAfterReadyMade {
            opensEditWeekAfterReadyMade = false
            openEditWeek()
        }
    }

    // The level of the ready-made plans. Where the user picks it is not decided yet:
    // for now it is always Beginner.
    var readyMadeLevel: ReadyMadeLevel = .beginner

    // The Create button of the sheet: the plans of the program go to My plans
    // and into the rotation of the training days (one plan for each day, in order).
    func createReadyMade(_ style: ReadyMadeStyle) {
        // Without a saved week nothing is created: the sheet asks to set the week first
        guard hasSavedWeek, let savedWeek = savedWeekPlan else { return }
        isReadyMadeOpen = false

        // The training days saved in Edit week, Monday first (1 = Sunday ... 7 = Saturday)
        let weekdays = savedWeek.workoutWeekdays.sorted { ($0 + 5) % 7 < ($1 + 5) % 7 }

        guard let program = ReadyMadeCatalog.program(level: readyMadeLevel, style: style,
                                                     days: weekdays.count) else { return }

        let newPlans = ReadyMadePlanFactory.makePlans(
            from: program,
            takenColorIndexes: plans.compactMap { $0.colorIndex }
        )
        guard !newPlans.isEmpty else { return }

        for plan in newPlans {
            addPlan(plan)
        }

        // The rotation: day 1 gets plan 1, day 2 plan 2... (with more days than plans, they start again)
        var draft = savedWeek
        draft.rotation = weekdays.enumerated().map { position, weekday in
            RotationSlot(weekday: weekday, planId: newPlans[position % newPlans.count].id)
        }
        savedWeekPlan = draft
        saveProfile()
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

    // "Delete all plans": every plan is deleted the same way as one by one
    // (rotation and Go are cleaned too). The past workouts in Progress are kept.
    func deleteAllPlans() {
        for plan in plans {
            deletePlan(plan)
        }
    }

    // "Reset week" in Edit week: the week is saved empty, like before the first save.
    // The completed days (history) are kept; the reminders are removed.
    func resetWeek() {
        weekData.plannedWeekdays = []
        weekData.restWeekdays = []
        weekData.previousPlannedWeekdays = []
        weekData.previousRestWeekdays = []
        weekData.ruleStartDate = nil
        savedWeekPlan = nil
        goPlanId = nil
        goDate = nil

        if let profile {
            profile.hasSavedWeekPlan = false
            profile.draftWorkoutWeekdays = []
            profile.draftReminderWeekdays = []
            profile.draftReminderMinutes = []
            profile.draftRemindMe = false
            profile.draftRotationWeekdays = []
            profile.draftRotationPlanIds = []
        }
        saveProfile()

        // An empty draft has "Remind me" off: all the reminders are removed
        Task { await ReminderScheduler.updateReminders(for: EditWeekDraft()) }

        closeEditWeek()
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

        // Edit week was opened by "Set week" of Ready-made: the sheet comes back by itself
        let resumesReadyMade = resumesReadyMadeAfterWeek && hasSavedWeek
        closeEditWeek()
        if resumesReadyMade {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))   // wait until Edit week has gone
                isReadyMadeOpen = true
            }
        }
    }

    // Back (or Save): closes "Edit your week" and the Home is shown again.
    // Back without saving does not bring the Ready-made sheet back.
    func closeEditWeek() {
        isEditWeekOpen = false
        resumesReadyMadeAfterWeek = false
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

        // "Go" replaces the routine only on the day it was sent, but it is kept until the end of the
        // week: the rotation of the next days is adjusted because that plan was already done
        if let savedDate = record.goDate, Self.isInCurrentWeek(savedDate) {
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

        loadTodaySessions()

        let savedPlans = (try? context.fetch(FetchDescriptor<PlanRecord>())) ?? []
        plans = savedPlans.map { PlanItem(from: $0) }
    }

    // True when the date is in the current week (weeks start on Monday)
    private static func isInCurrentWeek(_ date: Date) -> Bool {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar.dateInterval(of: .weekOfYear, for: .now)?.contains(date) ?? false
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
