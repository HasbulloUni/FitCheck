//
//  OnboardingHeaderView.swift
//  FitCheck
//
//  The top of the onboarding screens: the round Back button (same as Edit week)
//  and the progress bar with one piece for each step (and the "2/4" next to it).
//

import SwiftUI

struct OnboardingHeaderView: View {
    let position: Int            // 1...4: the step we are on
    let unit: CGFloat
    let onBack: () -> Void
    var onSkip: (() -> Void)? = nil   // shows "Skip" at the right end when given

    var body: some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 12 * unit, height: 12 * unit)
                    .background(AppColors.card, in: Circle())
                    .overlay(Circle().stroke(AppColors.divider, lineWidth: 0.3 * unit))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            OnboardingProgressBar(position: position, unit: unit)

            Text("\(position)/\(OnboardingStep.barSteps)")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize()

            if let onSkip {
                Button(action: onSkip) {
                    Text("Skip")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .fixedSize()
            }
        }
    }
}

#Preview("Light") {
    OnboardingHeaderView(position: 2, unit: 3.9, onBack: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    OnboardingHeaderView(position: 2, unit: 3.9, onBack: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    OnboardingHeaderView(position: 1, unit: 3.9, onBack: {})
        .padding(20)
        .background(AppColors.background)
}
