//
//  GoalsSectionView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// BLOCK 4 - The "Goals" section: a title with "See all" and a grid of goal cards.
// Every size is a multiple of "unit" (1% of the screen width), like the other blocks.

// MARK: - The section
struct GoalsSectionView: View {
    let goals: [GoalItem]
    let unit: CGFloat
    let onSeeAll: () -> Void
    let onAddGoal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3 * unit) {

            // Title row: "Goals" on the left, "See all" on the right
            HStack {
                Text("Goals")
                    .font(.system(size: 6 * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button(action: onSeeAll) {
                    Text("See all")
                        .font(.system(size: 3.8 * unit, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if goals.isEmpty {
                // No goals yet: one wide card that invites the user to pick the first goal
                AddGoalCardView(title: "No goals yet", subtitle: "Pick your first goal", unit: unit, onTap: onAddGoal)
            } else {
                // Grid with 2 columns, with the goals and the "Add goal" card at the end.
                // Both columns share the free width in equal parts.
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 3 * unit),
                        GridItem(.flexible(), spacing: 3 * unit)
                    ],
                    spacing: 3 * unit
                ) {
                    // One card for each goal
                    ForEach(goals) { goal in
                        GoalCardView(goal: goal, unit: unit)
                    }

                    AddGoalCardView(title: "Add goal", subtitle: "Pick another", unit: unit, onTap: onAddGoal)
                }
            }
        }
    }
}

// MARK: - One goal card
// A progress ring on the left, title and subtitle on the right.
struct GoalCardView: View {
    let goal: GoalItem
    let unit: CGFloat

    var body: some View {
        HStack(spacing: 3 * unit) {

            // The ring: grey circle, colored arc on top, text in the middle
            ZStack {
                Circle()
                    .stroke(AppColors.divider, lineWidth: 1.2 * unit)

                Circle()
                    .trim(from: 0, to: goal.progress)   // draws only a part of the circle
                    .stroke(goal.color, style: StrokeStyle(lineWidth: 1.2 * unit, lineCap: .round))
                    .rotationEffect(.degrees(-90))      // the arc starts from the top

                Text(goal.centerText)
                    .font(.system(size: 3.2 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(width: 11 * unit, height: 11 * unit)

            // Title and subtitle, one under the other
            VStack(alignment: .leading, spacing: 0.5 * unit) {
                Text(goal.title)
                    .font(.system(size: 4.2 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(goal.subtitle)
                    .font(.system(size: 3.4 * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(3 * unit)
        .frame(maxWidth: .infinity, alignment: .leading)   // all cards get the same width
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 5 * unit))
    }
}

// MARK: - The "Add goal" card
// Same shape as a goal card, with a dashed circle and a plus.
struct AddGoalCardView: View {
    let title: String       // e.g. "Add goal"
    let subtitle: String    // e.g. "Pick another"
    let unit: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 3 * unit) {

                // Dashed circle with a plus in the middle
                ZStack {
                    Circle()
                        .strokeBorder(
                            AppColors.textSecondary,
                            style: StrokeStyle(lineWidth: 0.4 * unit, dash: [1 * unit, 0.8 * unit])
                        )

                    Image(systemName: "plus")
                        .font(.system(size: 4.5 * unit, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(width: 11 * unit, height: 11 * unit)

                VStack(alignment: .leading, spacing: 0.5 * unit) {
                    Text(title)
                        .font(.system(size: 4.2 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(subtitle)
                        .font(.system(size: 3.4 * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(3 * unit)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 5 * unit))
        }
    }
}

// MARK: - Previews
// Sample data used only by the previews
private let sampleGoals: [GoalItem] = [
    
]

#Preview("Light") {
    GoalsSectionView(goals: sampleGoals, unit: 3.9, onSeeAll: {}, onAddGoal: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    GoalsSectionView(goals: sampleGoals, unit: 3.9, onSeeAll: {}, onAddGoal: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    GoalsSectionView(goals: [], unit: 3.9, onSeeAll: {}, onAddGoal: {})
        .padding(20)
        .background(AppColors.background)
}
