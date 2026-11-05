//
//  WorkoutHeaderView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The top row: round Back button, "EXERCISE 1 OF 11" in green, and the Finish button.
struct WorkoutHeaderView: View {
    let text: String
    let unit: CGFloat
    let onBack: () -> Void
    let onFinish: () -> Void

    var body: some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 11 * unit, height: 11 * unit)
                    .background(AppColors.card, in: Circle())
                    .overlay(Circle().stroke(AppColors.divider, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text(text)
                .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                .foregroundStyle(AppColors.muscleGreen)

            Spacer()

            Button(action: onFinish) {
                Text("Finish")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 4.5 * unit)
                    .frame(height: 11 * unit)
                    .overlay(Capsule().stroke(AppColors.textPrimary, lineWidth: 2))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Light") {
    WorkoutHeaderView(text: "EXERCISE 1 OF 11", unit: 3.9, onBack: {}, onFinish: {})
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    WorkoutHeaderView(text: "EXERCISE 1 OF 11", unit: 3.9, onBack: {}, onFinish: {})
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
