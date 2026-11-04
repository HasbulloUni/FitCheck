//
//  ExerciseInfoSheet.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The sheet opened by "How to do it": name, muscles and the steps, one by one.
struct ExerciseInfoSheet: View {
    let step: WorkoutStep
    let unit: CGFloat
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                        Text(step.name)
                            .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                        Text(step.muscles)
                            .font(.system(size: AppSizes.Text.body * unit))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 11 * unit, height: 11 * unit)
                            .background(AppColors.cardAlt, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }

                Text("HOW TO DO IT")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                    .foregroundStyle(AppColors.muscleGreen)

                VStack(spacing: AppSizes.Space.related * unit) {
                    ForEach(Array(step.instructions.enumerated()), id: \.offset) { index, text in
                        HStack(alignment: .top, spacing: AppSizes.Space.group * unit) {
                            Text("\(index + 1)")
                                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                                .foregroundStyle(Color(light: 0x111111, dark: 0x111111))
                                .frame(width: 7 * unit, height: 7 * unit)
                                .background(AppColors.yellow, in: RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
                            Text(text)
                                .font(.system(size: AppSizes.Text.body * unit))
                                .foregroundStyle(AppColors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(3.5 * unit)
                        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
                    }
                }
            }
            .padding(5 * unit)
        }
        .background(AppColors.background)
    }
}

#Preview("Light") {
    ExerciseInfoSheet(step: WorkoutPreviewData.steps[2], unit: 3.9, onClose: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ExerciseInfoSheet(step: WorkoutPreviewData.steps[2], unit: 3.9, onClose: {})
        .preferredColorScheme(.dark)
}
