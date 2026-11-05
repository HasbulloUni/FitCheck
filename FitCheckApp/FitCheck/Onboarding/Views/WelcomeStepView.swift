//
//  WelcomeStepView.swift
//  FitCheck
//
//  Screen 1: the welcome and the name (optional).
//

import SwiftUI

struct WelcomeStepView: View {
    @Binding var name: String
    let unit: CGFloat

    @FocusState private var isNameFocused: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            rainbow

            VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                Spacer().frame(height: 26 * unit)

                Text("Comeback.")
                    .font(.system(size: AppSizes.Text.hero * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                Text("Train on your own, a little at a time. We build the plan, you show up.")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)

                // The name
                VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                    Text("What's your name?")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    TextField("Your name", text: $name)
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .textContentType(.givenName)
                        .padding(AppSizes.Space.section * unit)
                        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture { isNameFocused = false }
    }

    // The rainbow in the top right corner: the 6 colors of the plans
    private var rainbow: some View {
        ZStack {
            ForEach(Array(PlanPalette.colors.enumerated()), id: \.offset) { index, color in
                Circle()
                    .stroke(color, lineWidth: 3 * unit)
                    .frame(width: (46 - Double(index) * 5.5) * unit,
                           height: (46 - Double(index) * 5.5) * unit)
            }
        }
        .offset(x: 14 * unit, y: -14 * unit)
        .frame(width: 30 * unit, height: 30 * unit, alignment: .center)
        .clipped()
        .accessibilityHidden(true)
    }
}

#Preview("Light") {
    WelcomeStepView(name: .constant("Peppino"), unit: 3.9)
        .padding(.horizontal, 23.4)
        .background(AppColors.background)
}

#Preview("Dark") {
    WelcomeStepView(name: .constant("Peppino"), unit: 3.9)
        .padding(.horizontal, 23.4)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    WelcomeStepView(name: .constant(""), unit: 3.9)
        .padding(.horizontal, 23.4)
        .background(AppColors.background)
}
