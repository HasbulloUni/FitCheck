//
//  RotationCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The card "This week's rotation" of Edit week: one row for each training day.
// Each row has a numbered circle in the color of the plan, the name of the plan, the day
// and the "Change" button (a menu with all the plans of My plans).
// A day that has just been added has an empty row: "Choose a plan".
// Only drawing: the data and the logic live in EditWeekViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other components.
struct RotationCardView: View {
    let rows: [RotationRowItem]
    let plans: [PlanItem]                       // all the plans the menu can offer
    let unit: CGFloat
    let onChange: (Int, UUID) -> Void           // the day (1 = Sunday ... 7) and the chosen plan

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Title row: "This week's rotation" and how many plans
            HStack {
                Text(EditWeekRules.rotationCardTitle)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if !rows.isEmpty {
                    Text(rows.count == 1 ? "1 plan" : "\(rows.count) plans")
                        .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .padding(.bottom, 3 * unit)

            if rows.isEmpty {
                // No training day picked yet
                Text(EditWeekRules.rotationNoDaysHint)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            } else if plans.isEmpty {
                // Days picked but no plan created yet
                Text(EditWeekRules.rotationNoPlansHint)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ForEach(Array(rows.enumerated()), id: \.element.id) { position, row in
                    rowView(row)

                    // The thin line that joins one circle to the next
                    if position < rows.count - 1 {
                        Rectangle()
                            .fill(AppColors.divider)
                            .frame(width: 0.8 * unit, height: 3 * unit)
                            .padding(.leading, 6.1 * unit)
                    }
                }
            }
        }
        .padding(4 * unit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
    }

    // One row: circle, plan and day, "Change"
    private func rowView(_ row: RotationRowItem) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Text("\(row.number)")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                .foregroundStyle(row.plan == nil ? AppColors.textSecondary : .white)
                .frame(width: 12.5 * unit, height: 12.5 * unit)
                .background(row.plan?.color ?? AppColors.cardAlt, in: Circle())

            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text(row.plan?.name ?? EditWeekRules.rotationEmptyPlan)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(row.plan == nil ? AppColors.textSecondary : AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(row.dayName)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            changeMenu(for: row)
        }
    }

    // The "Change" button: a menu with all the plans. The chosen one has the check mark.
    private func changeMenu(for row: RotationRowItem) -> some View {
        Menu {
            Picker(EditWeekRules.rotationChange, selection: Binding<UUID?>(
                get: { row.plan?.id },
                set: { newId in
                    if let newId { onChange(row.weekday, newId) }
                }
            )) {
                ForEach(plans) { plan in
                    Label {
                        Text(plan.name)
                    } icon: {
                        Image(uiImage: Self.dot(of: plan.color))
                            .renderingMode(.original)
                    }
                    .tag(Optional(plan.id))
                }
            }
        } label: {
            Text(row.plan == nil ? EditWeekRules.rotationChoose : EditWeekRules.rotationChange)
                .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 5 * unit)
                .padding(.vertical, 2.8 * unit)
                .background(AppColors.cardAlt, in: Capsule())
        }
        .accessibilityLabel("\(EditWeekRules.rotationChange) plan for \(row.dayName)")
    }

    // A small colored circle for the menu (a menu only shows pictures, not colored shapes)
    private static func dot(of color: Color) -> UIImage {
        let size = CGSize(width: 14, height: 14)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor(color).setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        }
    }
}

// MARK: - Previews
private let samplePlans: [PlanItem] = [
    PlanItem(id: UUID(), name: "Full body A", icon: "figure.mixed.cardio", color: AppColors.muscleRed, exerciseCount: 9, minutes: 60),
    PlanItem(id: UUID(), name: "Full body B", icon: "figure.mixed.cardio", color: AppColors.greenSoft, exerciseCount: 10, minutes: 60),
    PlanItem(id: UUID(), name: "Upper body", icon: "figure.strengthtraining.traditional", color: AppColors.musclePurple, exerciseCount: 8, minutes: 60)
]

private let sampleRows: [RotationRowItem] = [
    RotationRowItem(number: 1, weekday: 2, dayName: "Mon", plan: samplePlans[0]),
    RotationRowItem(number: 2, weekday: 4, dayName: "Wed", plan: samplePlans[1]),
    RotationRowItem(number: 3, weekday: 6, dayName: "Fri", plan: nil)   // a day just added
]

#Preview("Light") {
    RotationCardView(rows: sampleRows, plans: samplePlans, unit: 3.9, onChange: { _, _ in })
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    RotationCardView(rows: sampleRows, plans: samplePlans, unit: 3.9, onChange: { _, _ in })
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    RotationCardView(rows: [], plans: [], unit: 3.9, onChange: { _, _ in })
        .padding(20)
        .background(AppColors.background)
}
