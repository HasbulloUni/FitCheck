//
//  EditWeekRules.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// MARK: - The fixed rules and texts of "Edit your week"
// Only data, no logic. Every number and text of the screen lives here,
// so the team can change them in one place.
enum EditWeekRules {

    // MARK: Training days
    static let minWorkoutDays = 2
    static let maxWorkoutDays = 5

    // MARK: Session length (minutes)
    static let durations = [60, 90]
    static let defaultDuration = 60

    // The text of a duration button, e.g. "60 min"
    static func durationTitle(_ minutes: Int) -> String {
        "\(minutes) min"
    }

    // MARK: Reminder time
    // Times are counted in minutes from midnight: 18:00 = 18 * 60 = 1080
    static let defaultStartMinutes = 18 * 60
    // No earliest or latest time: the user can train whenever they want.

    // MARK: Texts
    static let title = "Edit your week"
    static let subtitle = "Changes apply from today on. Past days stay as they are."
    static let daysQuestion = "Which days? Pick \(minWorkoutDays) to \(maxWorkoutDays)"
    static let durationQuestion = "How long is a session?"
    static let startQuestion = "When do you wanna start?"
    static let remindMe = "Remind me"
    static let noDaysHint = "Pick your training days to set the times."
    static let notificationsNote = "Notifications are asked after you save your times."
    static let saveButton = "Save changes"

    // MARK: Reminder notification
    static let reminderTitle = "Time to train"

    // e.g. "Your 60 min workout is waiting for you."
    static func reminderBody(minutes: Int) -> String {
        "Your \(minutes) min workout is waiting for you."
    }
}
