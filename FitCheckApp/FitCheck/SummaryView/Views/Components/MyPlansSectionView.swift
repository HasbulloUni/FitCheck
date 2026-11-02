//
//  MyPlansSectionView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// BLOCK 5 - The "My plans" section: title with "+ New plan" and one row for each plan.
// Every size is a multiple of "unit" (1% of the screen width), like the other blocks.

// MARK: - The section
struct MyPlansSectionView: View {
    let plans: [PlanItem]
    let unit: CGFloat
    let onNewPlan: () -> Void               // tap on "+ New plan" (or on the empty card)
    let onOpenPlan: (PlanItem) -> Void      // tap on a plan row
    let onEditPlan: (PlanItem) -> Void      // tap on the pencil of a plan row

    var body: some View {
        VStack(alignment: .leading, spacing: 2 * unit) {

            // Title row: "My plans" on the left, "+ New plan" on the right
            HStack {
                Text("My plans")
                    .font(.system(size: 6 * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button(action: onNewPlan) {
                    Text("+ New plan")
                        .font(.system(size: 4 * unit, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if plans.isEmpty {
                // No plans yet: we reuse the "Add" card of the goals, with other texts
                AddGoalCardView(
                    title: "No plans yet",
                    subtitle: "Create your first plan",
                    unit: unit,
                    onTap: onNewPlan
                )
            } else {
                // One row for each plan
                ForEach(plans) { plan in
                    PlanRowView(
                        plan: plan,
                        unit: unit,
                        onOpen: { onOpenPlan(plan) },
                        onEdit: { onEditPlan(plan) }
                    )
                }
            }
        }
    }
}

// MARK: - One plan row
// A square with the letter, the name and the details, and a pencil on the right.
struct PlanRowView: View {
    let plan: PlanItem
    let unit: CGFloat
    let onOpen: () -> Void   // tap on the row
    let onEdit: () -> Void   // tap on the pencil

    var body: some View {
        HStack(spacing: 3 * unit) {

            // The row itself is a button that opens the plan
            Button(action: onOpen) {
                HStack(spacing: 3 * unit) {

                    // Square with the letter, in the color of the plan
                    Text(plan.letter)
                        .font(.system(size: 5 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 10 * unit, height: 10 * unit)
                        .background(plan.color.opacity(0.3), in: RoundedRectangle(cornerRadius: 2.5 * unit))

                    VStack(alignment: .leading, spacing: 0.5 * unit) {
                        Text(plan.name)
                            .font(.system(size: 4.4 * unit, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(plan.details)
                            .font(.system(size: 3.4 * unit, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            PencilButtonView(unit: unit, action: onEdit)
        }
        .padding(3 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 5 * unit))
    }
}

// MARK: - The grey round pencil button
struct PencilButtonView: View {
    let unit: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "pencil")
                .font(.system(size: 3.4 * unit, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
                .padding(2.5 * unit)
                .background(AppColors.cardAlt, in: Circle())
        }
    }
}

// MARK: - Previews
// Sample data used only by the previews
private let samplePlans: [PlanItem] = [
    PlanItem(letter: "A", name: "Full body A", details: "67 min · 11 exercises", color: AppColors.muscleOrange),
    PlanItem(letter: "B", name: "Full body B", details: "62 min · 10 exercises", color: AppColors.musclePurple),
    PlanItem(letter: "C", name: "Full body C", details: "65 min · 9 exercises", color: AppColors.green)
]

#Preview("Light") {
    MyPlansSectionView(
        plans: samplePlans, unit: 3.9,
        onNewPlan: {}, onOpenPlan: { _ in }, onEditPlan: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
}

#Preview("Dark") {
    MyPlansSectionView(
        plans: samplePlans, unit: 3.9,
        onNewPlan: {}, onOpenPlan: { _ in }, onEditPlan: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    MyPlansSectionView(
        plans: [], unit: 3.9,
        onNewPlan: {}, onOpenPlan: { _ in }, onEditPlan: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
}
