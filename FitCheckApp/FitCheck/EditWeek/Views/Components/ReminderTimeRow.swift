//
//  ReminderTimeRow.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// One line "Mon  18:00": the reminder time of one training day.
// Tapping the time opens the time picker.
// Only drawing: the logic lives in EditWeekViewModel.
struct ReminderTimeRow: View {
    let dayName: String                    // e.g. "Mon"
    let minutes: Int                       // time in minutes from midnight, e.g. 1080
    let timeText: String                   // the same time written, e.g. "18:00"
    let unit: CGFloat
    let onPickTime: (Int) -> Void          // called with the minutes chosen in the picker

    @State private var isPickerOpen = false

    var body: some View {
        HStack(spacing: 2 * unit) {
            Text(dayName)
                .font(.system(size: 3.8 * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            // Tap on the text: the picker opens
            Button(action: { isPickerOpen = true }) {
                Text(timeText)
                    .font(.system(size: 3.8 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 3.5 * unit)
                    .padding(.vertical, 1.8 * unit)
                    .background(AppColors.cardAlt, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $isPickerOpen) {
            timePickerSheet
        }
    }

    // The time picker sheet: a title, the wheels on a card and a "Done" button
    private var timePickerSheet: some View {
        VStack(spacing: 4 * unit) {
            Text("Reminder · \(dayName)")
                .font(.system(size: 5 * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, 6 * unit)

            DatePicker(
                "",
                selection: Binding(
                    get: { dateFromMinutes(minutes) },
                    set: { onPickTime(minutesFromDate($0)) }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxWidth: .infinity)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 6 * unit))

            Button(action: { isPickerOpen = false }) {
                Text("Done")
                    .font(.system(size: 4.4 * unit, weight: .semibold))
                    .foregroundStyle(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3.5 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 5 * unit)
        .padding(.bottom, 5 * unit)
        .background(AppColors.background)
        .presentationDetents([.height(95 * unit)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(7 * unit)
    }

    // Minutes from midnight -> a Date of today, only to feed the picker
    private func dateFromMinutes(_ minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    // A Date from the picker -> minutes from midnight
    private func minutesFromDate(_ date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
}

// MARK: - Previews
#Preview("Light") {
    ReminderTimeRow(dayName: "Mon", minutes: 1080, timeText: "18:00", unit: 3.9,
                    onPickTime: { _ in })
        .padding(20)
        .background(AppColors.card)
}

#Preview("Dark") {
    ReminderTimeRow(dayName: "Mon", minutes: 1080, timeText: "18:00", unit: 3.9,
                    onPickTime: { _ in })
        .padding(20)
        .background(AppColors.card)
        .preferredColorScheme(.dark)
}
