//
//  ExercisePickerView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// "Add exercises": search, browse by muscle, and tap a row to add or remove an exercise.
// It uses our own design, not the native iPhone components.
// While browsing (no search, no group) the list is grouped: the exercises already in the plan
// at the top, "suggested" exercises for muscles not trained yet, then everything else.
// A tap on a row opens its preview (photos and steps); the round button on the right adds or
// removes it right away, with a small "Undo" afterwards.
// A row that breaks a safe limit (max 4 for one muscle) is faded and says why,
// and a banner explains it when the whole list is blocked.
// It only draws: the data and the logic live in ExercisePickerViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct ExercisePickerView: View {
    @State private var viewModel: ExercisePickerViewModel
    let label: String                         // the name of the plan, next to the back button
    let accent: Color                         // the color of the plan: border, check and "Add to ..."
    let onDone: ([CatalogItem]) -> Void       // "Done": gives the chosen exercises back
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ExercisePickerViewModel,
         label: String = "Your plan",
         accent: Color = AppColors.green,
         onDone: @escaping ([CatalogItem]) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.label = label
        self.accent = accent
        self.onDone = onDone
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
                    topBar(unit: unit)

                    Text("Add exercises")
                        .font(.system(size: AppSizes.Text.display * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    searchField(text: $viewModel.searchText, unit: unit)

                    chipsRow(unit: unit)

                    resultsLabel(unit: unit)
                }
                .padding(.horizontal, 5 * unit)
                .padding(.top, 4 * unit)

                ZStack(alignment: .bottom) {
                    exercisesList(unit: unit)

                    if let change = viewModel.recentChange {
                        undoToast(change, unit: unit)
                            .padding(.horizontal, 5 * unit)
                            .padding(.bottom, 2 * unit)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                bottomBar(unit: unit)
            }
            // A tap on a row: the photos and the steps of that exercise
            .sheet(item: $viewModel.previewItem) { item in
                ExercisePreviewView(item: item, viewModel: viewModel, accent: accent)
                    .presentationDetents([.fraction(0.85), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(8 * unit)
            }
        }
        .background(AppColors.background.ignoresSafeArea())
        // "Undo" stays 3 seconds, then it goes away by itself
        .task(id: viewModel.recentChange?.item.id) {
            if viewModel.recentChange == nil { return }
            try? await Task.sleep(for: .seconds(3))
            if Task.isCancelled { return }
            withAnimation { viewModel.clearRecentChange() }
        }
    }

    // MARK: - Top: back button, search, chips, results

    // The round back button and the name of the plan with its color
    private func topBar(unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.section * unit) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
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
                .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                .tracking(0.4 * unit)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Spacer()
        }
    }

    // The search field: a white rounded bar with a magnifier and a clear button
    private func searchField(text: Binding<String>, unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)

            TextField(
                "",
                text: text,
                prompt: Text("Search \(viewModel.pool.count) exercises")
                    .foregroundStyle(AppColors.textSecondary)
            )
            .font(.system(size: AppSizes.Text.body * unit, weight: .regular))
            .foregroundStyle(AppColors.textPrimary)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            if !text.wrappedValue.isEmpty {
                Button(action: { text.wrappedValue = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 4 * unit)
        .frame(height: 12.5 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .overlay(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit).stroke(AppColors.divider, lineWidth: 0.3 * unit))
    }

    // "All" and one chip for each muscle group; the chosen one is black
    private func chipsRow(unit: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSizes.Space.related * unit) {
                chip(title: "All", isSelected: viewModel.selectedGroup == nil, unit: unit) {
                    viewModel.selectedGroup = nil
                }

                ForEach(viewModel.groups, id: \.self) { group in
                    chip(title: group, isSelected: viewModel.selectedGroup == group, unit: unit) {
                        viewModel.selectedGroup = group
                    }
                }
            }
            .padding(.horizontal, 5 * unit)
        }
        // The chips scroll up to the edges of the screen
        .padding(.horizontal, -5 * unit)
    }

    private func chip(title: String, isSelected: Bool, unit: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
                .padding(.horizontal, 4 * unit)
                .frame(height: 9 * unit)
                .background(isSelected ? AppColors.textPrimary : AppColors.card, in: Capsule())
                .overlay(Capsule().stroke(AppColors.divider, lineWidth: 0.3 * unit))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // "ALL · 371" while browsing, or "N RESULTS FOR “word”" / "N RESULTS" while searching/filtering
    private func resultsLabel(unit: CGFloat) -> some View {
        HStack {
            Text(resultsLabelText)
            Spacer()
            if viewModel.isBrowsing {
                Text("MAX \(SafetyRules.maxExercisesPerMuscle) PER MUSCLE")
            }
        }
        .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
        .tracking(0.3 * unit)
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, 1 * unit)
    }

    private var resultsLabelText: String {
        if viewModel.isBrowsing { return "ALL · \(viewModel.visibleItems.count)" }
        if !viewModel.searchText.isEmpty {
            return "\(viewModel.visibleItems.count) RESULTS FOR “\(viewModel.searchText)”"
        }
        return "\(viewModel.visibleItems.count) RESULTS"
    }

    // MARK: - The list: in the plan, suggested, and everything else

    private func exercisesList(unit: CGFloat) -> some View {
        // A change of filter or search can leave the list scrolled past where the new
        // results end: ScrollViewReader lets us jump back to the top every time.
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
                    Color.clear.frame(height: 0).id("top")

                    if viewModel.isBrowsing && !viewModel.selectedItems.isEmpty {
                        inPlanSection(unit: unit)
                    }

                    if viewModel.isBrowsing && !viewModel.suggestedItems.isEmpty {
                        suggestedSection(unit: unit)
                    }

                    resultsSection(unit: unit)
                }
                .padding(.horizontal, 5 * unit)
                .padding(.vertical, 2 * unit)
                .padding(.bottom, 14 * unit)   // room for the "Undo" toast
            }
            .onChange(of: viewModel.selectedGroup) {
                withAnimation { proxy.scrollTo("top", anchor: .top) }
            }
            .onChange(of: viewModel.searchText) {
                withAnimation { proxy.scrollTo("top", anchor: .top) }
            }
        }
    }

    // The exercises already chosen, as small removable chips
    private func inPlanSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            sectionLabel("IN \(label.uppercased()) · \(viewModel.selectedCount)", unit: unit)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSizes.Space.related * unit) {
                    ForEach(viewModel.selectedItems, id: \.id) { item in
                        inPlanChip(item, unit: unit)
                    }
                }
                .padding(.horizontal, 0.5 * unit)
                .padding(.vertical, 0.5 * unit)
            }
        }
    }

    private func inPlanChip(_ item: CatalogItem, unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            ExerciseImageView(paths: Array((viewModel.details(for: item)?.images ?? []).prefix(1)))
                .frame(width: 7.5 * unit, height: 7.5 * unit)
                .clipShape(Circle())

            Text(viewModel.name(of: item))
                .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Button(action: { viewModel.toggle(item) }) {
                Image(systemName: "xmark")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 6 * unit, height: 6 * unit)
                    .background(AppColors.cardAlt, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(viewModel.name(of: item))")
        }
        .padding(.leading, 1 * unit)
        .padding(.trailing, 1.5 * unit)
        .frame(height: 10 * unit)
        .background(AppColors.card, in: Capsule())
        .overlay(Capsule().stroke(accent, lineWidth: 0.4 * unit))
    }

    // Exercises for the muscles the day does not train yet
    private func suggestedSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            sectionLabel("SUGGESTED · NOT TRAINED YET", unit: unit)

            ForEach(viewModel.suggestedItems, id: \.id) { item in
                row(item, unit: unit)
            }
        }
    }

    // The results of the search or the filter, or a message when nothing matches
    private func resultsSection(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            if viewModel.visibleItems.isEmpty {
                noResults(unit: unit)
            } else {
                if let banner = viewModel.fullBanner {
                    fullBanner(banner, unit: unit)
                }
                ForEach(viewModel.visibleItems, id: \.id) { item in
                    row(item, unit: unit)
                }
            }
        }
    }

    private func sectionLabel(_ text: String, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
            .tracking(0.3 * unit)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.horizontal, 1 * unit)
    }

    // Explains why every exercise shown is blocked, e.g. "Quadriceps is full: 4 of 4."
    private func fullBanner(_ text: String, unit: CGFloat) -> some View {
        HStack(alignment: .top, spacing: AppSizes.Space.group * unit) {
            Image(systemName: "info.circle")
                .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
            Text(text)
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
        }
        .foregroundStyle(AppColors.textPrimary)
        .padding(3 * unit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // Nothing matched the search: explains why (when it is worth it) and offers close matches
    private func noResults(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
            VStack(spacing: AppSizes.Space.related * unit) {
                Image(systemName: "shield")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .regular))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 16 * unit, height: 16 * unit)
                    .background(AppColors.card, in: Circle())

                Text("No results for “\(viewModel.searchText)”")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(viewModel.noResultsNote ?? "Try another word or another muscle.")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6 * unit)
            .padding(.horizontal, 4 * unit)

            if !viewModel.alternativeItems.isEmpty {
                sectionLabel("SIMILAR", unit: unit)

                ForEach(viewModel.alternativeItems, id: \.id) { item in
                    row(item, unit: unit)
                }
            }
        }
    }

    // One exercise: photo, name, "Quadriceps · Kettlebell" (or why it cannot be added), and the
    // round add button. A tap on the name opens the preview; the button adds or removes it.
    private func row(_ item: CatalogItem, unit: CGFloat) -> some View {
        let isSelected = viewModel.isSelected(item)
        let blockedText = viewModel.blockedText(item)   // nil = it can be added

        return HStack(spacing: AppSizes.Space.group * unit) {
            Button(action: { viewModel.previewItem = item }) {
                HStack(spacing: AppSizes.Space.group * unit) {
                    ExerciseImageView(paths: viewModel.details(for: item)?.images ?? [])
                        .frame(width: 17 * unit, height: 17 * unit)
                        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))

                    VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                        Text(viewModel.name(of: item))
                            .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)

                        Text(blockedText ?? viewModel.detailText(item))
                            .font(.system(size: AppSizes.Text.body * unit, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows photos and steps")

            addButton(item, isSelected: isSelected, isBlocked: blockedText != nil, unit: unit)
        }
        .padding(.horizontal, 3 * unit)
        .padding(.vertical, 2.8 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit)
                .stroke(accent, lineWidth: isSelected ? 0.5 * unit : 0)
        )
        .opacity(blockedText == nil || isSelected ? 1 : 0.45)
    }

    // The round button: plus (black) to add, check (plan color) when chosen, lock (grey) when blocked
    private func addButton(_ item: CatalogItem, isSelected: Bool, isBlocked: Bool, unit: CGFloat) -> some View {
        Button(action: { viewModel.toggle(item) }) {
            Group {
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Color.black)
                } else if isBlocked {
                    Image(systemName: "lock.fill").foregroundStyle(AppColors.textSecondary)
                } else {
                    Image(systemName: "plus").foregroundStyle(AppColors.background)
                }
            }
            .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
            .frame(width: 11 * unit, height: 11 * unit)
            .background(
                isSelected ? accent : (isBlocked ? AppColors.cardAlt : AppColors.textPrimary),
                in: Circle()
            )
        }
        .buttonStyle(.plain)
        .disabled(isBlocked && !isSelected)
        .accessibilityLabel(
            isSelected ? "Remove \(viewModel.name(of: item))"
            : (isBlocked ? "\(viewModel.name(of: item)) cannot be added" : "Add \(viewModel.name(of: item))")
        )
    }

    // "Goblet Squat added" / "removed" with the "Undo" button
    private func undoToast(_ change: (item: CatalogItem, added: Bool), unit: CGFloat) -> some View {
        HStack {
            Text("\(viewModel.name(of: change.item)) \(change.added ? "added" : "removed")")
                .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                .foregroundStyle(AppColors.background)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            Button(action: { withAnimation { viewModel.undoRecentChange() } }) {
                Text("Undo")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.horizontal, 4 * unit)
                    .frame(height: 9.5 * unit)
                    .background(AppColors.background, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 4.5 * unit)
        .padding(.trailing, 2 * unit)
        .frame(height: 13 * unit)
        .background(AppColors.textPrimary, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // MARK: - Bottom: "N selected" and "Done"

    // "5 selected" and the black "Done" button, in a white bar at the bottom
    private func bottomBar(unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text(viewModel.selectedText)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            Button(action: {
                onDone(viewModel.selectedItems)
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .frame(width: 35 * unit, height: 14 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 6 * unit)
        .padding(.trailing, 5 * unit)
        .padding(.top, 5 * unit)
        .padding(.bottom, 2 * unit)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 7 * unit, topTrailingRadius: 7 * unit)
                .fill(AppColors.card)
                .shadow(color: .black.opacity(0.06), radius: 6 * unit, y: -1.5 * unit)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Previews
// The sample exercises exist only here, inside the previews.
private func previewItems() -> [CatalogItem] {
    [
        CatalogItem(id: "Goblet_Squat", name: "Goblet Squat", level: "beginner", mechanic: "compound", force: "push",
                    equipment: "Kettlebell", muscle: "quadriceps", group: "Legs", variants: [:], needsBar: false),
        CatalogItem(id: "Leg_Press", name: "Leg Press", level: "beginner", mechanic: "compound", force: "push",
                    equipment: "Machine", muscle: "quadriceps", group: "Legs", variants: [:], needsBar: false),
        CatalogItem(id: "Dumbbell_Lunges", name: "Dumbbell Lunges", level: "beginner", mechanic: "compound",
                    force: "push", equipment: "Dumbbell", muscle: "quadriceps", group: "Legs", variants: [:],
                    needsBar: false),
        CatalogItem(id: "Hack_Squat", name: "Hack Squat", level: "beginner", mechanic: "compound", force: "push",
                    equipment: "Machine", muscle: "quadriceps", group: "Legs", variants: [:], needsBar: false),
        CatalogItem(id: "Bodyweight_Squat", name: "Bodyweight Squat", level: "beginner", mechanic: "compound",
                    force: "push", equipment: "Bodyweight", muscle: "quadriceps", group: "Legs", variants: [:],
                    needsBar: false),
        CatalogItem(id: "Pull_Through", name: "Pull Through", level: "beginner", mechanic: "compound", force: "pull",
                    equipment: "Cable", muscle: "glutes", group: "Glutes", variants: [:], needsBar: false),
        CatalogItem(id: "Calf_Press", name: "Calf Press", level: "beginner", mechanic: "isolation", force: "push",
                    equipment: "Machine", muscle: "calves", group: "Legs", variants: [:], needsBar: false)
    ]
}

#Preview("Light") {
    ExercisePickerView(
        viewModel: ExercisePickerViewModel(pool: previewItems(), selectedIds: ["Goblet_Squat", "Leg_Press"],
                                           goal: .tone, level: .medium, planName: "Leg day"),
        label: "Leg day",
        accent: AppColors.muscleOrange,
        onDone: { _ in }
    )
}

#Preview("Dark") {
    ExercisePickerView(
        viewModel: ExercisePickerViewModel(pool: previewItems(), selectedIds: ["Goblet_Squat", "Leg_Press"],
                                           goal: .tone, level: .medium, planName: "Leg day"),
        label: "Leg day",
        accent: AppColors.muscleOrange,
        onDone: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    ExercisePickerView(
        viewModel: ExercisePickerViewModel(pool: [], selectedIds: [], goal: .tone, level: .medium),
        onDone: { _ in }
    )
}
