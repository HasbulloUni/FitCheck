//
//  MyPlansSectionView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// BLOCK 5 - The "My plans" section: title with "+ New plan" and one row for each plan.
// Every size is a multiple of "unit" (1% of the screen width), like the other blocks.
//
// Each row is one training day. Swipe it:
//   - from right to left: the Edit and Delete buttons appear
//   - from left to right: the Go button appears (it starts the workout)

// MARK: - The section
struct MyPlansSectionView: View {
    let plans: [PlanItem]
    let unit: CGFloat
    let onNewPlan: () -> Void               // tap on "+ New plan" (or on the empty card)
    let onOpenPlan: (PlanItem) -> Void      // tap on a plan row
    let onEditPlan: (PlanItem) -> Void      // swipe right-to-left, then Edit
    let onDeletePlan: (PlanItem) -> Void    // swipe right-to-left, then Delete (after the question)
    let onStartPlan: (PlanItem) -> Void     // swipe left-to-right, then Go

    // The plan the user wants to delete: the question is shown while it is not nil
    @State private var planToDelete: PlanItem? = nil

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
                        onEdit: { onEditPlan(plan) },
                        onDelete: { planToDelete = plan },
                        onStart: { onStartPlan(plan) }
                    )
                }
            }
        }
        // Delete asks first: it cannot be undone
        .confirmationDialog(
            "Delete \(planToDelete?.name ?? "this plan")?",
            isPresented: Binding(
                get: { planToDelete != nil },
                set: { if !$0 { planToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let plan = planToDelete { onDeletePlan(plan) }
                planToDelete = nil
            }
            Button("Cancel", role: .cancel) { planToDelete = nil }
        }
    }
}

// MARK: - One plan row
// The card shows the icon, the name and the summary (exercises and minutes).
// Behind the card there are the buttons that appear with the swipe.
struct PlanRowView: View {
    let plan: PlanItem
    let unit: CGFloat
    let onOpen: () -> Void     // tap on the row
    let onEdit: () -> Void     // Edit button
    let onDelete: () -> Void   // Delete button
    let onStart: () -> Void    // Go button

    // Where the card rests: 0 = closed, negative = moved left, positive = moved right
    @State private var restingOffset: CGFloat = 0
    // How far the finger has moved during the swipe
    @State private var dragOffset: CGFloat = 0

    // Sizes of the row and of the buttons
    private var rowHeight: CGFloat { 16 * unit }
    private var smallButton: CGFloat { 14 * unit }   // Edit and Delete
    private var goButton: CGFloat { 18 * unit }      // Go
    private var gap: CGFloat { 2 * unit }            // space between card and buttons

    // How far the card moves to show the buttons
    private var editDeleteReveal: CGFloat { 2 * smallButton + 2 * gap }
    private var goReveal: CGFloat { goButton + gap }

    // The real position of the card, never farther than the buttons
    private var offset: CGFloat {
        min(max(restingOffset + dragOffset, -editDeleteReveal), goReveal)
    }

    var body: some View {
        ZStack {
            // Go button, on the left (visible only when the card moves right)
            HStack {
                actionButton(width: goButton, color: AppColors.green, action: onStart) {
                    VStack(spacing: 0.5 * unit) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 4.4 * unit, weight: .bold))
                        Text("Go")
                            .font(.system(size: 3.4 * unit, weight: .bold))
                    }
                    .foregroundStyle(.black)
                }
                Spacer()
            }
            .opacity(offset > 0 ? 1 : 0)
            .allowsHitTesting(offset > 0)

            // Edit and Delete buttons, on the right (visible only when the card moves left)
            HStack(spacing: gap) {
                Spacer()
                actionButton(width: smallButton, color: AppColors.cardAlt, action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 4.6 * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .accessibilityLabel("Edit \(plan.name)")

                actionButton(width: smallButton, color: AppColors.red, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 4.6 * unit, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Delete \(plan.name)")
            }
            .opacity(offset < 0 ? 1 : 0)
            .allowsHitTesting(offset < 0)

            // The card itself
            card
                .offset(x: offset)
                .onTapGesture {
                    // An open row closes first, a closed row opens the plan
                    if restingOffset != 0 {
                        closeRow()
                    } else {
                        onOpen()
                    }
                }
                .simultaneousGesture(swipe)
        }
        .frame(height: rowHeight)
        // The swipe is not possible with VoiceOver, so the same actions are offered here
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Go") { onStart() }
        .accessibilityAction(named: "Edit") { onEdit() }
        .accessibilityAction(named: "Delete") { onDelete() }
    }

    // MARK: The card: icon, name and summary
    private var card: some View {
        HStack(spacing: 3 * unit) {

            // Square with the icon, in the color of the plan
            Image(systemName: plan.icon)
                .font(.system(size: 5 * unit, weight: .semibold))
                .foregroundStyle(plan.color)
                .frame(width: 10 * unit, height: 10 * unit)
                .background(plan.color.opacity(0.25), in: RoundedRectangle(cornerRadius: 2.5 * unit))

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
        .padding(3 * unit)
        .frame(height: rowHeight)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 5 * unit))
        .contentShape(Rectangle())
    }

    // MARK: The swipe
    // Only a mostly horizontal movement counts, so the screen can still scroll up and down.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                let target = restingOffset + (isHorizontal ? value.translation.width : 0)

                withAnimation(.spring(duration: 0.25)) {
                    if target < -editDeleteReveal / 2 {
                        restingOffset = -editDeleteReveal   // open: Edit and Delete
                    } else if target > goReveal / 2 {
                        restingOffset = goReveal            // open: Go
                    } else {
                        restingOffset = 0                   // closed
                    }
                    dragOffset = 0
                }
            }
    }

    private func closeRow() {
        withAnimation(.spring(duration: 0.25)) {
            restingOffset = 0
            dragOffset = 0
        }
    }

    // MARK: One button behind the card. It closes the row and then does its action.
    private func actionButton<Label: View>(
        width: CGFloat,
        color: Color,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) -> some View {
        Button {
            closeRow()
            action()
        } label: {
            label()
                .frame(width: width, height: rowHeight)
                .background(color, in: RoundedRectangle(cornerRadius: 5 * unit))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews
// Sample data used only by the previews
private let samplePlans: [PlanItem] = [
    PlanItem(id: UUID(), name: "Legs", icon: "figure.run", color: AppColors.muscleOrange, exerciseCount: 9, minutes: 60),
    PlanItem(id: UUID(), name: "Chest + Back", icon: "figure.strengthtraining.traditional", color: AppColors.musclePurple, exerciseCount: 11, minutes: 90),
    PlanItem(id: UUID(), name: "Full body", icon: "figure.mixed.cardio", color: AppColors.muscleGreen, exerciseCount: 10, minutes: 60)
]

#Preview("Light") {
    MyPlansSectionView(
        plans: samplePlans, unit: 3.9,
        onNewPlan: {}, onOpenPlan: { _ in }, onEditPlan: { _ in },
        onDeletePlan: { _ in }, onStartPlan: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
}

#Preview("Dark") {
    MyPlansSectionView(
        plans: samplePlans, unit: 3.9,
        onNewPlan: {}, onOpenPlan: { _ in }, onEditPlan: { _ in },
        onDeletePlan: { _ in }, onStartPlan: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    MyPlansSectionView(
        plans: [], unit: 3.9,
        onNewPlan: {}, onOpenPlan: { _ in }, onEditPlan: { _ in },
        onDeletePlan: { _ in }, onStartPlan: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
}
