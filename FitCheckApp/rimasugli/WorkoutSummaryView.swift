//
//  WorkoutSummaryView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The end screen: time, sets, and the weights of today compared with the last time.
// The workout is already saved when this appears. "Done" closes the workout.
struct WorkoutSummaryView: View {
    let planName: String
    let summary: WorkoutSummary
    let unit: CGFloat
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: AppSizes.Space.section * unit) {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                    VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                        Image(systemName: summary.isCompleted ? "checkmark.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 12 * unit))
                            .foregroundStyle(summary.isCompleted ? AppColors.greenSoft : AppColors.yellow)
                        Text(summary.isCompleted ? "\(planName) done" : "Workout saved")
                            .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                        Text(summary.isCompleted
                             ? "Saved in Progress."
                             : "Your sets are saved in Progress. The plan does not count as done.")
                            .font(.system(size: AppSizes.Text.body * unit))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    HStack(spacing: AppSizes.Space.related * unit) {
                        statCard(value: "\(summary.minutes)", title: "min")
                        statCard(value: "\(summary.setsDone)", title: "sets")
                        statCard(value: "\(summary.exercisesDone)/\(summary.exercisesTotal)", title: "exercises")
                    }

                    if !summary.loads.isEmpty {
                        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
                            Text("Weights vs last time")
                                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                                .foregroundStyle(AppColors.textPrimary)
                            ForEach(summary.loads) { line in
                                loadRow(line)
                            }
                        }
                        .padding(4 * unit)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
                    }
                }
            }
            WorkoutBigButton(title: "Done", style: .yellow, unit: unit, action: onDone)
        }
        .padding(.horizontal, 5 * unit)
        .padding(.vertical, 5 * unit)
    }

    private func statCard(value: String, title: String) -> some View {
        VStack(spacing: AppSizes.Space.tight * unit) {
            Text(value)
                .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()
            Text(title)
                .font(.system(size: AppSizes.Text.small * unit))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3.5 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    private func loadRow(_ line: WorkoutSummary.LoadLine) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Text(line.name)
                .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
            Spacer()
            Text("\(WorkoutFormat.weight(line.weight)) kg")
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
            if let change = line.change, change > 0 {
                Text("+\(WorkoutFormat.weight(change))")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                    .foregroundStyle(Color(light: 0x111111, dark: 0x111111))
                    .padding(.horizontal, 2 * unit)
                    .padding(.vertical, AppSizes.Space.tight * unit)
                    .background(AppColors.yellow, in: Capsule())
            }
        }
    }
}

#Preview("Light") {
    WorkoutSummaryView(planName: "Legs day", summary: WorkoutPreviewData.summary, unit: 3.9, onDone: {})
        .background(AppColors.background)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    WorkoutSummaryView(planName: "Legs day", summary: WorkoutPreviewData.summary, unit: 3.9, onDone: {})
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
