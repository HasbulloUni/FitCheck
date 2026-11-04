//
//  MinutesCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The "Minutes" card: the total minutes trained in the chosen period.
struct MinutesCardView: View {
    let minutes: Int
    let hasSessions: Bool
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ProgressCardTitle(text: "Minutes", unit: unit)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: unit) {
                Text("\(minutes)")
                    .font(.system(size: AppSizes.Text.display * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("min")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Text(hasSessions ? "in this period" : "Nothing logged yet")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .progressCard(unit: unit, height: 24 * unit)
    }
}

#Preview("Light") {
    MinutesCardView(minutes: 630, hasSessions: true, unit: 3.9)
        .frame(width: 43 * 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    MinutesCardView(minutes: 630, hasSessions: true, unit: 3.9)
        .frame(width: 43 * 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    MinutesCardView(minutes: 0, hasSessions: false, unit: 3.9)
        .frame(width: 43 * 3.9)
        .padding(20)
        .background(AppColors.background)
}
