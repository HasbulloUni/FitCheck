//
//  EditWeekView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// The screen "Edit your week" (Sketch 22b): training days, session length and reminder times.
// It only draws: the data and the logic live in EditWeekViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct EditWeekView: View {
    // The ViewModel is created here, starting from the current week of the Home
    @State private var viewModel: EditWeekViewModel

    let onBack: () -> Void        // the round back button: closes the screen without saving
    let onSave: (EditWeekDraft) -> Void   // "Save changes": gives the chosen week to the Home

    init(week: WeekData, savedPlan: EditWeekDraft? = nil, onBack: @escaping () -> Void, onSave: @escaping (EditWeekDraft) -> Void) {
        _viewModel = State(initialValue: EditWeekViewModel(week: week, savedPlan: savedPlan))
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 3 * unit) {
                        backButton(unit: unit)

                        header(unit: unit)

                        daysSection(unit: unit)

                        durationSection(unit: unit)

                        reminderSection(unit: unit)
                    }
                    .padding(.horizontal, 6 * unit)
                    .padding(.top, 4 * unit)
                    .padding(.bottom, 4 * unit)
                }

                saveButton(unit: unit)
            }
        }
        .background(AppColors.background)
    }

    // MARK: - Pieces of the screen

    // The round back button
    private func backButton(unit: CGFloat) -> some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 4 * unit, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 12 * unit, height: 12 * unit)
                .background(AppColors.card, in: Circle())
                .overlay(Circle().stroke(AppColors.divider, lineWidth: 0.3 * unit))
        }
        .buttonStyle(.plain)
    }

    // The title
    private func header(unit: CGFloat) -> some View {
        Text(EditWeekRules.title)
            .font(.system(size: 9 * unit, weight: .heavy))
            .foregroundStyle(AppColors.textPrimary)
    }

    // "Which days? Pick 2 to 5" and the seven circles
    private func daysSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * unit) {
            sectionTitle(EditWeekRules.daysQuestion, unit: unit)

            DayCirclesRow(
                selectedWeekdays: viewModel.draft.workoutWeekdays,
                unit: unit,
                onToggle: { viewModel.toggleDay($0) }
            )
        }
    }

    // "How long is a session?" and the duration buttons
    private func durationSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * unit) {
            sectionTitle(EditWeekRules.durationQuestion, unit: unit)

            DurationPicker(
                durations: viewModel.durations,
                selected: viewModel.draft.durationMinutes,
                unit: unit,
                onSelect: { viewModel.selectDuration($0) }
            )
        }
    }

    // "When do you wanna start?" and the "Remind me" card
    private func reminderSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * unit) {
            sectionTitle(EditWeekRules.startQuestion, unit: unit)

            ReminderCard(
                remindMe: viewModel.draft.remindMe,
                reminders: viewModel.draft.reminders,
                unit: unit,
                timeText: { viewModel.timeText($0) },
                onSwitch: { viewModel.setRemindMe($0) },
                onPickTime: { viewModel.setTime(weekday: $0, minutes: $1) }
            )
        }
    }

    // The big "Save changes" button, fixed at the bottom. It works only with a valid number of days.
    private func saveButton(unit: CGFloat) -> some View {
        Button(action: { onSave(viewModel.draft) }) {
            Text(EditWeekRules.saveButton)
                .font(.system(size: 4.6 * unit, weight: .semibold))
                .foregroundStyle(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4.5 * unit)
                .background(AppColors.textPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.3)
        .padding(.horizontal, 6 * unit)
        .padding(.top, 5 * unit)
        .padding(.bottom, 3 * unit)
    }

    // The bold title of a section
    private func sectionTitle(_ text: String, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 4.4 * unit, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
    }
}

// MARK: - Previews
// Sample data: Monday, Wednesday and Friday are training days.
private let sampleWeek: WeekData = {
    var data = WeekData()
    data.plannedWeekdays = [2, 4, 6]
    return data
}()

#Preview("Light") {
    EditWeekView(week: sampleWeek, onBack: {}, onSave: { _ in })
}

#Preview("Dark") {
    EditWeekView(week: sampleWeek, onBack: {}, onSave: { _ in })
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    EditWeekView(week: WeekData(), onBack: {}, onSave: { _ in })
}
