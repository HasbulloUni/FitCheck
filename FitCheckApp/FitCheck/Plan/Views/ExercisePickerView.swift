//
//  ExercisePickerView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// "Pick your exercises": tap a row to add or remove an exercise.
// It uses our own design, not the native iPhone components: round back button, big title,
// search field, muscle chips, rows with a green check and a big black "Done" button.
// It only draws: the data and the logic live in ExercisePickerViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct ExercisePickerView: View {
    @State private var viewModel: ExercisePickerViewModel
    let label: String                         // the small green text next to the back button
    let onDone: ([CatalogItem]) -> Void       // "Done": gives the chosen exercises back
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ExercisePickerViewModel,
         label: String = "Your plan",
         onDone: @escaping ([CatalogItem]) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.label = label
        self.onDone = onDone
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3 * unit) {
                    topBar(unit: unit)

                    VStack(alignment: .leading, spacing: 1.5 * unit) {
                        Text("Pick your exercises")
                            .font(.system(size: 9 * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        Text("Tap to add or remove exercises.")
                            .font(.system(size: 4.2 * unit, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    searchField(text: $viewModel.searchText, unit: unit)

                    chipsRow(unit: unit)

                    Text("\(viewModel.visibleItems.count) RESULTS")
                        .font(.system(size: 3.2 * unit, weight: .bold))
                        .tracking(0.3 * unit)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal, 6 * unit)
                .padding(.top, 4 * unit)

                exercisesList(unit: unit)

                bottomBar(unit: unit)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    // MARK: - Pieces of the screen

    // The round back button and the small green label
    private func topBar(unit: CGFloat) -> some View {
        HStack(spacing: 4 * unit) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 4 * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 12 * unit, height: 12 * unit)
                    .background(AppColors.card, in: Circle())
                    .overlay(Circle().stroke(AppColors.divider, lineWidth: 0.3 * unit))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text(label.uppercased())
                .font(.system(size: 3.6 * unit, weight: .bold))
                .tracking(0.4 * unit)
                .foregroundStyle(AppColors.muscleGreen)

            Spacer()
        }
    }

    // The search field: a white rounded bar with a magnifier and a clear button
    private func searchField(text: Binding<String>, unit: CGFloat) -> some View {
        HStack(spacing: 2.5 * unit) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 4.4 * unit, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            TextField(
                "",
                text: text,
                prompt: Text("Search \(viewModel.pool.count) exercises")
                    .foregroundStyle(AppColors.textSecondary)
            )
            .font(.system(size: 4.4 * unit, weight: .regular))
            .foregroundStyle(AppColors.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            if !text.wrappedValue.isEmpty {
                Button(action: { text.wrappedValue = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 4.4 * unit))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 4.5 * unit)
        .padding(.vertical, 4 * unit)
        .background(AppColors.card, in: Capsule())
    }

    // "All" and one chip for each muscle group; the chosen one is black
    private func chipsRow(unit: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2 * unit) {
                chip(title: "All", isSelected: viewModel.selectedGroup == nil, unit: unit) {
                    viewModel.selectedGroup = nil
                }

                ForEach(viewModel.groups, id: \.self) { group in
                    chip(title: group, isSelected: viewModel.selectedGroup == group, unit: unit) {
                        viewModel.selectedGroup = group
                    }
                }
            }
            .padding(.horizontal, 6 * unit)
        }
        // The chips scroll up to the edges of the screen
        .padding(.horizontal, -6 * unit)
    }

    private func chip(title: String, isSelected: Bool, unit: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 3.8 * unit, weight: .bold))
                .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
                .padding(.horizontal, 5 * unit)
                .padding(.vertical, 3 * unit)
                .background(isSelected ? AppColors.textPrimary : AppColors.card, in: Capsule())
                .overlay(Capsule().stroke(AppColors.divider, lineWidth: 0.3 * unit))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // The list of exercises, or a message when nothing matches
    private func exercisesList(unit: CGFloat) -> some View {
        ScrollView {
            if viewModel.visibleItems.isEmpty {
                VStack(spacing: 1.5 * unit) {
                    Text("No exercises found")
                        .font(.system(size: 4.6 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text("Try another word or another muscle.")
                        .font(.system(size: 3.8 * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12 * unit)
            } else {
                LazyVStack(spacing: 2 * unit) {
                    ForEach(viewModel.visibleItems, id: \.id) { item in
                        row(item, unit: unit)
                    }
                }
                .padding(.horizontal, 6 * unit)
                .padding(.vertical, 2 * unit)
            }
        }
    }

    // One exercise: name, muscle and type, and the check on the right.
    // The chosen rows have a green border.
    private func row(_ item: CatalogItem, unit: CGFloat) -> some View {
        let isSelected = viewModel.isSelected(item)
        let isAllowed = viewModel.canToggle(item)   // false when a safe limit is reached

        return Button(action: { viewModel.toggle(item) }) {
            HStack(spacing: 3 * unit) {
                VStack(alignment: .leading, spacing: 0.8 * unit) {
                    Text(viewModel.name(of: item))
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

                checkbox(isSelected: isSelected, unit: unit)
            }
            .padding(.horizontal, 4 * unit)
            .padding(.vertical, 3 * unit)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 4.5 * unit))
            .overlay(
                RoundedRectangle(cornerRadius: 4.5 * unit)
                    .stroke(AppColors.green, lineWidth: isSelected ? 0.6 * unit : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAllowed)
        .opacity(isAllowed ? 1 : 0.4)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // The square check: green with a white tick when chosen, an empty outline otherwise
    private func checkbox(isSelected: Bool, unit: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.8 * unit)
                .fill(isSelected ? AppColors.green : Color.clear)
            RoundedRectangle(cornerRadius: 1.8 * unit)
                .stroke(isSelected ? AppColors.green : AppColors.divider, lineWidth: 0.6 * unit)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 3.2 * unit, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 7 * unit, height: 7 * unit)
    }

    // "11 exercises selected", "about 67 min" and the big "Done" button, fixed at the bottom
    private func bottomBar(unit: CGFloat) -> some View {
        VStack(spacing: 4 * unit) {
            HStack {
                Text("\(viewModel.selectedCount) exercises selected")
                    .font(.system(size: 4.2 * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text("about \(viewModel.estimatedMinutes) min")
                    .font(.system(size: 3.8 * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Button(action: {
                onDone(viewModel.selectedItems)
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 4.6 * unit, weight: .semibold))
                    .foregroundStyle(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4.5 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 6 * unit)
        .padding(.top, 4 * unit)
        .padding(.bottom, 3 * unit)
    }
}

// MARK: - Previews
// The sample exercises exist only here, inside the previews.
private func previewItems() -> [CatalogItem] {
    [
        CatalogItem(id: "a", name: "Back squat", level: "beginner", mechanic: "compound", force: "push",
                    equipment: "Barbell", muscle: "quadriceps", group: "Legs", variants: [:], needsBar: true),
        CatalogItem(id: "b", name: "Leg press", level: "beginner", mechanic: "compound", force: "push",
                    equipment: "Machine", muscle: "quadriceps", group: "Legs", variants: [:], needsBar: false),
        CatalogItem(id: "c", name: "Goblet squat", level: "beginner", mechanic: "compound", force: "push",
                    equipment: "Dumbbell", muscle: "quadriceps", group: "Legs", variants: [:], needsBar: false),
        CatalogItem(id: "d", name: "Leg extension", level: "beginner", mechanic: "isolation", force: "push",
                    equipment: "Machine", muscle: "quadriceps", group: "Legs", variants: [:], needsBar: false),
        CatalogItem(id: "e", name: "Bench press", level: "beginner", mechanic: "compound", force: "push",
                    equipment: "Barbell", muscle: "chest", group: "Chest", variants: [:], needsBar: true)
    ]
}

#Preview("Light") {
    ExercisePickerView(
        viewModel: ExercisePickerViewModel(pool: previewItems(), selectedIds: ["a", "b"], goal: .tone, level: .easy),
        onDone: { _ in }
    )
}

#Preview("Dark") {
    ExercisePickerView(
        viewModel: ExercisePickerViewModel(pool: previewItems(), selectedIds: ["a", "b"], goal: .tone, level: .easy),
        onDone: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    ExercisePickerView(
        viewModel: ExercisePickerViewModel(pool: [], selectedIds: [], goal: .tone, level: .easy),
        onDone: { _ in }
    )
}
