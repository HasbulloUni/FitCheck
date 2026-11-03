//
//  ExerciseDetailView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The sheet that opens with a tap on an exercise of "Add your plan":
// photo, name, sets (+ and −, max 4), reps, rest, effort, ramp-up sets, and "Remove from plan".
// It only draws: it reads and changes the plan through AddPlanViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct ExerciseDetailView: View {
    let viewModel: AddPlanViewModel
    let exerciseId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // The only GeometryReader of the sheet: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            // The exercise as it is now (the sets can change while the sheet is open)
            if let exercise = viewModel.exercise(withId: exerciseId) {
                ScrollView {
                    content(exercise, unit: unit)
                        .padding(.horizontal, 5 * unit)
                        .padding(.top, 6 * unit)
                        .padding(.bottom, 4 * unit)
                }
            }
        }
        .background(AppColors.card)
    }

    // MARK: - Pieces of the sheet

    private func content(_ exercise: ChosenExercise, unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            photo(exercise, unit: unit)

            Text(viewModel.displayName(of: exercise.item))
                .font(.system(size: 6.6 * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.top, 3.5 * unit)

            Text(viewModel.kindText(exercise.item))
                .font(.system(size: 3.6 * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)

            settingsCard(exercise, unit: unit)
                .padding(.top, 3.5 * unit)

            if viewModel.hasRampUp(exercise) {
                HStack(alignment: .top, spacing: 2 * unit) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 3.6 * unit, weight: .semibold))
                    Text("Before this one, 2 ramp-up sets are added for you: \(viewModel.rampUpText).")
                        .font(.system(size: 3.2 * unit, weight: .regular))
                }
                .foregroundStyle(AppColors.textSecondary)
                .padding(.top, 3 * unit)
            }

            buttons(exercise, unit: unit)
                .padding(.top, 5 * unit)
        }
    }

    // The photo of the exercise (downloaded the first time), with the equipment on top
    private func photo(_ exercise: ChosenExercise, unit: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 5.5 * unit)
                .fill(viewModel.color.opacity(0.3))

            ExerciseImageView(paths: viewModel.images(of: exercise))
                .frame(height: 38 * unit)
                .frame(maxWidth: .infinity)

            HStack(spacing: 1.5 * unit) {
                if viewModel.hasRampUp(exercise) {
                    photoChip("Ramp-up sets", unit: unit)
                }
                Spacer()
                photoChip(exercise.item.equipment, unit: unit)
            }
            .padding(3 * unit)
        }
        .frame(height: 42 * unit)
        .clipShape(RoundedRectangle(cornerRadius: 5.5 * unit))
    }

    private func photoChip(_ text: String, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 3 * unit, weight: .bold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 2.6 * unit)
            .frame(height: 6.5 * unit)
            .background(Color.white, in: Capsule())
    }

    // Sets with + and −, then reps, rest and effort
    private func settingsCard(_ exercise: ChosenExercise, unit: CGFloat) -> some View {
        VStack(spacing: 0) {
            settingRow("Sets", unit: unit) {
                HStack(spacing: 2.5 * unit) {
                    stepButton("minus", label: "Fewer sets", exercise: exercise, step: -1, unit: unit)

                    Text("\(exercise.sets)")
                        .font(.system(size: 4.4 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 5 * unit)

                    stepButton("plus", label: "More sets", exercise: exercise, step: 1, unit: unit)
                }
            }
            divider(unit: unit)
            settingRow("Reps", unit: unit) { valueText(viewModel.repsText(exercise), unit: unit) }
            divider(unit: unit)
            settingRow("Rest", unit: unit) { valueText(viewModel.restText(exercise), unit: unit) }
            divider(unit: unit)

            VStack(alignment: .leading, spacing: 1 * unit) {
                Text("Effort")
                    .font(.system(size: 3.8 * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                Text(viewModel.effortText(exercise))
                    .font(.system(size: 3.8 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 3 * unit)
        }
        .padding(.horizontal, 4 * unit)
        .background(AppColors.background, in: RoundedRectangle(cornerRadius: 5 * unit))
    }

    private func settingRow<Value: View>(_ title: String, unit: CGFloat,
                                         @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 3.8 * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            value()
        }
        .frame(height: 12 * unit)
    }

    private func valueText(_ text: String, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 3.8 * unit, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
    }

    private func divider(unit: CGFloat) -> some View {
        Rectangle()
            .fill(AppColors.divider)
            .frame(height: 0.25 * unit)
    }

    // The round + or − button of the sets: faded at the minimum (3) or the maximum (4)
    private func stepButton(_ icon: String, label: String, exercise: ChosenExercise,
                            step: Int, unit: CGFloat) -> some View {
        let isAllowed = viewModel.canChangeSets(of: exercise, by: step)

        return Button(action: { viewModel.changeSets(of: exercise, by: step) }) {
            Image(systemName: icon)
                .font(.system(size: 3.4 * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 8 * unit, height: 8 * unit)
                .background(AppColors.card, in: Circle())
                .overlay(Circle().stroke(AppColors.divider, lineWidth: 0.3 * unit))
        }
        .buttonStyle(.plain)
        .disabled(!isAllowed)
        .opacity(isAllowed ? 1 : 0.35)
        .accessibilityLabel(label)
    }

    // "Remove from plan" (red text) and the black "Done"
    private func buttons(_ exercise: ChosenExercise, unit: CGFloat) -> some View {
        HStack(spacing: 2.5 * unit) {
            Button(action: { withAnimation { viewModel.removeExercise(exercise) } }) {
                Text("Remove from plan")
                    .font(.system(size: 4 * unit, weight: .bold))
                    .foregroundStyle(AppColors.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 14 * unit)
                    .background(AppColors.card, in: Capsule())
                    .overlay(Capsule().stroke(AppColors.divider, lineWidth: 0.4 * unit))
            }
            .buttonStyle(.plain)

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 4 * unit, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .frame(width: 32 * unit, height: 14 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Previews
// The sample exercises exist only here, inside the previews.
private func previewViewModel(withData: Bool) -> AddPlanViewModel {
    let viewModel = AddPlanViewModel(takenColorIndexes: [])
    if withData {
        viewModel.setExercises([
            CatalogItem(id: "Goblet_Squat", name: "Goblet Squat", level: "beginner", mechanic: "compound",
                        force: "push", equipment: "Kettlebell", muscle: "quadriceps", group: "Legs",
                        variants: [:], needsBar: false),
            CatalogItem(id: "Leg_Press", name: "Leg Press", level: "beginner", mechanic: "compound",
                        force: "push", equipment: "Machine", muscle: "quadriceps", group: "Legs",
                        variants: [:], needsBar: false)
        ])
    } else {
        // An exercise with no photo saved: the sheet shows the placeholder
        viewModel.setExercises([
            CatalogItem(id: "no_photo", name: "Pull Through", level: "beginner", mechanic: "compound",
                        force: "pull", equipment: "Cable", muscle: "glutes", group: "Glutes",
                        variants: [:], needsBar: false)
        ])
    }
    return viewModel
}

#Preview("Light") {
    ExerciseDetailView(viewModel: previewViewModel(withData: true), exerciseId: "Goblet_Squat")
}

#Preview("Dark") {
    ExerciseDetailView(viewModel: previewViewModel(withData: true), exerciseId: "Goblet_Squat")
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    ExerciseDetailView(viewModel: previewViewModel(withData: false), exerciseId: "no_photo")
}
