//
//  YourPlanStepView.swift
//  FitCheck
//
//  Screen 5: one tab for each training day, with the plan of that day:
//  warm-up, main part (numbered exercises) and cool-down. "Edit" opens the plan editor.
//  Nothing is saved until the big button "Set plan".
//

import SwiftUI
import SwiftData

struct YourPlanStepView: View {
    let weekdays: [Int]          // Monday first
    let plans: [PlanItem]        // same order as the days
    let level: ReadyMadeLevel
    let unit: CGFloat
    let onEdit: (PlanItem) -> Void

    @Query private var exercises: [Exercise]
    @State private var selected = 0
    @State private var editingPlan: PlanItem? = nil

    private let dayNames = [1: "Sun", 2: "Mon", 3: "Tue", 4: "Wed", 5: "Thu", 6: "Fri", 7: "Sat"]

    // Same goal and level that the plan editor uses for sets, reps and rest
    private let goal: PlanGoal = .tone
    private let planLevel: PlanLevel = .medium

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            OnboardingTitleView(title: "Your plan",
                                subtitle: subtitle,
                                unit: unit)

            if plans.isEmpty {
                Text("No plans yet. Go back and pick a plan.")
                    .font(.system(size: AppSizes.Text.body * unit))
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                dayTabs
                planHeader(for: currentPlan)
                planLists(for: currentPlan)
            }

            Text("You can change days, plans and reminders any time from Home.")
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
        // "Edit": the same plan editor of the app, on this day
        .fullScreenCover(item: $editingPlan) { plan in
            AddPlanView(
                editing: plan,
                takenColorIndexes: plans.filter { $0.id != plan.id }.compactMap { $0.colorIndex },
                otherPlanNames: plans.filter { $0.id != plan.id }.map { $0.name },
                onBack: { editingPlan = nil },
                onSave: { saved in
                    onEdit(saved)
                    editingPlan = nil
                }
            )
        }
    }

    private var subtitle: String {
        let days = weekdays.count
        return "\(level.title) · \(days) \(days == 1 ? "day" : "days") a week"
    }

    // The plan of the open tab (the plans repeat if the days are more)
    private var currentPlan: PlanItem {
        plans[min(selected, weekdays.count - 1) % plans.count]
    }

    // MARK: - Day tabs

    private var dayTabs: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { position, weekday in
                Button { selected = position } label: {
                    Text(dayNames[weekday] ?? "")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 10 * unit)
                        .background(selected == position ? AppColors.card : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected == position ? .isSelected : [])
            }
        }
        .padding(unit)
        .background(AppColors.cardAlt, in: Capsule())
    }

    // MARK: - Name, color and Edit

    private func planHeader(for plan: PlanItem) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit)
                .fill(plan.color)
                .frame(width: 3 * unit, height: 12 * unit)

            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text(plan.name)
                    .font(.system(size: AppSizes.Text.title * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(plan.details)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Button { editingPlan = plan } label: {
                Text("Edit")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                    .foregroundStyle(AppColors.muscleGreen)
                    .padding(.horizontal, AppSizes.Space.group * unit)
                    .frame(height: 8 * unit)
                    .background(AppColors.card, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(plan.name)")
        }
    }

    // MARK: - Warm-up, main part, cool-down

    private func planLists(for plan: PlanItem) -> some View {
        let rows = exerciseRows(for: plan)

        return VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
            sectionTitle("WARM-UP")
            simpleCard(title: "Walking treadmill", detail: "\(Int(SafetyRules.warmupMinutes)) min")

            sectionTitle("MAIN PART")
            VStack(spacing: AppSizes.Space.related * unit) {
                ForEach(Array(rows.enumerated()), id: \.offset) { position, row in
                    exerciseRow(row, number: position + 1, color: plan.color)
                }
            }

            if plan.hasCooldown {
                sectionTitle("COOL-DOWN")
                simpleCard(title: "Slow walk and stretches", detail: "\(Int(SafetyRules.cooldownMinutes)) min")
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
            .tracking(0.2 * unit)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.leading, AppSizes.Space.group * unit)
    }

    private func simpleCard(title: String, detail: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: AppSizes.Text.bodyLarge * unit))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Text(detail)
                .font(.system(size: AppSizes.Text.body * unit))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSizes.Space.group * unit)
        .frame(height: 13 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // Number in a tile (the color of the plan, lighter), name and "3 × 12-15 · rest 60 s · Chest"
    private func exerciseRow(_ row: (name: String, detail: String), number: Int, color: Color) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Text("\(number)")
                .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 11 * unit, height: 11 * unit)
                .background(color.opacity(0.3), in: RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))

            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text(row.name)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(row.detail)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSizes.Space.group * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // The exercises of the plan with the same texts as the plan editor
    private func exerciseRows(for plan: PlanItem) -> [(name: String, detail: String)] {
        let catalog = CatalogBuilder.build(from: exercises)
        let byId = Dictionary(catalog.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return plan.exerciseIds.enumerated().compactMap { position, id in
            guard let item = byId[id] else { return nil }
            let sets = position < plan.exerciseSets.count ? plan.exerciseSets[position] : Prescription.sets(for: planLevel)
            let planned = Prescription.make(item: item, goal: goal, level: planLevel, sets: sets, slotKey: item.group)
            let amount = planned.holdSeconds.map { "\($0) s" } ?? "\(planned.repsMin ?? 0)-\(planned.repsMax ?? 0)"
            let name = item.variants[planLevel.rawValue] ?? item.name
            return (name, "\(planned.sets) × \(amount) · rest \(planned.restSeconds) s · \(item.muscle.capitalized)")
        }
    }
}

private let samplePlans = [
    PlanItem(id: UUID(), name: "Full body A", icon: "figure.strengthtraining.traditional",
             color: PlanPalette.colors[0], exerciseCount: 9, minutes: 52),
    PlanItem(id: UUID(), name: "Full body B", icon: "figure.strengthtraining.traditional",
             color: PlanPalette.colors[1], exerciseCount: 9, minutes: 50),
    PlanItem(id: UUID(), name: "Full body C", icon: "figure.strengthtraining.traditional",
             color: PlanPalette.colors[2], exerciseCount: 8, minutes: 48)
]

#Preview("Light") {
    ScrollView {
        YourPlanStepView(weekdays: [2, 4, 6], plans: samplePlans, level: .intermediate, unit: 3.9, onEdit: { _ in })
            .padding(23.4)
    }
    .background(AppColors.background)
    .modelContainer(planPreviewContainer(withData: true))
}

#Preview("Dark") {
    ScrollView {
        YourPlanStepView(weekdays: [2, 4, 6], plans: samplePlans, level: .intermediate, unit: 3.9, onEdit: { _ in })
            .padding(23.4)
    }
    .background(AppColors.background)
    .modelContainer(planPreviewContainer(withData: true))
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    YourPlanStepView(weekdays: [], plans: [], level: .beginner, unit: 3.9, onEdit: { _ in })
        .padding(23.4)
        .background(AppColors.background)
        .modelContainer(planPreviewContainer(withData: false))
}
