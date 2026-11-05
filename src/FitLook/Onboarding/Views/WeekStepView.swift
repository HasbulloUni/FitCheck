//
//  WeekStepView.swift
//  FitCheck
//
//  Screen 3: the training days and the reminder.
//  It reuses DayCirclesRow and ReminderCard of Edit week, with the same rules.
//

import SwiftUI

struct WeekStepView: View {
    let viewModel: EditWeekViewModel
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            OnboardingTitleView(title: "Your week",
                                subtitle: "Start small. Three days a week is enough to see change.",
                                unit: unit)

            VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
                Text(EditWeekRules.daysQuestion)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                DayCirclesRow(
                    selectedWeekdays: viewModel.draft.workoutWeekdays,
                    unit: unit,
                    onToggle: { viewModel.toggleDay($0) }
                )
            }

            VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
                Text(EditWeekRules.startQuestion)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                ReminderCard(
                    remindMe: viewModel.draft.remindMe,
                    reminders: viewModel.draft.reminders,
                    unit: unit,
                    timeText: { viewModel.timeText($0) },
                    onSwitch: { viewModel.setRemindMe($0) },
                    onPickTime: { viewModel.setTime(weekday: $0, minutes: $1) }
                )

                Text("A reminder helps you show up. You can change it any time in Edit week.")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

private func previewViewModel(days: [Int]) -> EditWeekViewModel {
    let viewModel = EditWeekViewModel(week: WeekData(), savedPlan: nil, plans: [])
    for day in days { viewModel.toggleDay(day) }
    return viewModel
}

#Preview("Light") {
    WeekStepView(viewModel: previewViewModel(days: [2, 4, 6]), unit: 3.9)
        .padding(23.4)
        .background(AppColors.background)
}

#Preview("Dark") {
    WeekStepView(viewModel: previewViewModel(days: [2, 4, 6]), unit: 3.9)
        .padding(23.4)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    WeekStepView(viewModel: previewViewModel(days: []), unit: 3.9)
        .padding(23.4)
        .background(AppColors.background)
}
