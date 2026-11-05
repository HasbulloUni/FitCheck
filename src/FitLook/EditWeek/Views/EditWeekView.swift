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
    let onReset: () -> Void       // "Reset week": the Home saves an empty week (after the question)

    // True while the question "Reset your week?" is shown
    @State private var isResetAsked = false

    init(week: WeekData, savedPlan: EditWeekDraft? = nil, plans: [PlanItem] = [],
         onBack: @escaping () -> Void, onSave: @escaping (EditWeekDraft) -> Void,
         onReset: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: EditWeekViewModel(week: week, savedPlan: savedPlan, plans: plans))
        self.onBack = onBack
        self.onSave = onSave
        self.onReset = onReset
    }

    var body: some View {
        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
                        backButton(unit: unit)

                        header(unit: unit)

                        daysSection(unit: unit)

                        rotationSection(unit: unit)

                        reminderSection(unit: unit)

                        resetButton(unit: unit)
                    }
                    .padding(.horizontal, AppSizes.Space.screen * unit)
                    .padding(.top, AppSizes.Space.section * unit)
                    .padding(.bottom, AppSizes.Space.section * unit)
                }

                saveButton(unit: unit)
            }
        }
        .background(AppColors.background)
        // Reset asks first: it cannot be undone
        .confirmationDialog("Reset your week?", isPresented: $isResetAsked, titleVisibility: .visible) {
            Button("Reset week", role: .destructive) { onReset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Training days, rotation and reminders are cleared. Your plans stay in My plans.")
        }
    }

    // MARK: - Pieces of the screen

    // "Reset week": a quiet red text at the end of the list
    private func resetButton(unit: CGFloat) -> some View {
        Button { isResetAsked = true } label: {
            Text("Reset week")
                .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                .foregroundStyle(AppColors.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSizes.Space.group * unit)
        }
        .buttonStyle(.plain)
        .padding(.top, AppSizes.Space.section * unit)
    }

    // The round back button
    private func backButton(unit: CGFloat) -> some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
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
            .font(.system(size: AppSizes.Text.hero * unit, weight: .heavy))
            .foregroundStyle(AppColors.textPrimary)
    }

    // "Which days? Pick 2 to 5" and the seven circles
    private func daysSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
            sectionTitle(EditWeekRules.daysQuestion, unit: unit)

            DayCirclesRow(
                selectedWeekdays: viewModel.draft.workoutWeekdays,
                unit: unit,
                onToggle: { viewModel.toggleDay($0) }
            )
        }
    }

    // "Plan rotation" and the card with one row for each training day
    private func rotationSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
            sectionTitle(EditWeekRules.rotationQuestion, unit: unit)

            RotationCardView(
                rows: viewModel.rotationRows,
                plans: viewModel.plans,
                unit: unit,
                onChange: { viewModel.changePlan(weekday: $0, to: $1) }
            )

            if let note = viewModel.rotationLimitNote {
                Text(note)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    // "When do you wanna start?" and the "Remind me" card
    private func reminderSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
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
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                .foregroundStyle(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4.5 * unit)
                .background(AppColors.textPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.3)
        .padding(.horizontal, AppSizes.Space.screen * unit)
        .padding(.top, 5 * unit)
        .padding(.bottom, AppSizes.Space.group * unit)
    }

    // The bold title of a section
    private func sectionTitle(_ text: String, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
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
