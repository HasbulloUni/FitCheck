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

    // Today's workout: nil when there is no plan to show (rest day or nothing chosen yet).
    // As soon as a workout is completed today, the card shows its results and stays green all day:
    // whichever plan was trained, the day is done (a plan sent with Go later does not bring Start back).
    var todayPlan: TodayPlan? {
        let outcome = todayOutcome

        if let session = todaySessions.first {
            // The plan of the session if it is the one of the card, otherwise only the numbers
            if case let .workout(plan, fromGo) = outcome, session.planId == plan.id.uuidString {
                return donePlan(from: session, plan: plan, fromGo: fromGo)
            }
            return donePlan(from: session)
        }

        guard case let .workout(plan, fromGo) = outcome else { return nil }
        return TodayPlan(
            name: plan.name,
            minutes: plan.minutes,
            exerciseCount: plan.exerciseCount,
            planId: plan.id,
            result: nil,
            fromGo: fromGo,
            // The button is there only while the workout is not started (no session today, screen closed)
            backTitle: fromGo && workoutPlan == nil ? backTitle : nil
        )
    }

    // What Today would show without the Go: it gives the text of the "Back to ..." button
    private var backTitle: String {
        let withoutGo = TodayResolver.resolve(
            today: .now,
            trainingWeekdays: weekData.plannedWeekdays,
            rotation: savedWeekPlan?.rotation ?? [],
            plans: plans,
            goPlanId: nil,
            goDate: nil
        )
        switch withoutGo {
        case .rest:                 return "Back to rest day"
        case .workout(let plan, _): return "Back to \(plan.name)"
        case .noPlan:               return "Back to my plan"
        }
    }

    // "Back to ..." button: the Go is cancelled and Today goes back to the routine.
    // Only before the workout is started or done.
    func cancelGo() {
        guard goPlanId != nil, workoutPlan == nil, todaySessions.isEmpty else { return }
        goPlanId = nil
        goDate = nil
        saveProfile()
        refreshGoals()   // the week card and the rotation read goPlanId, so they update by themselves
    }

    // The Today card of a day with a workout done: the numbers come from the saved session
    private func donePlan(from session: SessionRecord, plan: PlanItem? = nil, fromGo: Bool = false) -> TodayPlan {
        TodayPlan(
            name: session.planName,
            minutes: session.minutes,
            exerciseCount: plan?.exerciseCount ?? 0,
            planId: plan?.id,
            result: TodayResult(
                minutes: session.minutes,
                sets: session.muscleSets.reduce(0, +),
                topWeight: session.loadWeights.max(),
                date: session.date
            ),
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
        refreshGoals()
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
        loadTodaySessions()   // also refreshes the goals
        celebrateIfWeekDone()
    }

    // MARK: Fireworks
    // True while the fireworks are on the screen
    var isFireworksShown = false

    // The Monday (as a number) of the last week already celebrated: each week is celebrated once
    private static let celebratedWeekKey = "celebratedWeekStart"

    // All the workouts of this week are done: at least as many days with a completed workout as the planned days
    private var isThisWeekDone: Bool {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return false }
        // Planned days of this week, each day with the rule that was valid on it
        var plannedCount = 0
        var day = week.start
        while day < week.end {
            if weekData.plannedWeekdays(on: day).contains(calendar.component(.weekday, from: day)) {
                plannedCount += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        guard plannedCount > 0 else { return false }
        let doneDays = Set(completedSessionDays.filter { week.contains($0) })
        return doneDays.count >= plannedCount
    }

    private func celebrateIfWeekDone() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard isThisWeekDone,
              let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return }

        let key = weekStart.timeIntervalSince1970
        guard UserDefaults.standard.double(forKey: Self.celebratedWeekKey) != key else { return }
        UserDefaults.standard.set(key, forKey: Self.celebratedWeekKey)

        // With "Reduce Motion" on there are no fireworks
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        isFireworksShown = true
    }

    func hideFireworks() {
        isFireworksShown = false
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

        // Every day with a completed workout turns its circle green in the week card
        let allDescriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.isCompleted })
        let allSessions = (try? context?.fetch(allDescriptor)) ?? []
        completedSessionDays = allSessions.map { Calendar.current.startOfDay(for: $0.date) }
        completedSessionColors = allSessions.map { $0.colorIndex }

        refreshGoals()
    }

    // Recomputes the Home goals from all the saved sessions (also the interrupted ones)
    func refreshGoals() {
        let sessions = (try? context?.fetch(FetchDescriptor<SessionRecord>())) ?? []
        goalsViewModel.progress = GoalProgressBuilder.build(
            sessions: sessions,
            weekData: weekData,
            rotation: savedWeekPlan?.rotation ?? [],
            plans: plans,
            now: .now
        )
    }

    // The days (at midnight) with at least one completed workout, read from the saved sessions
    private var completedSessionDays: [Date] = []
    private var completedSessionColors: [Int] = []   // the plan color of each day above, same position

    // The week data with the days done added: the week card and the header read this one
    private var weekDataWithHistory: WeekData {
        var data = weekData
        data.completedDays += completedSessionDays
        data.sessionDays = completedSessionDays
        data.sessionColorIndexes = completedSessionColors
        return data
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

    // True when My plans is full: no more plans can be created until one is deleted
    var isPlanLimitReached: Bool { plans.count >= SafetyRules.maxPlans }

    // The message of the alert shown when a new plan would go over the limit (nil = no alert)
    var planLimitMessage: String? = nil

    private func showPlanLimitAlert(extraPlans: Int = 1) {
        let free = max(0, SafetyRules.maxPlans - plans.count)
        if extraPlans > 1 && free > 0 {
            planLimitMessage = "You can have up to \(SafetyRules.maxPlans) plans and you have \(plans.count). This program adds \(extraPlans): delete \(extraPlans - free) first."
        } else {
            planLimitMessage = "You can have up to \(SafetyRules.maxPlans) plans. Delete one to make a new one."
        }
    }

    func openAddPlan() {
        // A new plan needs a free place (editing an existing plan is always possible)
        if isPlanLimitReached {
            showPlanLimitAlert()
            return
        }
        planBeingEdited = nil
        isAddPlanOpen = true
    }

    // True while the "Ready-made" sheet is open
    var isReadyMadeOpen = false

    // "+ New plan" > Ready-made: the sheet rises from the bottom
    func openReadyMade() {
        if isPlanLimitReached {
            showPlanLimitAlert()
            return
        }
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

        // The program must fit in My plans: otherwise nothing is created
        if plans.count + newPlans.count > SafetyRules.maxPlans {
            let extra = newPlans.count
            // The alert waits until the sheet has gone
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(450))
                showPlanLimitAlert(extraPlans: extra)
            }
            return
        }

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
        refreshGoals()   // the planned days changed: the goals change too
    }

    // The pencil of a plan: the same screen opens with the plan filled in
    func openEditPlan(_ plan: PlanItem) {
        planBeingEdited = plan
        isAddPlanOpen = true
    }

    // The lines of the dropdown of a plan: only the main exercises, in the order of the plan.
    // Sets come from the plan, reps from Prescription (same goal and level as the plan editor).
    func exerciseLines(for plan: PlanItem) -> [PlanExerciseLine] {
        // Read only the exercises of this plan from the database
        let ids = plan.exerciseIds
        var exercises: [Exercise] = []
        if let context {
            let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate<Exercise> { ids.contains($0.id) })
            exercises = (try? context.fetch(descriptor)) ?? []
        }
        let exerciseById = Dictionary(exercises.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let catalog = CatalogBuilder.build(from: exercises)
        let itemById = Dictionary(catalog.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        let goal = PlanGoal.tone
        let level = PlanLevel.medium

        var lines: [PlanExerciseLine] = []
        for (position, id) in plan.exerciseIds.enumerated() {
            let sets = position < plan.exerciseSets.count ? plan.exerciseSets[position] : Prescription.sets(for: level)
            let lineId = "\(position)-\(id)"

            if let item = itemById[id] {
                let planned = Prescription.make(item: item, goal: goal, level: level, sets: sets, slotKey: item.group)
                let amount: String
                if let seconds = planned.holdSeconds {
                    amount = "\(seconds) s"
                } else if let low = planned.repsMin, let high = planned.repsMax {
                    amount = low == high ? "\(low)" : "\(low)-\(high)"
                } else {
                    amount = "-"
                }
                lines.append(PlanExerciseLine(id: lineId, name: planned.name, setsRepsText: "\(planned.sets) × \(amount)"))
            } else if let exercise = exerciseById[id] {
                // Known exercise but not in the catalog: only the sets are shown
                lines.append(PlanExerciseLine(id: lineId, name: exercise.name, setsRepsText: "\(sets) sets"))
            } else {
                // The exercise is not in the database (anymore): a placeholder, never a crash
                lines.append(PlanExerciseLine(id: lineId, name: "Exercise not found", setsRepsText: "-"))
            }
        }
        return lines
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
        refreshGoals()   // the minutes of the plans changed: the goals change too
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
        refreshGoals()
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
        // Empty from today on: the days before today keep the old choice
        weekData.resetWeek()
        savedWeekPlan = nil
        goPlanId = nil
        goDate = nil
        refreshGoals()   // the planned days changed: the goals change too

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

    // Which week the card shows: 0 = this week, 1 = next week, -1 = last week... (the user swipes to change it)
    var weekOffset = 0

    // How many weeks ahead the user can swipe
    static let maxWeeksAhead = 8

    // How many weeks back the user can swipe
    static let maxWeeksBack = 12

    // The 7 days shown in the week card
    var weekDays: [WeekDay] {
        var data = weekDataWithHistory
        data.hasGoToday = isGoActiveToday
        return data.days(weekOffset: weekOffset)
    }

    // The title of the card
    var weekTitle: String {
        switch weekOffset {
        case 0:  return "This week"
        case 1:  return "Next week"
        case -1: return "Last week"
        case ..<0: return "\(-weekOffset) weeks ago"
        default: return "In \(weekOffset) weeks"
        }
    }

    // Swipe to the next week
    func showNextWeek() {
        if weekOffset < Self.maxWeeksAhead {
            weekOffset += 1
        }
    }

    // Swipe back: the past weeks can be seen too (up to maxWeeksBack)
    func showPreviousWeek() {
        if weekOffset > -Self.maxWeeksBack {
            weekOffset -= 1
        }
    }

    // Workouts planned this week: the header shows the invitation only when there are none
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
        refreshGoals()   // days or rotation changed: the goals change too

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

        // The goal progress is computed from the saved sessions in loadTodaySessions()

        // The plans are loaded first: the goal targets need their minutes
        let savedPlans = (try? context.fetch(FetchDescriptor<PlanRecord>())) ?? []
        plans = savedPlans.map { PlanItem(from: $0) }

        loadTodaySessions()   // also computes the goals
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
