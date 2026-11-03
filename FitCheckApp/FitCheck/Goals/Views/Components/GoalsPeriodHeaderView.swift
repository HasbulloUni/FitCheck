//
//  GoalsPeriodHeaderView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The title of a section: "THIS WEEK" on the left, "Resets Monday" on the right.
struct GoalsPeriodHeaderView: View {
    let period: GoalsPeriod
    let unit: CGFloat   // 1% of the screen width

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(period.title.uppercased())
                .font(.system(size: 3.2 * unit, weight: .heavy))
                .tracking(0.3 * unit)   // a little space between the letters
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Text(period.resetText)
                .font(.system(size: 3 * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, unit)
    }
}

#Preview("Light") {
    GoalsPeriodHeaderView(period: .week, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    GoalsPeriodHeaderView(period: .month, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
