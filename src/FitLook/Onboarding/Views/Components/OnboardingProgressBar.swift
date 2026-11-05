//
//  OnboardingProgressBar.swift
//  FitCheck
//
//  The 4 pieces of the progress bar of the onboarding: done = dark, current = yellow,
//  next = grey. A soft shadow under each piece keeps it visible on any color
//  (also the yellow plan color of the Custom screen).
//

import SwiftUI

struct OnboardingProgressBar: View {
    let position: Int            // 1...4: the step we are on
    let unit: CGFloat
    var onColor = false          // true when the bar sits on the color of a plan (the next pieces are white)

    var body: some View {
        HStack(spacing: AppSizes.Space.tight * unit) {
            ForEach(1...OnboardingStep.barSteps, id: \.self) { index in
                Capsule()
                    .fill(color(for: index))
                    .frame(height: 1.5 * unit)
                    .shadow(color: .black.opacity(0.4), radius: 0.5 * unit, x: 0, y: 0.5 * unit)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(position) of \(OnboardingStep.barSteps)")
    }

    private func color(for index: Int) -> Color {
        if index < position { return AppColors.textPrimary }
        if index == position { return AppColors.yellow }
        return onColor ? Color.white.opacity(0.6) : AppColors.divider
    }
}

#Preview("Light") {
    OnboardingProgressBar(position: 3, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    OnboardingProgressBar(position: 2, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    OnboardingProgressBar(position: 3, unit: 3.9, onColor: true)
        .padding(20)
        .background(PlanPalette.colors[2])
}
