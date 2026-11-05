//
//  LoadGainsCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The "Top load gains" card: only the biggest increases of weight (3 at most), not every exercise.
// With no increases the same card shows an invitation.
struct LoadGainsCardView: View {
    let gains: [LoadGain]
    var topLoads: [LoadTop] = []   // shown instead of the invitation when there are no increases yet
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
            ProgressCardTitle(text: gains.isEmpty && !topLoads.isEmpty ? "Heaviest weights" : "Top load gains", unit: unit)

            if gains.isEmpty && !topLoads.isEmpty {
                // No increase yet (for example the first workout): the heaviest weights of the period
                VStack(spacing: AppSizes.Space.group * unit) {
                    ForEach(topLoads) { load in
                        HStack(spacing: AppSizes.Space.related * unit) {
                            Text(load.name)
                                .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Spacer(minLength: unit)

                            Text("\(ProgressFormat.kg(load.kg)) kg")
                                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }

                Text("Your heaviest weights so far. Increases will show up here.")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            } else if gains.isEmpty {
                VStack(alignment: .leading, spacing: unit) {
                    Text("No weight increases yet")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Add weight to an exercise and it will show up here.")
                        .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }
            } else {
                VStack(spacing: AppSizes.Space.group * unit) {
                    ForEach(gains) { gain in
                        HStack(spacing: AppSizes.Space.related * unit) {
                            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                                Text(gain.name)
                                    .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)

                                Text("\(ProgressFormat.kg(gain.fromKg)) → \(ProgressFormat.kg(gain.toKg)) kg")
                                    .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                                    .foregroundStyle(AppColors.textSecondary)
                            }

                            Spacer(minLength: unit)

                            HStack(spacing: AppSizes.Space.tight * unit) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                                Text("+\(ProgressFormat.kg(gain.gainKg)) kg")
                                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                            }
                            .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }

                Text("Only your biggest increases in this period.")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .progressCard(unit: unit)
    }
}

#Preview("Light") {
    LoadGainsCardView(gains: ProgressPreviewData.summary().loadGains, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    LoadGainsCardView(gains: ProgressPreviewData.summary().loadGains, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    LoadGainsCardView(gains: [], unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}
