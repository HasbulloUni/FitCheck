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
    let onNewPlan: () -> Void               // "Custom" in the "+ New plan" menu (or tap on the empty card)
    var onReadyMade: () -> Void = {}        // "Ready-made" in the "+ New plan" menu
    var onDeleteAllPlans: () -> Void = {}   // "Delete all plans" in the "+ New plan" menu (after the question)
    let onOpenPlan: (PlanItem) -> Void      // tap on a plan row
    let onEditPlan: (PlanItem) -> Void      // swipe right-to-left, then Edit
    let onDeletePlan: (PlanItem) -> Void    // swipe right-to-left, then Delete (after the question)
    let onStartPlan: (PlanItem) -> Void     // swipe left-to-right, then Go

    // The plan the user wants to delete: the question is shown while it is not nil
    @State private var planToDelete: PlanItem? = nil
    // True while the question "Delete all plans?" is shown
    @State private var isDeleteAllAsked = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {

            // Title row: "My plans" on the left, "+ New plan" on the right
            HStack {
                Text("My plans")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                // The standard iOS menu: the user picks how to make the plan
                Menu {
                    Button(action: onReadyMade) {
                        Label("Ready-made", systemImage: "wand.and.stars")
                    }
                    Button(action: onNewPlan) {
                        Label("Custom", systemImage: "slider.horizontal.3")
                    }

                    // Only when there is something to delete
                    if !plans.isEmpty {
                        Divider()
                        Button(role: .destructive) { isDeleteAllAsked = true } label: {
                            Label("Delete all plans", systemImage: "trash")
                        }
                    }
                } label: {
                    Text("+ New plan")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .medium))
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
        // Delete all asks first too
        .confirmationDialog(
            "Delete all \(plans.count) plans?",
            isPresented: $isDeleteAllAsked,
            titleVisibility: .visible
        ) {
            Button("Delete all", role: .destructive) { onDeleteAllPlans() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They are also removed from the rotation. Your progress is kept.")
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
    // Decided at the start of a drag: is it a horizontal swipe? (nil = not decided yet)
    @State private var isHorizontalSwipe: Bool? = nil

    // Sizes of the row and of the buttons
    private var rowHeight: CGFloat { 16 * unit }
    private var smallButton: CGFloat { 14 * unit }   // Edit and Delete
    private var goButton: CGFloat { 18 * unit }      // Go
    private var gap: CGFloat { 2 * unit }            // space between card and buttons

    // How far the card moves to show the buttons
    private var editDeleteReveal: CGFloat { 2 * smallButton + 2 * gap }
    private var goReveal: CGFloat { goButton + gap }

    // The position of the card follows the finger. Beyond the buttons it gets harder
    // to pull (rubber band), like the native iOS lists.
    private var offset: CGFloat {
        rubberBand(restingOffset + dragOffset)
    }

    // 0...1: how much of the buttons on the right / left is visible
    private var rightProgress: CGFloat { min(max(-offset / editDeleteReveal, 0), 1) }
    private var leftProgress: CGFloat { min(max(offset / goReveal, 0), 1) }

    // The spring used by every movement of the card
    private var rowSpring: Animation { .spring(response: 0.38, dampingFraction: 0.78) }

    var body: some View {
        ZStack {
            // Go button, on the left (it grows while the card moves right)
            HStack {
                actionButton(width: goButton, color: AppColors.green, action: onStart) {
                    VStack(spacing: AppSizes.Space.tight * unit) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                        Text("Go")
                            .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    }
                    .foregroundStyle(.black)
                }
                .scaleEffect(0.6 + 0.4 * leftProgress, anchor: .leading)
                .opacity(leftProgress)
                Spacer()
            }
            .allowsHitTesting(leftProgress > 0.5)

            // Edit and Delete buttons, on the right (they grow while the card moves left)
            HStack(spacing: gap) {
                Spacer()
                actionButton(width: smallButton, color: AppColors.cardAlt, action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .accessibilityLabel("Edit \(plan.name)")

                actionButton(width: smallButton, color: AppColors.red, action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Delete \(plan.name)")
            }
            .scaleEffect(0.6 + 0.4 * rightProgress, anchor: .trailing)
            .opacity(rightProgress)
            .allowsHitTesting(rightProgress > 0.5)

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
        // A soft tap when the row opens or closes
        .sensoryFeedback(.impact(flexibility: .soft), trigger: restingOffset)
        // The swipe is not possible with VoiceOver, so the same actions are offered here
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Go") { onStart() }
        .accessibilityAction(named: "Edit") { onEdit() }
        .accessibilityAction(named: "Delete") { onDelete() }
    }

    // Resistance beyond the end of the buttons: the card follows the finger only a little
    private func rubberBand(_ value: CGFloat) -> CGFloat {
        let limit = value < 0 ? editDeleteReveal : goReveal
        let distance = abs(value)
        guard distance > limit else { return value }
        let extra = distance - limit
        let damped = limit + extra * 0.25 / (1 + extra / (limit * 2))
        return value < 0 ? -damped : damped
    }

    // MARK: The card: icon, name and summary
    private var card: some View {
        HStack(spacing: AppSizes.Space.group * unit) {

            // Square with the icon, in the color of the plan
            Image(systemName: plan.icon)
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                .foregroundStyle(plan.color)
                .frame(width: 10 * unit, height: 10 * unit)
                .background(plan.color.opacity(0.25), in: RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))

            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text(plan.name)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(plan.details)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()
        }
        .padding(AppSizes.Space.group * unit)
        .frame(height: rowHeight)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .contentShape(Rectangle())
    }

    // MARK: The swipe
    // The direction is decided at the start: a mostly horizontal movement moves the card,
    // a vertical one is left to the scroll view. Once decided, it does not change.
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if isHorizontalSwipe == nil {
                    isHorizontalSwipe = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isHorizontalSwipe == true else { return }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                defer { isHorizontalSwipe = nil }
                guard isHorizontalSwipe == true else { return }

                // Where the card would stop if it kept its speed: a quick flick is enough
                let projected = restingOffset + value.predictedEndTranslation.width * 0.4
                let target = restingOffset + value.translation.width

                withAnimation(rowSpring) {
                    let decision = abs(projected - restingOffset) > abs(target - restingOffset) ? projected : target
                    if decision < -editDeleteReveal / 2 {
                        restingOffset = -editDeleteReveal   // open: Edit and Delete
                    } else if decision > goReveal / 2 {
                        restingOffset = goReveal            // open: Go
                    } else {
                        restingOffset = 0                   // closed
                    }
                    dragOffset = 0
                }
            }
    }

    private func closeRow() {
        withAnimation(rowSpring) {
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
                .background(color, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
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
