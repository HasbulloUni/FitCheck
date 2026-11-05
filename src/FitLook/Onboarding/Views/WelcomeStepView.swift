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
                // Space for the arc: the text starts below the lowest ring
                Spacer().frame(height: 40 * unit)

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
                        .onChange(of: name) { _, value in
                            // The name is cut at 30 characters
                            if value.count > 30 { name = String(value.prefix(30)) }
                        }
                        .padding(AppSizes.Space.section * unit)
                        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture { isNameFocused = false }
    }

    // Size of the Skip button (drawn by OnboardingFlowView, top right). It is fixed, so the
    // centre of the rainbow can be put exactly on its centre.
    static let skipWidth: CGFloat = 16
    static let skipHeight: CGFloat = 8

    // The rainbow is only an ARC: the circles are very big and their centre is OUTSIDE the
    // screen (above and to the right of Skip), so only a band of each circle is seen.
    // Skip does not move and stays inside the smallest circle (its distance from the centre
    // is about 28 units, the smallest radius is 38).
    // All values are in units (1% of the screen width), so it looks the same on every iPhone.
    static let centerShiftX: CGFloat = 20     // centre is 20 units to the right of Skip's centre
    static let centerShiftY: CGFloat = -20    // and 20 units above it
    static let smallestRadius: CGFloat = 38
    static let ringStep: CGFloat = 6

    private var rainbow: some View {
        ZStack {
            ForEach(Array(PlanPalette.colors.enumerated()), id: \.offset) { index, color in
                // index 0 (red) is the biggest circle, the last one (purple) the smallest
                let radius = Self.smallestRadius + Self.ringStep * CGFloat(PlanPalette.colors.count - 1 - index)
                Circle()
                    .stroke(color, lineWidth: 3 * unit)
                    .frame(width: radius * 2 * unit, height: radius * 2 * unit)
            }
        }
        .frame(width: 0, height: 0)   // a point: the circles are centred on it
        .offset(x: (-Self.skipWidth / 2 + Self.centerShiftX) * unit,
                y: (Self.skipHeight / 2 + Self.centerShiftY) * unit)
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
