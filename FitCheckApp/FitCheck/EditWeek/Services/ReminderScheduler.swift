//
//  ReminderScheduler.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI
import UserNotifications

// The local reminders of the training days.
// Everything stays on the phone: no server, no push.
// One reminder for each training day, repeated every week at the chosen time.
enum ReminderScheduler {

    // Called after "Save changes": the old reminders are removed and the new ones are created.
    static func updateReminders(for draft: EditWeekDraft) async {
        let center = UNUserNotificationCenter.current()

        // Start clean: remove the reminders made last time
        center.removePendingNotificationRequests(withIdentifiers: allIdentifiers)

        // "Remind me" is off: no reminders
        guard draft.remindMe else { return }

        // The permission is asked now, after the user saved the times.
        // If the user says no (now or before), nothing is created and nothing is shown.
        guard await isAllowed(center) else { return }

        for reminder in draft.reminders {
            let content = UNMutableNotificationContent()
            content.title = EditWeekRules.reminderTitle
            content.body = EditWeekRules.reminderBody()
            content.sound = .default

            // Every week, on this day of the week (1 = Sunday ... 7 = Saturday), at this time
            var when = DateComponents()
            when.weekday = reminder.weekday
            when.hour = reminder.minutes / 60
            when.minute = reminder.minutes % 60

            let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
            let request = UNNotificationRequest(
                identifier: identifier(for: reminder.weekday),
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    // MARK: - Helpers

    // True when the user allows notifications. The question appears only the first time.
    private static func isAllowed(_ center: UNUserNotificationCenter) async -> Bool {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = try? await center.requestAuthorization(options: [.alert, .sound])
            return granted ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false   // the user said no: it can be changed only in the iPhone settings
        }
    }

    // One name for each day, so a reminder can be replaced or removed
    private static func identifier(for weekday: Int) -> String {
        "workout-reminder-\(weekday)"
    }

    // The names of the 7 possible reminders
    private static var allIdentifiers: [String] {
        (1...7).map { identifier(for: $0) }
    }
}
