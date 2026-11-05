//
//  PlanChoiceStepView.swift
//  FitCheck
//
//  Screen 4: two Ready-made cards (Full body, Muscle groups) and, below them,
//  the button "Build your own plan", which opens the plan creator as a new screen.
//

import SwiftUI

struct PlanChoiceStepView: View {
    @Binding var choice: PlanChoice
    let level: ReadyMadeLevel
    let dayCount: Int
    let unit: CGFloat
    let onPickCustom: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            OnboardingTitleView(title: "How do you want to train?",
                                subtitle: "Pick a ready-made plan, or build your own.",
                                unit: unit)

            Text("\(level.title.uppercased()) · \(dayCount) \(dayCount == 1 ? "DAY" : "DAYS") A WEEK")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
                .tracking(0.2 * unit)
                .foregroundStyle(AppColors.textSecondary)

            VStack(spacing: AppSizes.Space.group * unit) {
                ForEach(ReadyMadeStyle.allCases) { style in
                    card(title: style.title,
                         detail: detail(for: style),
                         isSelected: choice == .ready(style)) {
                        choice = .ready(style)
                    }
                }
            }

            buildOwnButton

            Text("Plans are general suggestions, not medical advice.")
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // The names of the plans for the days chosen (same splits as the Ready-made catalog)
    private func detail(for style: ReadyMadeStyle) -> String {
        switch style {
        case .fullBody:
            let letters = ["A", "B", "C", "D", "E"].prefix(max(dayCount, 2))
            return "Full body " + letters.joined(separator: " · ")
        case .muscleGroups:
            switch dayCount {
            case 2:  return "Upper · Lower"
            case 4:  return "Upper A · Lower A · Upper B · Lower B"
            case 5:  return "Push · Pull · Legs · Upper · Lower"
            default: return "Push · Pull · Legs"
            }
        }
    }

    // A separate dashed button: it opens the creator for a custom plan
    private var buildOwnButton: some View {
        Button(action: onPickCustom) {
            HStack {
                Image(systemName: "plus")
                Spacer()
                Text("Build your own plan")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
            .padding(AppSizes.Space.section * unit)
            .frame(maxWidth: .infinity, minHeight: 15 * unit)
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit)
                    .strokeBorder(AppColors.textSecondary,
                                  style: StrokeStyle(lineWidth: 0.4 * unit, dash: [1 * unit, 0.8 * unit]))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // A white card with a green border and a green check on the chosen one
    private func card(title: String, detail: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                    Text(title)
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(detail)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColors.green : AppColors.divider)
            }
            .padding(AppSizes.Space.section * unit)
            .frame(maxWidth: .infinity, minHeight: 19 * unit)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit)
                    .stroke(isSelected ? AppColors.green : .clear, lineWidth: 0.5 * unit)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Light") {
    PlanChoiceStepView(choice: .constant(.ready(.fullBody)), level: .intermediate, dayCount: 3, unit: 3.9, onPickCustom: {})
        .padding(23.4)
        .background(AppColors.background)
}

#Preview("Dark") {
    PlanChoiceStepView(choice: .constant(.ready(.muscleGroups)), level: .beginner, dayCount: 3, unit: 3.9, onPickCustom: {})
        .padding(23.4)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PlanChoiceStepView(choice: .constant(.ready(.fullBody)), level: .beginner, dayCount: 0, unit: 3.9, onPickCustom: {})
        .padding(23.4)
        .background(AppColors.background)
}
