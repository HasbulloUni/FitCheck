//
//  SessionsCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The "Sessions" card: a donut with the sessions done, and a legend that says which plan
// was done how many times, each with its own color. With no sessions the same card
// shows an empty ring and a short invitation.
struct SessionsCardView: View {
    let slices: [PlanSlice]
    let total: Int
    let unit: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
            ProgressCardTitle(text: "Sessions", unit: unit)

            HStack(spacing: AppSizes.Space.screen * unit) {
                SessionsDonutView(slices: slices, total: total, unit: unit)

                if slices.isEmpty {
                    emptyText
                } else {
                    legend
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .progressCard(unit: unit)
    }

    // One row for each plan: color, name, number of sessions
    private var legend: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            ForEach(slices) { slice in
                HStack(spacing: AppSizes.Space.related * unit) {
                    Circle()
                        .fill(slice.color)
                        .frame(width: 2.4 * unit, height: 2.4 * unit)

                    Text(slice.name)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer(minLength: unit)

                    Text("\(slice.count)")
                        .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyText: some View {
        VStack(alignment: .leading, spacing: unit) {
            Text("No sessions yet")
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Text("Finish a workout and it will show up here.")
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - The donut
// A grey ring with one colored arc for each plan.
struct SessionsDonutView: View {
    let slices: [PlanSlice]
    let total: Int
    let unit: CGFloat

    // One arc of the ring: where it starts and ends (from 0 to 1)
    private struct Arc: Identifiable {
        let id: Int
        let from: Double
        let to: Double
        let color: Color
    }

    private var arcs: [Arc] {
        guard total > 0 else { return [] }
        var result: [Arc] = []
        var start = 0.0
        let gap = slices.count > 1 ? 0.012 : 0.0   // a tiny space between the arcs
        for (index, slice) in slices.enumerated() {
            let fraction = Double(slice.count) / Double(total)
            result.append(Arc(id: index, from: start, to: start + fraction - gap, color: slice.color))
            start += fraction
        }
        return result
    }

    var body: some View {
        let lineWidth = 3.4 * unit

        ZStack {
            Circle()
                .inset(by: lineWidth / 2)
                .stroke(AppColors.divider, lineWidth: lineWidth)

            ForEach(arcs) { arc in
                Circle()
                    .inset(by: lineWidth / 2)
                    .trim(from: arc.from, to: arc.to)
                    .stroke(arc.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))   // the first arc starts from the top
            }

            VStack(spacing: 0) {
                Text("\(total)")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                Text("sessions")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(width: 25 * unit, height: 25 * unit)
    }
}

// MARK: - Previews
#Preview("Light") {
    let summary = ProgressPreviewData.summary()
    SessionsCardView(slices: summary.planSlices, total: summary.sessionCount, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    let summary = ProgressPreviewData.summary()
    SessionsCardView(slices: summary.planSlices, total: summary.sessionCount, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    SessionsCardView(slices: [], total: 0, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}
