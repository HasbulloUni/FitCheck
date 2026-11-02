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
struct EditWeekDraft {
    // Training days chosen by the user (1 = Sunday ... 7 = Saturday)
    var workoutWeekdays: [Int] = []

    // How long a session is, in minutes (one of EditWeekRules.durations)
    var durationMinutes = EditWeekRules.defaultDuration

    // The "Remind me" switch
    var remindMe = true

    // One reminder time for each training day
    var reminders: [DayReminder] = []

    init() {}

    // Starts from the current week of the Home, so nothing changes until "Save changes".
    // Every day gets the default time (18:00): later the user can change it.
    init(from week: WeekData) {
        workoutWeekdays = week.plannedWeekdays
        reminders = week.plannedWeekdays.map {
            DayReminder(weekday: $0, minutes: EditWeekRules.defaultStartMinutes)
        }
    }
}
