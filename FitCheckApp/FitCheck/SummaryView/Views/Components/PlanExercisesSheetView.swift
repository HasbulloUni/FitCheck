//
//  PlanExercisesSheetView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import SwiftUI

// The content of the bottom sheet that opens when a plan is tapped in "My plans".
// Only drawing: the plan and its lines come from the ViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other blocks.
struct PlanExercisesSheetView: View {
    let plan: PlanItem
    let lines: [PlanExerciseLine]
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            header

            ScrollView {
                exercisesCard
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, AppSizes.Space.screen * unit)
        .padding(.top, AppSizes.Space.screen * unit)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.background)
    }

    // The icon in the color of the plan, the name and the caption
    private var header: some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Image(systemName: plan.icon)
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                .foregroundStyle(plan.color)
                .frame(width: 10 * unit, height: 10 * unit)
                .background(plan.color.opacity(0.25), in: RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text(plan.name)
                    .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(plan.details)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // The rounded card with one row for each exercise
    private var exercisesCard: some View {
        VStack(spacing: 0) {
            if lines.isEmpty {
                Text("No exercises")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSizes.Space.group * unit)
            } else {
                ForEach(Array(lines.enumerated()), id: \.element.id) { position, line in
                    if position > 0 {
                        Divider()
                            .overlay(AppColors.textSecondary.opacity(0.25))
                    }
                    HStack(spacing: AppSizes.Space.group * unit) {
                        Text(line.name)
                            .font(.system(size: AppSizes.Text.body * unit, weight: .medium))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        Text(line.setsRepsText)
                            .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.vertical, AppSizes.Space.group * unit)
                    .padding(.horizontal, AppSizes.Space.group * unit)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .padding(.bottom, AppSizes.Space.screen * unit)
    }
}

// MARK: - Previews
private let previewPlan = PlanItem(
    id: UUID(), name: "Legs", icon: "figure.run", color: AppColors.muscleOrange,
    exerciseCount: 3, minutes: 60
)

private let previewLines: [PlanExerciseLine] = [
    PlanExerciseLine(id: "0-a", name: "Goblet squat", setsRepsText: "3 × 10"),
    PlanExerciseLine(id: "1-b", name: "Romanian deadlift", setsRepsText: "3 × 8-12"),
    PlanExerciseLine(id: "2-c", name: "Plank", setsRepsText: "3 × 30 s")
]

#Preview("Light") {
    PlanExercisesSheetView(plan: previewPlan, lines: previewLines, unit: 3.9)
}

#Preview("Dark") {
    PlanExercisesSheetView(plan: previewPlan, lines: previewLines, unit: 3.9)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PlanExercisesSheetView(
        plan: PlanItem(id: UUID(), name: "Empty plan", icon: "figure.run",
                       color: AppColors.muscleGreen, exerciseCount: 0, minutes: 0),
        lines: [], unit: 3.9
    )
}
