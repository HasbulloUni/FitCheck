//
//  GoalsSectionView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// BLOCK 4 - The "Goals" section: the title and two rows of three goal cards.
// First row: the goals of the week. Second row: the goals of the month.
// Every size is a multiple of "unit" (1% of the screen width), like the other blocks.

// MARK: - The section
struct GoalsSectionView: View {
    let weekGoals: [GoalItem]
    let monthGoals: [GoalItem]
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {

            // Title
            Text("Goals")
                .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            // Week goals
            GoalsPeriodHeaderView(period: .week, unit: unit)
            GoalsRowView(goals: weekGoals, unit: unit)

            // Month goals
            GoalsPeriodHeaderView(period: .month, unit: unit)
            GoalsRowView(goals: monthGoals, unit: unit)
        }
    }
}

// MARK: - A row of goal cards
// The cards share the width in equal parts and all get the height of the tallest one.
struct GoalsRowView: View {
    let goals: [GoalItem]
    let unit: CGFloat

    var body: some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            ForEach(goals) { goal in
                GoalCardView(goal: goal, unit: unit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fixedSize(horizontal: false, vertical: true)   // same height for every card
    }
}

// MARK: - One goal card
// The ring on top, only the name of the goal under it.
struct GoalCardView: View {
    let goal: GoalItem
    let unit: CGFloat

    var body: some View {
        VStack(spacing: AppSizes.Space.related * unit) {
            GoalRingView(
                progress: goal.progress,
                color: goal.color,
                centerText: goal.centerText,
                size: 13 * unit,
                lineWidth: 1.4 * unit,
                fontSize: AppSizes.Text.small * unit,
                caption: nil
            )

            // Only the name of the goal
            Text(goal.title)
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 3 * unit)
        .padding(.horizontal, 1.5 * unit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)   // all cards get the same size
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

// MARK: - The "Add goal" card
// Same shape as a goal card, with a dashed circle and a plus.
// The Goals section does not use it anymore, but "My plans" still does (for "Create your first plan").
struct AddGoalCardView: View {
    let title: String       // e.g. "Add goal"
    let subtitle: String    // e.g. "Pick another"
    let unit: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSizes.Space.group * unit) {

                // Dashed circle with a plus in the middle
                ZStack {
                    Circle()
                        .strokeBorder(
                            AppColors.textSecondary,
                            style: StrokeStyle(lineWidth: 0.4 * unit, dash: [1 * unit, 0.8 * unit])
                        )

                    Image(systemName: "plus")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(width: 11 * unit, height: 11 * unit)

                VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                    Text(title)
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(subtitle)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(3 * unit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        }
    }
}

// MARK: - Previews
// Sample data used only by the previews
private let sampleWeekGoals: [GoalItem] = [
    GoalItem(title: "Sessions", centerText: "1/3", subtitle: "2 to go", progress: 1.0 / 3.0, color: AppColors.muscleBlue),
    GoalItem(title: "Minutes", centerText: "85", subtitle: "95 min left", progress: 85.0 / 180.0, color: AppColors.greenSoft),
    GoalItem(title: "Strength days", centerText: "1/2", subtitle: "1 to go", progress: 0.5, color: AppColors.musclePurple)
]

private let sampleMonthGoals: [GoalItem] = [
    GoalItem(title: "Week active", centerText: "3/4", subtitle: "1 to go", progress: 0.75, color: AppColors.muscleOrange),
    GoalItem(title: "Plan completion", centerText: "75%", subtitle: "6 left", progress: 0.75, color: AppColors.muscleRed),
    GoalItem(title: "Muscle coverage", centerText: "4/6", subtitle: "2 to go", progress: 4.0 / 6.0, color: AppColors.muscleYellow)
]

#Preview("Light") {
    GoalsSectionView(weekGoals: sampleWeekGoals, monthGoals: sampleMonthGoals, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    GoalsSectionView(weekGoals: sampleWeekGoals, monthGoals: sampleMonthGoals, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    // At the start every goal is at zero
    GoalsSectionView(
        weekGoals: GoalsViewModel().weekGoals,
        monthGoals: GoalsViewModel().monthGoals,
        unit: 3.9
    )
    .padding(20)
    .background(AppColors.background)
}
