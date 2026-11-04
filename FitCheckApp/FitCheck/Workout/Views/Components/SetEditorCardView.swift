//
//  SetEditorCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The white card with Reps and Weight (− and +) and the main button:
// "Complete set" for the current set, "Save changes" when a done set is edited.
struct SetEditorCardView: View {
    let reps: Int
    let weight: Double
    let isEditing: Bool
    let unit: CGFloat
    let onReps: (Int) -> Void
    let onWeight: (Double) -> Void
    let onTapReps: () -> Void       // tap on the number: opens the wheel
    let onTapWeight: () -> Void
    let onMainButton: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(title: "Reps",
                value: "\(reps)", unitText: nil,
                onTapValue: onTapReps,
                onMinus: { onReps(-1) }, onPlus: { onReps(1) })

            Divider().overlay(AppColors.divider)

            row(title: "Weight",
                value: WorkoutFormat.weight(weight), unitText: "kg",
                onTapValue: onTapWeight,
                onMinus: { onWeight(-WorkoutRules.weightStep) },
                onPlus: { onWeight(WorkoutRules.weightStep) })

            WorkoutBigButton(title: isEditing ? "Save changes" : "Complete set",
                             style: isEditing ? .black : .yellow,
                             unit: unit, action: onMainButton)
                .padding(.top, AppSizes.Space.group * unit)
        }
        .padding(.horizontal, 4 * unit)
        .padding(.top, AppSizes.Space.related * unit)
        .padding(.bottom, 4 * unit)
        .frame(height: WorkoutRules.cardHeightUnits * unit, alignment: .top)   // same height as the rest card
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    private func row(title: String, value: String, unitText: String?,
                     onTapValue: @escaping () -> Void,
                     onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            stepButton(symbol: "minus", label: "Less \(title.lowercased())", action: onMinus)
            // The number is a button: it opens the iPhone wheel to choose faster
            Button(action: onTapValue) {
                HStack(alignment: .firstTextBaseline, spacing: AppSizes.Space.tight * unit) {
                    Text(value)
                        .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                    if let unitText {
                        Text(unitText)
                            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .frame(minWidth: 20 * unit, minHeight: 12.5 * unit)
                .padding(.horizontal, AppSizes.Space.related * unit)
                .background(AppColors.background, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) \(value). Tap to choose.")
            stepButton(symbol: "plus", label: "More \(title.lowercased())", action: onPlus)
        }
        .frame(height: 16.5 * unit)
    }

    private func stepButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 12.5 * unit, height: 12.5 * unit)
                .background(AppColors.cardAlt, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview("Light") {
    SetEditorCardView(reps: 10, weight: 60, isEditing: false, unit: 3.9,
                      onReps: { _ in }, onWeight: { _ in },
                      onTapReps: {}, onTapWeight: {}, onMainButton: {})
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SetEditorCardView(reps: 10, weight: 62.5, isEditing: true, unit: 3.9,
                      onReps: { _ in }, onWeight: { _ in },
                      onTapReps: {}, onTapWeight: {}, onMainButton: {})
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
