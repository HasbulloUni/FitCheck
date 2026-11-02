//
//  ReminderCard.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// The white card "Remind me" with the switch and one time row for each training day.
// With the switch off, or with no training day, only the title line is shown.
// Only drawing: all the actions go back to EditWeekViewModel.
struct ReminderCard: View {
    let remindMe: Bool
    let reminders: [DayReminder]
    let unit: CGFloat
    let timeText: (Int) -> String                       // minutes -> "18:00"
    let onSwitch: (Bool) -> Void
    let onPickTime: (Int, Int) -> Void                  // day number, minutes

    // Short names of the days, indexed by the Apple number minus 1 (1 = Sunday)
    private let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 2.5 * unit) {
            HStack {
                Text(EditWeekRules.remindMe)
                    .font(.system(size: 4 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Toggle("", isOn: Binding(get: { remindMe }, set: { onSwitch($0) }))
                    .labelsHidden()
                    .tint(AppColors.yellow)
                    .scaleEffect(0.85)
            }

            if remindMe {
                ForEach(reminders) { reminder in
                    ReminderTimeRow(
                        dayName: dayNames[reminder.weekday - 1],
                        minutes: reminder.minutes,
                        timeText: timeText(reminder.minutes),
                        unit: unit,
                        onPickTime: { onPickTime(reminder.weekday, $0) }
                    )
                }
            }
        }
        .padding(.horizontal, 4 * unit)
        .padding(.vertical, 3 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 6 * unit))
        // The list of times appears and disappears smoothly with the switch
        .animation(.easeInOut(duration: 0.25), value: remindMe)
    }
}

// MARK: - Previews
private let sampleReminders = [
    DayReminder(weekday: 2, minutes: 1080),
    DayReminder(weekday: 4, minutes: 1140),
    DayReminder(weekday: 6, minutes: 1080)
]

private func sampleTime(_ minutes: Int) -> String {
    String(format: "%02d:%02d", minutes / 60, minutes % 60)
}

// The card only draws: the switch value comes from outside.
// This small wrapper keeps the value, so in the preview the switch really works.
private struct ReminderCardPreview: View {
    @State var remindMe = true
    let reminders: [DayReminder]

    var body: some View {
        ReminderCard(remindMe: remindMe, reminders: reminders, unit: 3.9, timeText: sampleTime,
                     onSwitch: { remindMe = $0 }, onPickTime: { _, _ in })
            .padding(20)
            .background(AppColors.background)
    }
}

#Preview("Light") {
    ReminderCardPreview(reminders: sampleReminders)
}

#Preview("Dark") {
    ReminderCardPreview(reminders: sampleReminders)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    ReminderCardPreview(reminders: [])
}
