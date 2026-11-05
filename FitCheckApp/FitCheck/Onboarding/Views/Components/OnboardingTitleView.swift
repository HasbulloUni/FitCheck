//
//  OnboardingTitleView.swift
//  FitCheck
//
//  Big title and a short line under it: the start of every onboarding screen.
//

import SwiftUI

struct OnboardingTitleView: View {
    let title: String
    let subtitle: String
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            Text(title)
                .font(.system(size: AppSizes.Text.hero * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(.system(size: AppSizes.Text.body * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Light") {
    OnboardingTitleView(title: "Your level", subtitle: "We pick the right plans for you.", unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    OnboardingTitleView(title: "Your level", subtitle: "We pick the right plans for you.", unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    OnboardingTitleView(title: "", subtitle: "", unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}
