//
//  ExercisePreviewView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The sheet that opens with a tap on a row of "Add exercises": the photos (start and end of
// the movement), the muscles, the sets this exercise would get in the plan, the steps, and the
// button to add or remove it.
// It only draws: it reads and changes the plan through ExercisePickerViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct ExercisePreviewView: View {
    let item: CatalogItem
    let viewModel: ExercisePickerViewModel
    let accent: Color
    @State private var showsAllSteps = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // The only GeometryReader of the sheet: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width
            let details = viewModel.details(for: item)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    photos(details?.images ?? [], unit: unit)

                    Text(viewModel.name(of: item))
                        .font(.system(size: 6.6 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(.top, 3.5 * unit)

                    tagsRow(details, unit: unit)

                    if let line = viewModel.planLineText(item) {
                        planRow(line, unit: unit)
                    }

                    if let steps = details?.instructions, !steps.isEmpty {
                        stepsSection(steps, unit: unit)
                    }

                    addButton(unit: unit)
                        .padding(.top, 5 * unit)

                    if !viewModel.isSelected(item), let blocked = viewModel.blockedText(item) {
                        Text(blocked)
                            .font(.system(size: 3.1 * unit, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.top, 1.5 * unit)
                    }
                }
                .padding(.horizontal, 5 * unit)
                .padding(.top, 2 * unit)
                .padding(.bottom, 4 * unit)
            }
        }
        .background(AppColors.card)
    }

    // MARK: - Pieces of the sheet

    // The 2 photos of the movement (start and end), or a placeholder when the database has none
    private func photos(_ images: [String], unit: CGFloat) -> some View {
        HStack(spacing: 2 * unit) {
            if images.isEmpty {
                RoundedRectangle(cornerRadius: 5.5 * unit)
                    .fill(AppColors.cardAlt)
                    .frame(height: 38 * unit)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 8 * unit))
                            .foregroundStyle(AppColors.textSecondary)
                    )
            } else {
                ForEach(Array(images.prefix(2).enumerated()), id: \.offset) { index, path in
                    ZStack(alignment: .bottomLeading) {
                        ExerciseImageView(paths: [path])

                        Text(index == 0 ? "START" : "END")
                            .font(.system(size: 2.8 * unit, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 2.2 * unit)
                            .frame(height: 5.5 * unit)
                            .background(.black, in: Capsule())
                            .padding(2 * unit)
                    }
                    .frame(height: 38 * unit)
                    .clipShape(RoundedRectangle(cornerRadius: 4.5 * unit))
                }
            }
        }
    }

    // The main muscle (filled), the secondary muscles, the equipment and the level
    private func tagsRow(_ details: ExercisePickerDetails?, unit: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 1.5 * unit) {
                tag(item.muscle.capitalized, filled: true, unit: unit)
                ForEach(details?.secondaryMuscles ?? [], id: \.self) { muscle in
                    tag(muscle.capitalized, filled: false, unit: unit)
                }
                tag(item.equipment, filled: false, unit: unit)
                tag(item.level.capitalized, filled: false, unit: unit)
            }
        }
        .padding(.top, 2.5 * unit)
    }

    private func tag(_ text: String, filled: Bool, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 3 * unit, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(1)
            .padding(.horizontal, 2.6 * unit)
            .frame(height: 6.5 * unit)
            .background(filled ? accent.opacity(0.35) : AppColors.cardAlt, in: Capsule())
    }

    // "In your plan" with the sets this exercise would get, only when it is already chosen
    private func planRow(_ line: String, unit: CGFloat) -> some View {
        HStack {
            Text("In your plan")
                .font(.system(size: 3.4 * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(line)
                .font(.system(size: 3.6 * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 3.5 * unit)
        .frame(height: 11 * unit)
        .background(AppColors.background, in: RoundedRectangle(cornerRadius: 4.5 * unit))
        .padding(.top, 3 * unit)
    }

    // The steps: only the first 3 at first, with a button to show the rest
    private func stepsSection(_ steps: [String], unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2.5 * unit) {
            Text("HOW TO DO IT")
                .font(.system(size: 2.8 * unit, weight: .bold))
                .tracking(0.3 * unit)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, 4 * unit)

            ForEach(Array((showsAllSteps ? steps : Array(steps.prefix(3))).enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 3 * unit) {
                    Text("\(index + 1)")
                        .font(.system(size: 3.2 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 6 * unit, height: 6 * unit)
                        .background(accent.opacity(0.3), in: RoundedRectangle(cornerRadius: 2 * unit))

                    Text(step)
                        .font(.system(size: 3.5 * unit, weight: .regular))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

            if steps.count > 3 {
                Button(action: { withAnimation { showsAllSteps.toggle() } }) {
                    Text(showsAllSteps ? "Show less" : "Show all \(steps.count) steps")
                        .font(.system(size: 3.4 * unit, weight: .bold))
                        .foregroundStyle(AppColors.muscleGreen)
                }
                .buttonStyle(.plain)
                .padding(.leading, 9 * unit)
            }
        }
    }

    // "Add to <plan>" (the plan color) or "Remove from <plan>" (grey) when it is already chosen
    private func addButton(unit: CGFloat) -> some View {
        let isSelected = viewModel.isSelected(item)
        let isAllowed = viewModel.canToggle(item)

        return Button(action: {
            viewModel.toggle(item)
            if isSelected { dismiss() }
        }) {
            HStack(spacing: 2 * unit) {
                Image(systemName: isSelected ? "xmark" : "plus")
                    .font(.system(size: 4 * unit, weight: .bold))
                Text(isSelected ? "Remove from \(viewModel.planName)" : "Add to \(viewModel.planName)")
                    .font(.system(size: 4.2 * unit, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? AppColors.textPrimary : Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: 14.5 * unit)
            .background(isSelected ? AppColors.cardAlt : accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isAllowed)
        .opacity(isAllowed ? 1 : 0.4)
    }
}

// MARK: - Previews
// The sample exercise and its details exist only here, inside the previews.
private func previewSetup() -> (CatalogItem, ExercisePickerViewModel) {
    let item = CatalogItem(id: "Goblet_Squat", name: "Goblet Squat", level: "beginner", mechanic: "compound",
                            force: "push", equipment: "Kettlebell", muscle: "quadriceps", group: "Legs",
                            variants: [:], needsBar: false)
    let details = ["Goblet_Squat": ExercisePickerDetails(
        images: ["Goblet_Squat/0.jpg", "Goblet_Squat/1.jpg"],
        secondaryMuscles: ["glutes", "hamstrings", "calves"],
        instructions: [
            "Stand holding a light kettlebell by the horns close to your chest.",
            "Squat down between your legs until your hamstrings are on your calves.",
            "At the bottom, pause and use your elbows to push your knees out.",
            "Return to the starting position and repeat."
        ]
    )]
    let viewModel = ExercisePickerViewModel(pool: [item], selectedIds: ["Goblet_Squat"], goal: .tone,
                                            level: .medium, planName: "Leg day", details: details)
    return (item, viewModel)
}

#Preview("Light") {
    let (item, viewModel) = previewSetup()
    ExercisePreviewView(item: item, viewModel: viewModel, accent: AppColors.muscleOrange)
}

#Preview("Dark") {
    let (item, viewModel) = previewSetup()
    ExercisePreviewView(item: item, viewModel: viewModel, accent: AppColors.muscleOrange)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    let item = CatalogItem(id: "Pull_Through", name: "Pull Through", level: "beginner", mechanic: "compound",
                            force: "pull", equipment: "Cable", muscle: "glutes", group: "Glutes",
                            variants: [:], needsBar: false)
    let viewModel = ExercisePickerViewModel(pool: [item], selectedIds: [], goal: .tone, level: .medium,
                                            planName: "New plan")
    ExercisePreviewView(item: item, viewModel: viewModel, accent: AppColors.muscleBlue)
}
