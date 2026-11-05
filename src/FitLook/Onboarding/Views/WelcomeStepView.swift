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
}

// MARK: - The rainbow
// A quarter of a circle, centred on the top right corner of the SCREEN (it goes under the
// status bar). 6 concentric bands, from the outside: purple, blue, green, yellow, orange, red,
// each one split from the next by a thin white line. The inside of the red band is empty.
//  All values are in units (1% of the screen width).
struct RainbowArcView: View {
    static let innerRadius: CGFloat = 14
    static let bandWidth: CGFloat = 3.96
    static let lineWidth: CGFloat = 0.4

    var body: some View {
        // It measures its own width: 1 unit = 1% of the screen width
        GeometryReader { geo in
            arc(unit: geo.size.width / 100)
        }
    }

    @ViewBuilder
    private func arc(unit: CGFloat) -> some View {
        // PlanPalette is red...purple: reversed, the first band (outer) is purple
        let colors = Array(PlanPalette.colors.reversed())
        let count = CGFloat(colors.count)
        let outer = Self.innerRadius + Self.bandWidth * count

        ZStack {
            ForEach(Array(colors.enumerated()), id: \.offset) { index, color in
                let mid = outer - Self.bandWidth * (CGFloat(index) + 0.5)
                Circle()
                    .stroke(color, lineWidth: Self.bandWidth * unit)
                    .frame(width: mid * 2 * unit, height: mid * 2 * unit)
            }
            // The thin white lines between the bands (and on the outer edge)
            ForEach(0..<colors.count, id: \.self) { index in
                let edge = outer - Self.bandWidth * CGFloat(index)
                Circle()
                    .stroke(Color.white, lineWidth: Self.lineWidth * unit)
                    .frame(width: edge * 2 * unit, height: edge * 2 * unit)
            }
        }
        .frame(width: 0, height: 0)   // a point: the circles are centred on it
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
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
