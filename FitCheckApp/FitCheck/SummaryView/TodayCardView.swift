//
//  TodayCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// BLOCK 3 - The yellow "Today" card: the workout of the day with a Start button.
// Every measure is a multiple of "unit" (1% of the screen width).

// MARK: - The data shown in the card
// Only data, no logic. Later it will come from the user's plans.
struct TodayPlan {
    let name: String          // e.g. "Full body A"
    let minutes: Int          // e.g. 67
    let exerciseCount: Int    // e.g. 11
}

// MARK: - The card
struct TodayCardView: View {
    let plan: TodayPlan
    let unit: CGFloat   // 1% of the screen width
    let onStart: () -> Void   // what happens when the user taps Start

    var body: some View {
        HStack(spacing: 3 * unit) {

            // Left side: label, plan name, details
            VStack(alignment: .leading, spacing: 1.5 * unit) {
                Text("TODAY")
                    .font(.system(size: 3.2 * unit, weight: .bold))
                    .foregroundStyle(.black.opacity(0.7))

                Text(plan.name)
                    .font(.system(size: 6 * unit, weight: .bold))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("\(plan.minutes) min · \(plan.exerciseCount) exercises")
                    .font(.system(size: 3.6 * unit, weight: .medium))
                    .foregroundStyle(.black.opacity(0.8))
                    .minimumScaleFactor(0.8)   // shrinks a little on a small phone instead of wrapping
                    .lineLimit(1)
            }

            Spacer()

            // Right side: Start button
            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: 4.4 * unit, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6 * unit)
                    .padding(.vertical, 3.5 * unit)
                    .background(.black, in: Capsule())
            }
        }
        .padding(5 * unit)
        // The card stays yellow with black text in light and dark mode, so fixed black and white on purpose
        .background(AppColors.yellow, in: RoundedRectangle(cornerRadius: 7 * unit))
    }
}

// MARK: - Previews
private let samplePlan = TodayPlan(name: "Full body A", minutes: 67, exerciseCount: 11)

// unit 3.9 = an iPhone that is 390 pt wide
#Preview("Light") {
    TodayCardView(plan: samplePlan, unit: 3.9, onStart: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    TodayCardView(plan: samplePlan, unit: 3.9, onStart: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}


