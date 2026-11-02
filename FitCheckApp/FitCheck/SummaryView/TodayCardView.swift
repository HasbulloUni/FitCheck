//
//  TodayCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// BLOCK 3 - The yellow "Today" card: the workout of the day with a Start button.
// Every measure is a multiple of "unit" (1% of the screen width).

// MARK: - The data shown in the card
// Only data, no logic. Later it will come from the user's plans.
struct TodayPlan {
    let name: String          // e.g. "Full body A"
    let minutes: Int          // e.g. 67
    let exerciseCount: Int    // e.g. 11
}

// MARK: - The card
struct TodayCardView: View {
    let plan: TodayPlan
    let unit: CGFloat   // 1% of the screen width
    let onStart: () -> Void   // what happens when the user taps Start

    var body: some View {
        HStack(spacing: 3 * unit) {

            // Left side: label, plan name, details
            VStack(alignment: .leading, spacing: 1.5 * unit) {
                Text("TODAY")
                    .font(.system(size: 3.2 * unit, weight: .bold))
                    .foregroundStyle(.black.opacity(0.7))

                Text(plan.name)
                    .font(.system(size: 6 * unit, weight: .bold))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("\(plan.minutes) min · \(plan.exerciseCount) exercises")
                    .font(.system(size: 3.6 * unit, weight: .medium))
                    .foregroundStyle(.black.opacity(0.8))
                    .minimumScaleFactor(0.8)   // shrinks a little instead of wrapping
                    .lineLimit(1)
            }

            Spacer()

            // Right side: Start button
            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: 4.4 * unit, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6 * unit)
                    .padding(.vertical, 3.5 * unit)
                    .background(.black, in: Capsule())
            }
        }
        .padding(5 * unit)
        // The card stays yellow with black text in light and dark mode, so fixed black and white on purpose
        .background(AppColors.yellow, in: RoundedRectangle(cornerRadius: 6 * unit))
    }
}

// MARK: - The card when there is no workout yet
// Shown instead of TodayCardView when the user has not chosen a workout for today.
struct TodayEmptyCardView: View {
    let unit: CGFloat
    let onAddPlan: () -> Void   // what happens when the user taps "Add plan"

    var body: some View {
        HStack(spacing: 3 * unit) {

            // Left side: label, message and hint, one under the other
            VStack(alignment: .leading, spacing: 1.5 * unit) {
                Text("TODAY")
                    .font(.system(size: 3.2 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)

                Text("No workout yet")
                    .font(.system(size: 6 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("Add a plan to see it here")
                    .font(.system(size: 3.6 * unit, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }

            Spacer()

            // Right side: the button that invites the user to add a plan
            Button(action: onAddPlan) {
                Text("Add plan")
                    .font(.system(size: 4.4 * unit, weight: .semibold))
                    .foregroundStyle(AppColors.background)
                    .padding(.horizontal, 6 * unit)
                    .padding(.vertical, 3.5 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
        }
        .padding(5 * unit)
        // Dashed border: it says "something is missing here"
        .overlay(
            RoundedRectangle(cornerRadius: 6 * unit)
                .strokeBorder(
                    AppColors.textSecondary,
                    style: StrokeStyle(lineWidth: 0.4 * unit, dash: [1 * unit, 0.8 * unit])
                )
        )
    }
}

// MARK: - Previews
// Sample data used only by the previews
private let samplePlan = TodayPlan(name: "Full body A", minutes: 67, exerciseCount: 11)

// unit 3.9 = an iPhone that is 390 pt wide
#Preview("Light") {
    TodayCardView(plan: samplePlan, unit: 3.9, onStart: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    TodayCardView(plan: samplePlan, unit: 3.9, onStart: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    TodayEmptyCardView(unit: 3.9, onAddPlan: {})
        .padding(20)
        .background(AppColors.background)
}
