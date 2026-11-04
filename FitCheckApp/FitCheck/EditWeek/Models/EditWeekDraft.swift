//
//  EditWeekDraft.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// MARK: - The reminder time of one day
// Only data, no logic. The time is counted in minutes from midnight: 18:00 = 1080.
struct DayReminder: Identifiable {
    let weekday: Int        // 1 = Sunday, 2 = Monday ... 7 = Saturday
    var minutes: Int        // e.g. 1080 for 18:00

    var id: Int { weekday }
}

// MARK: - The working copy of the week
// The user changes this copy while the screen is open.
// The real week of the Home changes only when the user taps "Save changes".
// Only data, no logic: the logic lives in EditWeekViewModel.
// The plan of one training day of the rotation (nil planId = the day has no plan yet)
struct RotationSlot: Identifiable {
    let weekday: Int        // 1 = Sunday, 2 = Monday ... 7 = Saturday
    var planId: UUID?

    var id: Int { weekday }
}

// One row of the rotation card, ready to be drawn
struct RotationRowItem: Identifiable {
    let number: Int         // 1, 2, 3... in the order of the days (Monday first)
    let weekday: Int
    let dayName: String     // e.g. "Mon"
    let plan: PlanItem?     // nil = the row is still empty

    var id: Int { weekday }
}

struct EditWeekDraft {
    // Training days chosen by the user (1 = Sunday ... 7 = Saturday)
    var workoutWeekdays: [Int] = []

    // How long a session is, in minutes (one of EditWeekRules.durations)
    var durationMinutes = EditWeekRules.defaultDuration

    // The "Remind me" switch: it starts off, the user turns it on
    var remindMe = false

    // One reminder time for each training day
    var reminders: [DayReminder] = []

    // The plan of each training day, in the same order as the days (Monday first)
    var rotation: [RotationSlot] = []

    init() {}

    // Starts from the current week of the Home, so nothing changes until "Save changes".
    // Every day gets the default time (18:00): later the user can change it.
    init(from week: WeekData) {
        workoutWeekdays = week.plannedWeekdays
        reminders = week.plannedWeekdays.map {
            DayReminder(weekday: $0, minutes: EditWeekRules.defaultStartMinutes)
        }
    }

    // Rebuilds a draft that was saved with SwiftData
    init(workoutWeekdays: [Int], durationMinutes: Int, remindMe: Bool, reminders: [DayReminder],
         rotation: [RotationSlot] = []) {
        self.rotation = rotation
        self.workoutWeekdays = workoutWeekdays
        self.durationMinutes = durationMinutes
        self.remindMe = remindMe
        self.reminders = reminders
    }
}
