//
//  AddPlanView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI
import SwiftData

// The screen "Add your plan": name, category, color and length of one training day,
// and the exercises of that day (the button opens "Pick your exercises").
// It only draws: the data and the logic live in AddPlanViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct AddPlanView: View {
    @Query private var exercises: [Exercise]
    @State private var viewModel: AddPlanViewModel

    let takenColorIndexes: [Int]          // the colors already used by other plans
    let onBack: () -> Void                // the round back button: closes without saving
    let onSave: (PlanItem) -> Void        // "Save plan": gives the new plan to the Home

    init(takenColorIndexes: [Int], onBack: @escaping () -> Void, onSave: @escaping (PlanItem) -> Void) {
        _viewModel = State(initialValue: AddPlanViewModel(takenColorIndexes: takenColorIndexes))
        self.takenColorIndexes = takenColorIndexes
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4 * unit) {
                        topBar(unit: unit)

                        Text("Add your plan")
                            .font(.system(size: 9 * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        nameSection(unit: unit)
                        categorySection(unit: unit)
                        colorSection(unit: unit)
                        durationSection(unit: unit)
                        exercisesSection(unit: unit)
                    }
                    .padding(.horizontal, 6 * unit)
                    .padding(.top, 4 * unit)
                    .padding(.bottom, 4 * unit)
                }

                saveButton(unit: unit)
            }
        }
        .background(AppColors.background)
        .onAppear { viewModel.loadCatalog(from: exercises) }
        .onChange(of: exercises.count) { viewModel.loadCatalog(from: exercises) }
        // "Pick your exercises" opens over this screen
        .sheet(isPresented: $viewModel.isPickerShown) {
            ExercisePickerView(
                viewModel: ExercisePickerViewModel(
                    pool: viewModel.pool,
                    selectedIds: viewModel.chosen.map { $0.id },
                    goal: viewModel.goal,
                    level: viewModel.level
                ),
                label: "New plan",
                onDone: { viewModel.setExercises($0) }
            )
        }
    }

    // MARK: - Pieces of the screen

    // The round back button and the small green label
    private func topBar(unit: CGFloat) -> some View {
        HStack(spacing: 4 * unit) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 4 * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 12 * unit, height: 12 * unit)
                    .background(AppColors.card, in: Circle())
                    .overlay(Circle().stroke(AppColors.divider, lineWidth: 0.3 * unit))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text("NEW PLAN")
                .font(.system(size: 3.6 * unit, weight: .bold))
                .tracking(0.4 * unit)
                .foregroundStyle(AppColors.muscleGreen)

            Spacer()
        }
    }

    // The name: a white bar with the suggested name and a pencil
    private func nameSection(unit: CGFloat) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 3 * unit) {
            sectionTitle("Name of the day", unit: unit)

            HStack(spacing: 2.5 * unit) {
                TextField(
                    "",
                    text: $viewModel.name,
                    prompt: Text(viewModel.suggestedName).foregroundStyle(AppColors.textSecondary)
                )
                .font(.system(size: 4.4 * unit, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

                Image(systemName: "pencil")
                    .font(.system(size: 3.8 * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, 4.5 * unit)
            .padding(.vertical, 4 * unit)
            .background(AppColors.card, in: Capsule())
        }
    }

    // "Gym" and "Calisthenics": the chosen one is black
    private func categorySection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * unit) {
            sectionTitle("Category", unit: unit)

            HStack(spacing: 2.5 * unit) {
                ForEach(PlanCategory.allCases) { category in
                    let isSelected = viewModel.category == category

                    Button(action: { viewModel.selectCategory(category) }) {
                        Text(category.title)
                            .font(.system(size: 4 * unit, weight: .bold))
                            .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4.5 * unit)
                            .background(isSelected ? AppColors.textPrimary : AppColors.card, in: Capsule())
                            .overlay(Capsule().stroke(AppColors.divider, lineWidth: 0.3 * unit))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    // The colors: the ones used by other plans are faded and cannot be tapped
    private func colorSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * unit) {
            sectionTitle("Color", unit: unit)

            HStack(spacing: 3 * unit) {
                ForEach(PlanPalette.colors.indices, id: \.self) { index in
                    let isSelected = viewModel.colorIndex == index
                    let isTaken = takenColorIndexes.contains(index)

                    Button(action: { viewModel.colorIndex = index }) {
                        Circle()
                            .fill(PlanPalette.colors[index])
                            .frame(width: 9 * unit, height: 9 * unit)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.textPrimary, lineWidth: isSelected ? 0.7 * unit : 0)
                                    .padding(-1.2 * unit)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isTaken)
                    .opacity(isTaken ? 0.25 : 1)
                    .accessibilityLabel(isTaken ? "Color already used" : "Color \(index + 1)")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.leading, 1.5 * unit)
        }
    }

    // "60 min" and "90 min" (the same buttons of "Edit your week")
    private func durationSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * unit) {
            sectionTitle(EditWeekRules.durationQuestion, unit: unit)

            DurationPicker(
                durations: SafetyRules.sessionMinutesOptions,
                selected: viewModel.minutes,
                unit: unit,
                onSelect: { viewModel.minutes = $0 }
            )
        }
    }

    // The exercises of the day, with a remove button, and the button that opens the picker
    private func exercisesSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 3 * unit) {
            HStack {
                sectionTitle("Exercises", unit: unit)
                Spacer()
                if !viewModel.chosen.isEmpty {
                    Text("about \(viewModel.estimatedMinutes) min")
                        .font(.system(size: 3.6 * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            ForEach(viewModel.chosen, id: \.id) { item in
                exerciseRow(item, unit: unit)
            }

            addExercisesButton(unit: unit)
        }
    }

    // One chosen exercise: name, muscle and type, and a small remove button
    private func exerciseRow(_ item: CatalogItem, unit: CGFloat) -> some View {
        HStack(spacing: 3 * unit) {
            VStack(alignment: .leading, spacing: 0.8 * unit) {
                Text(item.name)
                    .font(.system(size: 4.2 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(viewModel.detailText(item))
                    .font(.system(size: 3.4 * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            Button(action: { viewModel.removeExercise(item) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 3 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 8 * unit, height: 8 * unit)
                    .background(AppColors.cardAlt, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(item.name)")
        }
        .padding(.horizontal, 4 * unit)
        .padding(.vertical, 3 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 4.5 * unit))
    }

    // The big "+ Add exercises" card: it opens "Pick your exercises".
    // It is off when the exercise list of the database is empty.
    private func addExercisesButton(unit: CGFloat) -> some View {
        Button(action: { viewModel.isPickerShown = true }) {
            HStack(spacing: 3 * unit) {
                Image(systemName: "plus")
                    .font(.system(size: 4.4 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 10 * unit, height: 10 * unit)
                    .background(AppColors.cardAlt, in: RoundedRectangle(cornerRadius: 2.5 * unit))

                VStack(alignment: .leading, spacing: 0.5 * unit) {
                    Text(viewModel.chosen.isEmpty ? "Add exercises" : "Change exercises")
                        .font(.system(size: 4.4 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    Text(viewModel.isCatalogReady ? "Pick the exercises of this day" : "The exercise list is empty")
                        .font(.system(size: 3.4 * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(3 * unit)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 5 * unit))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isCatalogReady)
        .opacity(viewModel.isCatalogReady ? 1 : 0.4)
    }

    // The big "Save plan" button, fixed at the bottom. It works only with at least one exercise.
    private func saveButton(unit: CGFloat) -> some View {
        Button(action: { onSave(viewModel.makePlan()) }) {
            Text("Save plan")
                .font(.system(size: 4.6 * unit, weight: .semibold))
                .foregroundStyle(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4.5 * unit)
                .background(AppColors.textPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave)
        .opacity(viewModel.canSave ? 1 : 0.3)
        .padding(.horizontal, 6 * unit)
        .padding(.top, 5 * unit)
        .padding(.bottom, 3 * unit)
    }

    // The bold title of a section
    private func sectionTitle(_ text: String, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 4.4 * unit, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
    }
}

// MARK: - Previews
// The preview database lives in memory: "Light" and "Dark" fill it from exercises.json.
#Preview("Light") {
    AddPlanView(takenColorIndexes: [0, 1], onBack: {}, onSave: { _ in })
        .modelContainer(planPreviewContainer(withData: true))
}

#Preview("Dark") {
    AddPlanView(takenColorIndexes: [0, 1], onBack: {}, onSave: { _ in })
        .modelContainer(planPreviewContainer(withData: true))
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    AddPlanView(takenColorIndexes: [], onBack: {}, onSave: { _ in })
        .modelContainer(planPreviewContainer(withData: false))
}
