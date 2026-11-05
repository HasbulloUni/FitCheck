//
//  OnboardingSaver.swift
//  FitCheck
//
//  Saves everything the user chose in the onboarding with SwiftData:
//  name, training days, reminders, plans and the rotation.
//  It writes the same fields that Home and Edit week read.
//

import SwiftUI
import SwiftData

enum OnboardingSaver {

    // Returns false if the data could not be saved (nothing is kept in that case)
    @discardableResult
    static func save(name: String, draft: EditWeekDraft, plans: [PlanItem], context: ModelContext) -> Bool {
        // The profile is the same one that Home uses: it is created here if it does not exist yet
        let profile = (try? context.fetch(FetchDescriptor<AppProfile>()))?.first ?? {
            let created = AppProfile()
            context.insert(created)
            return created
        }()

        profile.userName = name

        // The training days (same rule as "Save changes" in Edit week)
        var week = WeekData()
        week.changeWeek(plannedWeekdays: draft.workoutWeekdays)
        profile.plannedWeekdays = week.plannedWeekdays
        profile.restWeekdays = week.restWeekdays
        profile.previousPlannedWeekdays = week.previousPlannedWeekdays
        profile.previousRestWeekdays = week.previousRestWeekdays
        profile.ruleStartDate = week.ruleStartDate

        // The plans go to My plans
        for plan in plans {
            context.insert(PlanRecord(from: plan))
        }

        // The rotation: Monday first, the plans in order (they repeat if the days are more)
        var saved = draft
        let orderedDays = [2, 3, 4, 5, 6, 7, 1].filter { draft.workoutWeekdays.contains($0) }
        saved.rotation = orderedDays.enumerated().map { position, weekday in
            RotationSlot(weekday: weekday, planId: plans.isEmpty ? nil : plans[position % plans.count].id)
        }

        profile.hasSavedWeekPlan = true
        profile.draftWorkoutWeekdays = saved.workoutWeekdays
        profile.draftDurationMinutes = saved.durationMinutes
        profile.draftRemindMe = saved.remindMe
        profile.draftReminderWeekdays = saved.reminders.map { $0.weekday }
        profile.draftReminderMinutes = saved.reminders.map { $0.minutes }
        profile.draftRotationWeekdays = saved.rotation.map { $0.weekday }
        profile.draftRotationPlanIds = saved.rotation.map { $0.planId?.uuidString ?? "" }

        do {
            try context.save()
        } catch {
            context.rollback()
            return false
        }

        // The reminders ask the notification permission only if "Remind me" is on
        Task { await ReminderScheduler.updateReminders(for: saved) }
        return true
    }
}
