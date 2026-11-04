//
//  TimedStepCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The card of a warm-up or cool-down step: the time left, counting down.
// At zero it shows "Done": the user can also go on before, with the button below.
struct TimedStepCardView: View {
    let remaining: Int
    let total: Int
    let unit: CGFloat

    private var progress: Double {
        total > 0 ? min(1, Double(remaining) / Double(total)) : 0
    }

    var body: some View {
        VStack(spacing: AppSizes.Space.group * unit) {
            Text(remaining == 0 ? "DONE" : "TIME LEFT")
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textSecondary)

            Text(WorkoutFormat.clock(remaining))
                .font(.system(size: AppSizes.Text.hero * unit * 1.6, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.cardAlt)
                    Capsule().fill(AppColors.yellow).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 2 * unit)
        }
        .padding(5 * unit)
        .frame(maxWidth: .infinity)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

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
        .padding(4 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

#Preview("Light") {
    VStack {
        TimedStepCardView(remaining: 192, total: 480, unit: 3.9)
        SetsDoneCardView(setCount: 3, heaviest: 62.5, unit: 3.9)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack {
        TimedStepCardView(remaining: 192, total: 480, unit: 3.9)
        SetsDoneCardView(setCount: 3, heaviest: 62.5, unit: 3.9)
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
