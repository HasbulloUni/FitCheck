//
//  TimedStepCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The card shown when all the sets of an exercise are done
struct SetsDoneCardView: View {
    let setCount: Int
    let heaviest: Double
    let unit: CGFloat

    var body: some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Image(systemName: "checkmark")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 11 * unit, height: 11 * unit)
                .background(AppColors.greenSoft, in: Circle())
            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text("All sets done")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                Text(heaviest > 0
                     ? "\(setCount) sets · heaviest \(WorkoutFormat.weight(heaviest)) kg"
                     : "\(setCount) sets")
                    .font(.system(size: AppSizes.Text.small * unit))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
        .padding(AppSizes.Space.section * unit)
        .frame(height: WorkoutRules.cardHeightUnits * unit)   // same height as the Reps/Weight card
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

#Preview("Light") {
    VStack {
        SetsDoneCardView(setCount: 3, heaviest: 62.5, unit: 3.9)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack {
        SetsDoneCardView(setCount: 3, heaviest: 62.5, unit: 3.9)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
