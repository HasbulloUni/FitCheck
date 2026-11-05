//
//  EditWeekViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// The ViewModel of "Edit your week": it owns the draft and the logic, the View only draws.
// It handles the training days, the session length, the notes and the reminder times.
// (Saving comes next.)
@Observable
final class EditWeekViewModel {
    // The working copy of the week: the real week changes only when the user saves
    var draft: EditWeekDraft

    // Starts from the choices saved last time. The first time there are none,
    // so it starts from the current week of the Home.
    init(week: WeekData, savedPlan: EditWeekDraft?, plans: [PlanItem] = []) {
        self.plans = plans
        draft = savedPlan ?? EditWeekDraft(from: week)
        syncRotation()

        // The first time there is no rotation yet: the days get the plans in the order they were created
        let hadRotation = !(savedPlan?.rotation.isEmpty ?? true)
        if !hadRotation && draft.rotation.allSatisfy({ $0.planId == nil }) {
            for position in draft.rotation.indices where position < plans.count {
                draft.rotation[position].planId = plans[position].id
            }
        }
    }

    // All the plans of My plans: the "Change" menu offers them
    let plans: [PlanItem]

    // MARK: - Training days

    // How many training days are picked
    var workoutDayCount: Int { draft.workoutWeekdays.count }

    // True when this day is a training day (1 = Sunday ... 7 = Saturday)
    func isWorkoutDay(_ weekday: Int) -> Bool {
        draft.workoutWeekdays.contains(weekday)
    }

    // True when no more days can be added
    var isDayLimitReached: Bool {
        workoutDayCount >= EditWeekRules.maxWorkoutDays
    }

    // The "Save changes" button works only with a valid number of days
    var canSave: Bool {
        workoutDayCount >= EditWeekRules.minWorkoutDays
            && workoutDayCount <= EditWeekRules.maxWorkoutDays
    }

    // Tap on a day: training becomes rest, rest becomes training (up to the maximum)
    func toggleDay(_ weekday: Int) {
        if isWorkoutDay(weekday) {
            // The day is removed together with its reminder time
            draft.workoutWeekdays.removeAll { $0 == weekday }
            draft.reminders.removeAll { $0.weekday == weekday }
            syncRotation()
        } else if !isDayLimitReached {
            // The new day starts with the default time (18:00)
            draft.workoutWeekdays.append(weekday)
            draft.reminders.append(
                DayReminder(weekday: weekday, minutes: EditWeekRules.defaultStartMinutes)
            )
            // The reminders are always shown Monday first
            draft.reminders.sort { mondayFirstPosition($0.weekday) < mondayFirstPosition($1.weekday) }
            // The new day gets an empty row in the rotation, in its place
            syncRotation()
        }
    }

    // MARK: - Plan rotation

    private static let dayNames = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]

    // One row for each training day, Monday first, numbered 1, 2, 3...
    var rotationRows: [RotationRowItem] {
        draft.rotation.enumerated().map { position, slot in
            RotationRowItem(
                number: position + 1,
                weekday: slot.weekday,
                dayName: Self.dayNames[slot.weekday] ?? "",
                plan: plans.first(where: { $0.id == slot.planId })
            )
        }
    }

    // The most plans the rotation can have: one for each training day
    var maxRotationPlans: Int { workoutDayCount }

    // How many different plans the rotation uses now
    var rotationPlanCount: Int {
        Set(draft.rotation.compactMap { $0.planId }).count
    }

    // The note under the rotation rows, e.g. "3 training days: up to 3 plans in the rotation."
    var rotationLimitNote: String? {
        workoutDayCount == 0 ? nil : EditWeekRules.rotationLimitNote(days: workoutDayCount)
    }

    // The "Change" menu: the day keeps its plan until the user picks another one.
    // A new plan can enter the rotation only if there is still room (never more plans than days).
    func changePlan(weekday: Int, to planId: UUID) {
        guard let index = draft.rotation.firstIndex(where: { $0.weekday == weekday }) else { return }
        var newRotation = draft.rotation
        newRotation[index].planId = planId
        guard Set(newRotation.compactMap { $0.planId }).count <= maxRotationPlans else { return }
        draft.rotation[index].planId = planId
    }

    // Makes the rotation match the training days: a new day gets an empty row, a removed day
    // loses its row, and a plan that does not exist anymore (deleted) leaves its row empty.
    // The plans stay tied to their day, so adding a day never moves the others.
    private func syncRotation() {
        let orderedDays = [2, 3, 4, 5, 6, 7, 1].filter { draft.workoutWeekdays.contains($0) }
        draft.rotation = orderedDays.map { weekday in
            let oldId = draft.rotation.first(where: { $0.weekday == weekday })?.planId
            let stillExists = plans.contains(where: { $0.id == oldId })
            return RotationSlot(weekday: weekday, planId: stillExists ? oldId : nil)
        }
    }

    // MARK: - Session length

    // The durations shown as buttons: they come from EditWeekRules.durations
    var durations: [Int] { EditWeekRules.durations }

    /* UNUSED (commented out, 4 Nov 2026) func isSelectedDuration(_ minutes: Int) -> Bool {
        draft.durationMinutes == minutes
    } */

    /* UNUSED (commented out, 4 Nov 2026) func selectDuration(_ minutes: Int) {
        draft.durationMinutes = minutes
    } */

    // MARK: - Notes under the reminder card
    // They change with the number of days and the length of the session.

    // First note, e.g. "3 days picked. 60 minutes is the shortest that covers the whole body."
    /* UNUSED (commented out, 4 Nov 2026) var daysNote: String {
        let days = workoutDayCount == 1 ? "1 day picked." : "\(workoutDayCount) days picked."
        if draft.durationMinutes == EditWeekRules.durations.first {
            return "\(days) \(draft.durationMinutes) minutes is the shortest that covers the whole body."
        }
        return "\(days) \(draft.durationMinutes) minutes leaves room for extra exercises."
    } */

    // Second note: shown with 3 days or fewer, nil otherwise
    /* UNUSED (commented out, 4 Nov 2026) var fewDaysNote: String? {
        if workoutDayCount <= 3 {
            return "Fewer than 3 days? That is fine, 2 works too. We suggest 3 for steady progress."
        }
        return nil
    } */

    // MARK: - Reminder times

    // The "Remind me" switch
    func setRemindMe(_ isOn: Bool) {
        draft.remindMe = isOn

        // Turning it on: every training day must have its time (default 18:00)
        if isOn {
            for weekday in draft.workoutWeekdays where !draft.reminders.contains(where: { $0.weekday == weekday }) {
                draft.reminders.append(DayReminder(weekday: weekday, minutes: EditWeekRules.defaultStartMinutes))
            }
            draft.reminders.sort { mondayFirstPosition($0.weekday) < mondayFirstPosition($1.weekday) }
        }
    }

    // The time picker: the user taps "18:00" and chooses the time
    func setTime(weekday: Int, minutes: Int) {
        guard let index = draft.reminders.firstIndex(where: { $0.weekday == weekday }) else { return }
        draft.reminders[index].minutes = minutes
    }

    // The text of a time, e.g. 1080 -> "18:00"
    func timeText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }

    // Monday = 0 ... Sunday = 6 (the Apple calendar has Sunday = 1 and Monday = 2)
    private func mondayFirstPosition(_ weekday: Int) -> Int {
        (weekday + 5) % 7
    }
}
