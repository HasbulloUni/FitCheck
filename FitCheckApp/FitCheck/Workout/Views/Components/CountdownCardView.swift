//
//  CountdownCardView.swift
//  FitCheck
//
//  The only timer card of the workout: big numbers that go down, no ring, no bar.
//  The warm-up, the cool-down and the rest between sets all use it.
//  The buttons under the numbers change (Start, or +15 s and Skip rest).
//

import SwiftUI

struct CountdownCardView<Actions: View>: View {
    let title: String          // e.g. "REST", "TIME LEFT", "DONE"
    let remaining: Int         // seconds
    let subtitle: String?      // e.g. "next: set 3" (nil = nothing)
    let unit: CGFloat
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(spacing: AppSizes.Space.group * unit) {
            Text(title)
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textSecondary)

            VStack(spacing: AppSizes.Space.tight * unit) {
                Text(WorkoutFormat.clock(remaining))
                    .font(.system(size: AppSizes.Text.hero * unit * 1.6, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: AppSizes.Text.caption * unit))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            actions()
        }
        .padding(AppSizes.Space.section * unit)
        .frame(maxWidth: .infinity)
        .frame(height: WorkoutRules.cardHeightUnits * unit)   // same height as the Reps/Weight card
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

// The yellow "Start" button of a timer that has not started yet
struct TimerStartButton: View {
    let unit: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Start")
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(Color(light: 0x111111, dark: 0x111111))
                .frame(maxWidth: .infinity)
                .frame(height: 11 * unit)
                .background(AppColors.yellow, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    VStack {
        CountdownCardView(title: "TIME LEFT", remaining: 480, subtitle: nil, unit: 3.9) {
            TimerStartButton(unit: 3.9, action: {})
        }
        CountdownCardView(title: "REST", remaining: 45, subtitle: "next: set 3", unit: 3.9) { EmptyView() }
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    CountdownCardView(title: "REST", remaining: 45, subtitle: "next: set 3", unit: 3.9) { EmptyView() }
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
