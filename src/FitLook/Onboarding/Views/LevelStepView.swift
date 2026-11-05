//
//  LevelStepView.swift
//  FitCheck
//
//  Screen 2: the level. Three big colored cards with a big number.
//

import SwiftUI

struct LevelStepView: View {
    @Binding var level: ReadyMadeLevel
    let unit: CGFloat

    // Text and color of each level
    private func info(_ level: ReadyMadeLevel) -> (number: String, text: String, color: Color) {
        switch level {
        case .beginner:     return ("1", "New to training, or back after a break.", AppColors.green)
        case .intermediate: return ("2", "You train and know the main exercises.", AppColors.yellow)
        case .advanced:     return ("3", "You train hard and want more volume.", AppColors.red)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            OnboardingTitleView(title: "Your level",
                                subtitle: "Be honest, you can change it later.",
                                unit: unit)

            VStack(spacing: AppSizes.Space.group * unit) {
                ForEach(ReadyMadeLevel.allCases) { item in
                    card(for: item)
                }
            }
        }
    }

    private func card(for item: ReadyMadeLevel) -> some View {
        let data = info(item)
        let isSelected = level == item

        return Button { level = item } label: {
            HStack(spacing: AppSizes.Space.section * unit) {
                Text(data.number)
                    .font(.system(size: AppSizes.Text.hero * unit, weight: .heavy))

                VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                    Text(item.title)
                        .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    Text(data.text)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .medium))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .semibold))
            }
            // The text is always dark: the cards are bright in light and dark mode
            .foregroundStyle(Color(light: 0x111111, dark: 0x111111))
            .padding(AppSizes.Space.section * unit)
            // The same height for the three cards, whatever the length of the text
            .frame(height: 24 * unit)
            .background(data.color, in: RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
            .opacity(isSelected ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Light") {
    LevelStepView(level: .constant(.beginner), unit: 3.9)
        .padding(23.4)
        .background(AppColors.background)
}

#Preview("Dark") {
    LevelStepView(level: .constant(.intermediate), unit: 3.9)
        .padding(23.4)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    LevelStepView(level: .constant(.advanced), unit: 3.9)
        .padding(23.4)
        .background(AppColors.background)
}
