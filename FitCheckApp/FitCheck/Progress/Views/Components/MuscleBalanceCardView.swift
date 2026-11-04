//
//  MuscleBalanceCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The "Muscle balance" card: a radar with the 6 muscle groups. The further a point is
// from the center, the more sets that group got. Under it: the most and the least trained.
// With no sets the radar is empty and a short text invites the user to train.
struct MuscleBalanceCardView: View {
    let muscles: [MuscleSets]       // always the 6 groups
    let most: MuscleSets?
    let least: MuscleSets?
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            HStack {
                ProgressCardTitle(text: "Muscle balance", unit: unit)
                Spacer()
                Text("sets")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }

            radar
                .frame(maxWidth: .infinity)
                .frame(height: 50 * unit)

            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .progressCard(unit: unit)
    }

    // MARK: - The radar (drawn with a Canvas)

    private var radar: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 6 * unit   // room for the names
            let count = max(muscles.count, 1)
            let biggest = max(muscles.map { $0.sets }.max() ?? 1, 1)

            // The point of an axis at a distance from the center (distance from 0 to 1)
            func point(_ index: Int, _ distance: Double) -> CGPoint {
                let angle = -Double.pi / 2 + Double(index) * 2 * Double.pi / Double(count)
                return CGPoint(
                    x: center.x + CGFloat(cos(angle) * distance) * radius,
                    y: center.y + CGFloat(sin(angle) * distance) * radius
                )
            }

            // The 3 grey rings
            for ring in [0.33, 0.66, 1.0] {
                var path = Path()
                for index in 0..<count {
                    let p = point(index, ring)
                    if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
                context.stroke(path, with: .color(AppColors.divider), lineWidth: 0.3 * unit)
            }

            // The axes
            for index in 0..<count {
                var axis = Path()
                axis.move(to: center)
                axis.addLine(to: point(index, 1))
                context.stroke(axis, with: .color(AppColors.divider), lineWidth: 0.3 * unit)
            }

            // The shape of the sets (only when there is something to draw)
            if muscles.contains(where: { $0.sets > 0 }) {
                var shape = Path()
                for (index, muscle) in muscles.enumerated() {
                    let p = point(index, Double(muscle.sets) / Double(biggest))
                    if index == 0 { shape.move(to: p) } else { shape.addLine(to: p) }
                }
                shape.closeSubpath()
                context.fill(shape, with: .color(AppColors.textPrimary.opacity(0.14)))
                context.stroke(
                    shape,
                    with: .color(AppColors.textPrimary),
                    style: StrokeStyle(lineWidth: 0.6 * unit, lineJoin: .round)
                )
            }

            // The names of the groups, just outside the last ring
            for (index, muscle) in muscles.enumerated() {
                let label = Text(muscle.group.title)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                context.draw(label, at: point(index, 1 + Double(4.2 * unit) / Double(radius)))
            }
        }
    }

    // MARK: - Most and least trained

    private var footer: some View {
        Group {
            if let most, let least {
                HStack {
                    footerText(prefix: "Most", muscle: most)
                    Spacer()
                    footerText(prefix: "Least", muscle: least)
                }
            } else {
                Text("Train to see which muscles you work the most.")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func footerText(prefix: String, muscle: MuscleSets) -> some View {
        HStack(spacing: unit) {
            Text(prefix)
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Text("\(muscle.group.title) \(muscle.sets)")
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

// MARK: - Previews
#Preview("Light") {
    let summary = ProgressPreviewData.summary()
    MuscleBalanceCardView(muscles: summary.muscleSets, most: summary.mostMuscle, least: summary.leastMuscle, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    let summary = ProgressPreviewData.summary()
    MuscleBalanceCardView(muscles: summary.muscleSets, most: summary.mostMuscle, least: summary.leastMuscle, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    let summary = ProgressPreviewData.emptySummary()
    MuscleBalanceCardView(muscles: summary.muscleSets, most: summary.mostMuscle, least: summary.leastMuscle, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}
