//
//  RestCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The rest between two sets: a big ring with the time left, "+15 s" and "Skip rest".
struct RestCardView: View {
    let remaining: Int
    let total: Int
    let unit: CGFloat
    let nextSetNumber: Int
    let onAdd: () -> Void
    let onSkip: () -> Void

    // 1 = full ring, 0 = empty ring
    private var progress: Double {
        total > 0 ? min(1, Double(remaining) / Double(total)) : 0
    }

    var body: some View {
        VStack(spacing: AppSizes.Space.group * unit) {
            Text("REST")
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textSecondary)

            ZStack {
                Circle().stroke(AppColors.cardAlt, lineWidth: 3 * unit)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.textPrimary, style: StrokeStyle(lineWidth: 3 * unit, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remaining)
                VStack(spacing: AppSizes.Space.tight * unit) {
                    Text(WorkoutFormat.clock(remaining))
                        .font(.system(size: AppSizes.Text.display * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                    Text("next: set \(nextSetNumber)")
                        .font(.system(size: AppSizes.Text.caption * unit))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(width: 28 * unit, height: 28 * unit)

            HStack(spacing: AppSizes.Space.related * unit) {
                Button(action: onAdd) {
                    Text("+15 s")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 11 * unit)
                        .background(AppColors.cardAlt, in: Capsule())
                }
                .buttonStyle(.plain)

                Button(action: onSkip) {
                    Text("Skip rest")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                        .foregroundStyle(Color(light: 0x111111, dark: 0x111111))
                        .frame(maxWidth: .infinity)
                        .frame(height: 11 * unit)
                        .background(AppColors.yellow, in: Capsule())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            }
        }
        .padding(AppSizes.Space.section * unit)
        .frame(maxWidth: .infinity)
        .frame(height: WorkoutRules.cardHeightUnits * unit)   // same height as the Reps/Weight card
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

// The small black bar with the rest, shown while a done set is being edited
struct RestBarView: View {
    let remaining: Int
    let total: Int
    let unit: CGFloat
    let onSkip: () -> Void

    private var progress: Double {
        total > 0 ? min(1, Double(remaining) / Double(total)) : 0
    }

    var body: some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Text("REST")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                .foregroundStyle(.white.opacity(0.7))
            Text(WorkoutFormat.clock(remaining))
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(.white)
                .monospacedDigit()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.2))
                    Capsule().fill(AppColors.yellow).frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 1.6 * unit)
            Button(action: onSkip) {
                Text("Skip")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                    .foregroundStyle(Color(light: 0x111111, dark: 0x111111))
                    .padding(.horizontal, 4.5 * unit)
                    .frame(height: 11 * unit)
                    .background(AppColors.yellow, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 4.5 * unit)
        .padding(.trailing, 1.5 * unit)
        .frame(height: 14 * unit)
        .background(Color(light: 0x111111, dark: 0x111111), in: Capsule())
    }
}

#Preview("Light") {
    VStack {
        RestCardView(remaining: 45, total: 90, unit: 3.9, nextSetNumber: 3, onAdd: {}, onSkip: {})
        RestBarView(remaining: 38, total: 90, unit: 3.9, onSkip: {})
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack {
        RestCardView(remaining: 45, total: 90, unit: 3.9, nextSetNumber: 3, onAdd: {}, onSkip: {})
        RestBarView(remaining: 38, total: 90, unit: 3.9, onSkip: {})
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
