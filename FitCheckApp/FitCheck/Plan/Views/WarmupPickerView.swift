//
//  WarmupPickerView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// "Warm-up": the user picks 1 to 3 moves. Same row style as "Add exercises" (photo, name,
// muscle), but with no search bar: there are only a handful of moves, so they all fit on
// one screen.
// It only draws: the data and the logic live in WarmupPickerViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct WarmupPickerView: View {
    @State private var viewModel: WarmupPickerViewModel
    let label: String                     // the name of the plan, next to the back button
    let accent: Color                     // the color of the plan
    let onDone: ([String]) -> Void        // "Done": gives the picked exercise ids back
    @Environment(\.dismiss) private var dismiss

    init(viewModel: WarmupPickerViewModel, label: String, accent: Color,
         onDone: @escaping ([String]) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.label = label
        self.accent = accent
        self.onDone = onDone
    }

    var body: some View {
        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2 * unit) {
                    topBar(unit: unit)

                    HStack {
                        Text(viewModel.title)
                            .font(.system(size: 8 * unit, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        Text(viewModel.countText)
                            .font(.system(size: 3 * unit, weight: .bold))
                            .foregroundStyle(viewModel.canFinish ? Color.black : AppColors.textPrimary)
                            .padding(.horizontal, 2.2 * unit)
                            .frame(height: 6 * unit)
                            .background(viewModel.canFinish ? AppColors.greenSoft : AppColors.cardAlt,
                                        in: Capsule())
                    }
                }
                .padding(.horizontal, 5 * unit)
                .padding(.top, 4 * unit)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 3 * unit) {
                        ForEach(viewModel.items, id: \.id) { item in
                            row(item, unit: unit)
                        }
                    }
                    .padding(.horizontal, 5 * unit)
                    .padding(.vertical, 3 * unit)
                }

                doneButton(unit: unit)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    // MARK: - Pieces of the screen

    // The round back button and the name of the plan with its color
    private func topBar(unit: CGFloat) -> some View {
        HStack(spacing: 3.5 * unit) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 4.6 * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 11.5 * unit, height: 11.5 * unit)
                    .background(AppColors.card, in: Circle())
                    .overlay(Circle().stroke(AppColors.divider, lineWidth: 0.3 * unit))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Circle()
                .fill(accent)
                .frame(width: 3 * unit, height: 3 * unit)

            Text(label.uppercased())
                .font(.system(size: 3 * unit, weight: .bold))
                .tracking(0.4 * unit)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Spacer()
        }
    }

    // One move: photo, name, muscle, and the round add button on the right.
    // With 3 moves picked the others are faded until one is removed.
    private func row(_ item: CatalogItem, unit: CGFloat) -> some View {
        let isSelected = viewModel.isSelected(item)
        let isAllowed = viewModel.canToggle(item)

        return Button(action: { viewModel.toggle(item) }) {
            HStack(spacing: 3.2 * unit) {
                ExerciseImageView(paths: viewModel.images(of: item))
                    .frame(width: 17 * unit, height: 17 * unit)
                    .clipShape(RoundedRectangle(cornerRadius: 3.6 * unit))

                VStack(alignment: .leading, spacing: 0.8 * unit) {
                    Text(item.name)
                        .font(.system(size: 4.6 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(item.muscle.capitalized)
                        .font(.system(size: 3.6 * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                addButton(isSelected: isSelected, isBlocked: !isAllowed, unit: unit)
            }
            .padding(.horizontal, 3 * unit)
            .padding(.vertical, 2.8 * unit)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 5 * unit))
            .overlay(
                RoundedRectangle(cornerRadius: 5 * unit)
                    .stroke(accent, lineWidth: isSelected ? 0.5 * unit : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAllowed)
        .opacity(isAllowed ? 1 : 0.45)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // The round button: plus (black) to add, check (plan color) when chosen
    private func addButton(isSelected: Bool, isBlocked: Bool, unit: CGFloat) -> some View {
        Image(systemName: isSelected ? "checkmark" : "plus")
            .font(.system(size: 4.6 * unit, weight: .bold))
            .foregroundStyle(isSelected ? Color.black : AppColors.background)
            .frame(width: 11 * unit, height: 11 * unit)
            .background(isSelected ? accent : AppColors.textPrimary, in: Circle())
    }

    // The big black button, fixed at the bottom: it works with 1 to 3 moves
    private func doneButton(unit: CGFloat) -> some View {
        Button(action: {
            onDone(viewModel.selected)
            dismiss()
        }) {
            HStack {
                Text(viewModel.doneTitle)
                    .font(.system(size: 4.4 * unit, weight: .bold))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 4.4 * unit, weight: .bold))
                    .foregroundStyle(viewModel.canFinish ? AppColors.textPrimary : AppColors.textSecondary)
                    .frame(width: 11 * unit, height: 11 * unit)
                    .background(AppColors.background, in: Circle())
            }
            .foregroundStyle(viewModel.canFinish ? AppColors.background : AppColors.textSecondary)
            .padding(.leading, 6.5 * unit)
            .padding(.trailing, 2 * unit)
            .frame(height: 15 * unit)
            .background(viewModel.canFinish ? AppColors.textPrimary : AppColors.cardAlt, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canFinish)
        .padding(.horizontal, 5 * unit)
        .padding(.top, 3 * unit)
        .padding(.bottom, 2 * unit)
    }
}

// MARK: - Previews
// The sample moves exist only here, inside the previews.
private func previewItems() -> [CatalogItem] {
    [
        CatalogItem(id: "Standing_Hip_Circles", name: "Standing Hip Circles", level: "beginner",
                    mechanic: "isolation", force: "static", equipment: "Bodyweight", muscle: "abductors",
                    group: "Legs", variants: [:], needsBar: false),
        CatalogItem(id: "Ankle_Circles", name: "Ankle Circles", level: "beginner", mechanic: "isolation",
                    force: "static", equipment: "Bodyweight", muscle: "calves", group: "Legs", variants: [:],
                    needsBar: false),
        CatalogItem(id: "Arm_Circles", name: "Arm Circles", level: "beginner", mechanic: "isolation",
                    force: "static", equipment: "Bodyweight", muscle: "shoulders", group: "Shoulders",
                    variants: [:], needsBar: false),
        CatalogItem(id: "Wrist_Circles", name: "Wrist Circles", level: "beginner", mechanic: "isolation",
                    force: "static", equipment: "Bodyweight", muscle: "forearms", group: "Arms", variants: [:],
                    needsBar: false),
        CatalogItem(id: "Single_Leg_Glute_Bridge", name: "Single Leg Glute Bridge", level: "beginner",
                    mechanic: "isolation", force: "pull", equipment: "Bodyweight", muscle: "glutes",
                    group: "Glutes", variants: [:], needsBar: false),
        CatalogItem(id: "Walking_Treadmill", name: "Walking, Treadmill", level: "beginner", mechanic: "",
                    force: "", equipment: "Machine", muscle: "quadriceps", group: "Legs", variants: [:],
                    needsBar: false)
    ]
}

#Preview("Light") {
    WarmupPickerView(
        viewModel: WarmupPickerViewModel(items: previewItems(), details: [:],
                                         selected: ["Ankle_Circles", "Walking_Treadmill"]),
        label: "Legs",
        accent: AppColors.muscleOrange,
        onDone: { _ in }
    )
}

#Preview("Dark") {
    WarmupPickerView(
        viewModel: WarmupPickerViewModel(items: previewItems(), details: [:], selected: []),
        label: "Legs",
        accent: AppColors.muscleOrange,
        onDone: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    WarmupPickerView(
        viewModel: WarmupPickerViewModel(items: [], details: [:], selected: []),
        label: "New plan",
        accent: AppColors.muscleBlue,
        onDone: { _ in }
    )
}
