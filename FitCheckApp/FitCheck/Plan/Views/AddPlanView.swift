//
//  AddPlanView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI
import SwiftData

// The screen "Add your plan" (one training day), design "Color hero":
//  - a big header in the color of the plan: name, 60 / 90 min, color
//  - the warm-up card (opens "Warm-up"), the main part with "+ Add" and the × of each exercise,
//    the cool-down card with its switch
//  - when the user scrolls, a small header with the minutes bar takes the place of the big one
//  - "Undo" after an exercise is removed, and the big button that says what is still missing
// It only draws: the data and the logic live in AddPlanViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct AddPlanView: View {
    @Query private var exercises: [Exercise]
    @State private var viewModel: AddPlanViewModel
    @State private var isHeaderSmall = false      // true when the big header has scrolled away
    @FocusState private var isNameFocused: Bool

    let takenColorIndexes: [Int]          // the colors already used by other plans
    let otherPlanNames: [String]          // the names of the other plans (for the warning)
    let onBack: () -> Void                // the round back button: closes without saving
    let onSave: (PlanItem) -> Void        // "Save to My plans": gives the new plan to the Home

    // editing: the plan to change (nil = a new plan)
    init(editing plan: PlanItem? = nil, takenColorIndexes: [Int], otherPlanNames: [String] = [],
         onBack: @escaping () -> Void, onSave: @escaping (PlanItem) -> Void) {
        _viewModel = State(initialValue: AddPlanViewModel(takenColorIndexes: takenColorIndexes,
                                                          otherPlanNames: otherPlanNames, editing: plan))
        self.otherPlanNames = otherPlanNames
        self.takenColorIndexes = takenColorIndexes
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width
            let topInset = geo.safeAreaInsets.top

            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        bigHeader(unit: unit, topInset: topInset)

                        VStack(spacing: AppSizes.Space.related * unit) {
                            warmupCard(unit: unit)
                            mainPartTitle(unit: unit)

                            if viewModel.chosen.isEmpty {
                                emptyCard(unit: unit)
                            } else {
                                ForEach(Array(viewModel.chosen.enumerated()), id: \.element.id) { position, exercise in
                                    exerciseRow(exercise, number: position + 1, unit: unit)
                                }
                            }

                            cooldownCard(unit: unit)

                            // "Save to My plans" scrolls with the rest of the card: it never
                            // floats over the tab bar, so the two never look fused together.
                            if let removed = viewModel.lastRemoved {
                                undoMessage(removed, unit: unit)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            saveButton(unit: unit)
                                .padding(.top, 1.5 * unit)
                        }
                        .padding(.horizontal, 5 * unit)
                        .padding(.top, 3 * unit)
                        .padding(.bottom, 4 * unit)
                    }
                }
                .scrollDismissesKeyboard(.immediately)
                .ignoresSafeArea(edges: .top)
                // The small header appears when the big one has scrolled away
                .onScrollGeometryChange(for: Bool.self) { scroll in
                    scroll.contentOffset.y + scroll.contentInsets.top > 60 * unit
                } action: { _, isSmall in
                    withAnimation(.easeInOut(duration: 0.2)) { isHeaderSmall = isSmall }
                }

                if isHeaderSmall {
                    smallHeader(unit: unit, topInset: topInset)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            // "+ Add": the list of exercises, over the whole screen
            .fullScreenCover(isPresented: $viewModel.isPickerShown) {
                ExercisePickerView(
                    viewModel: ExercisePickerViewModel(
                        pool: viewModel.pool,
                        selectedIds: viewModel.chosen.map { $0.id },
                        goal: viewModel.goal,
                        level: viewModel.level,
                        targetMinutes: viewModel.minutes,
                        warmupMinutes: viewModel.warmupMinutes,
                        cooldownMinutes: viewModel.hasCooldown ? Int(SafetyRules.cooldownMinutes) : 0,
                        planName: viewModel.displayName,
                        details: viewModel.pickerDetails
                    ),
                    label: viewModel.displayName,
                    accent: viewModel.color,
                    onDone: { viewModel.setExercises($0) }
                )
            }
            // The warm-up card: pick 1 or 2 moves
            .fullScreenCover(isPresented: $viewModel.isWarmupShown) {
                WarmupPickerView(
                    viewModel: viewModel.makeWarmupPicker(),
                    label: viewModel.displayName,
                    accent: viewModel.color,
                    onDone: { viewModel.setWarmupMoves($0) }
                )
            }
            // A tap on an exercise: sets, reps, rest and "Remove from plan"
            .sheet(item: $viewModel.detailExercise) { exercise in
                ExerciseDetailView(viewModel: viewModel, exerciseId: exercise.id)
                    .presentationDetents([.fraction(0.85), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(8 * unit)
            }
        }
        .background(AppColors.background)
        .onAppear { viewModel.loadCatalog(from: exercises) }
        .onChange(of: exercises.count) { viewModel.loadCatalog(from: exercises) }
        // "Undo" stays 4 seconds, then it goes away by itself
        .task(id: viewModel.lastRemoved?.id) {
            if viewModel.lastRemoved == nil { return }
            try? await Task.sleep(for: .seconds(4))
            if Task.isCancelled { return }
            withAnimation { viewModel.hideUndo() }
        }
    }

    // MARK: - Big header (in the color of the plan)
    // The plan color is light in both themes, so the texts on it are fixed black on purpose
    // (like the yellow Today card).

    private func bigHeader(unit: CGFloat, topInset: CGFloat) -> some View {
        @Bindable var viewModel = viewModel

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSizes.Space.section * unit) {
                backButton(unit: unit)

                Text(viewModel.isEditing ? "EDIT PLAN" : "NEW PLAN")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .tracking(0.4 * unit)
                    .foregroundStyle(.black)

                Spacer()
            }

            // The name: the suggested one is shown faded until the user writes one
            HStack(spacing: AppSizes.Space.group * unit) {
                TextField(
                    "",
                    text: $viewModel.name,
                    prompt: Text(viewModel.suggestedName).foregroundStyle(.black.opacity(0.45))
                )
                .font(.system(size: AppSizes.Text.hero * unit, weight: .bold))
                .foregroundStyle(.black)
                .focused($isNameFocused)
                .submitLabel(.done)

                Button(action: { isNameFocused = true }) {
                    Image(systemName: "pencil")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 9.5 * unit, height: 9.5 * unit)
                        .background(.white.opacity(0.5), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rename")
            }
            .padding(.top, 5 * unit)

            // Same name as another plan: allowed, but the user is told
            if viewModel.hasDuplicateName {
                Text("Another plan has this name")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.7))
                    .padding(.top, 1 * unit)
            }

            HStack(spacing: AppSizes.Space.related * unit) {
                statPill(icon: "dumbbell", text: viewModel.exerciseCountText, unit: unit)
                statPill(icon: "clock", text: "about \(viewModel.estimatedMinutes) min", unit: unit)
            }
            .padding(.top, 3.5 * unit)

            durationSwitch(unit: unit)
                .padding(.top, 4 * unit)

            colorRow(unit: unit)
                .padding(.top, 3.5 * unit)
        }
        .padding(.horizontal, 5.5 * unit)
        .padding(.top, topInset + 2.5 * unit)
        .padding(.bottom, 4 * unit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            viewModel.color,
            in: UnevenRoundedRectangle(bottomLeadingRadius: 9 * unit, bottomTrailingRadius: 9 * unit)
        )
    }

    // The round white back button (on the color of the plan)
    private func backButton(unit: CGFloat) -> some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 11.5 * unit, height: 11.5 * unit)
                .background(.white, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }

    // A small see-through pill, e.g. "5 exercises" or "about 42 min"
    private func statPill(icon: String, text: String, unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            Image(systemName: icon)
                .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
            Text(text)
                .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 3 * unit)
        .frame(height: 8 * unit)
        .background(.white.opacity(0.42), in: Capsule())
    }

    // "60 min" and "90 min" in a black bar: the chosen one is white
    private func durationSwitch(unit: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(SafetyRules.sessionMinutesOptions, id: \.self) { option in
                let isSelected = viewModel.minutes == option

                Button(action: { viewModel.minutes = option }) {
                    Text(EditWeekRules.durationTitle(option))
                        .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                        .foregroundStyle(isSelected ? Color.black : Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 11.5 * unit)
                        .background(isSelected ? Color.white : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(1 * unit)
        .background(.black, in: Capsule())
    }

    // The colors: the ones used by other plans are faded and cannot be tapped
    private func colorRow(unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.section * unit) {
            Text("Color")
                .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                .foregroundStyle(.black.opacity(0.7))

            ForEach(PlanPalette.colors.indices, id: \.self) { index in
                let isSelected = viewModel.colorIndex == index
                // When every color is used (more plans than colors) all of them can be picked again
                let allTaken = PlanPalette.colors.indices.allSatisfy { takenColorIndexes.contains($0) }
                let isTaken = !allTaken && takenColorIndexes.contains(index)

                Button(action: { viewModel.colorIndex = index }) {
                    ZStack {
                        // The chosen color has a white and a black ring around it
                        if isSelected {
                            Circle().fill(.black)
                            Circle().fill(.white).padding(0.6 * unit)
                        }
                        Circle()
                            .fill(PlanPalette.colors[index])
                            .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 0.4 * unit))
                            .padding(1.4 * unit)
                    }
                    .frame(width: 9.5 * unit, height: 9.5 * unit)
                }
                .buttonStyle(.plain)
                .disabled(isTaken)
                .opacity(isTaken ? 0.25 : 1)
                .accessibilityLabel(isTaken ? "Color already used" : "Color \(index + 1)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    // MARK: - Small header (after scrolling)

    private func smallHeader(unit: CGFloat, topInset: CGFloat) -> some View {
        VStack(spacing: AppSizes.Space.group * unit) {
            HStack(spacing: AppSizes.Space.section * unit) {
                backButton(unit: unit)

                VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                    Text(viewModel.headerLabel)
                        .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
                        .tracking(0.3 * unit)
                        .foregroundStyle(.black.opacity(0.7))
                    Text(viewModel.displayName)
                        .font(.system(size: AppSizes.Text.title * unit, weight: .bold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()
            }

            // The minutes bar: how much of the 60 or 90 minutes is used
            HStack(spacing: AppSizes.Space.group * unit) {
                Capsule()
                    .fill(.white.opacity(0.45))
                    .frame(width: 56 * unit, height: 2 * unit)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.black)
                            .frame(width: 56 * unit * CGFloat(viewModel.timeShare), height: 2 * unit)
                    }

                Text(viewModel.timeText)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 5 * unit)
        .padding(.top, topInset + 2 * unit)
        .padding(.bottom, 4.5 * unit)
        .background(
            viewModel.color,
            in: UnevenRoundedRectangle(bottomLeadingRadius: 8 * unit, bottomTrailingRadius: 8 * unit)
        )
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Warm-up, main part, cool-down

    // The warm-up card: mandatory, no on/off switch. A small check shows it is picked.
    private func warmupCard(unit: CGFloat) -> some View {
        return Button(action: { viewModel.isWarmupShown = true }) {
            HStack(spacing: AppSizes.Space.section * unit) {
                iconTile("flame", unit: unit)

                VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                    Text("Warm-up")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(viewModel.warmupSummary)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                if viewModel.isWarmupReady {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                        .foregroundStyle(AppColors.greenSoft)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Pick the warm-up move")
        .padding(2.5 * unit)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // "Main part" and, once there is at least 1 exercise, the count against the minimum of 4
    // and the black "+ Add" button. While the list is empty, emptyCard below already has its
    // own "+" button and its own "at least 4 exercises" text, so this row stays just the title.
    private func mainPartTitle(unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Text("Main part")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                .foregroundStyle(AppColors.textPrimary)

            if !viewModel.chosen.isEmpty {
                countBadge(viewModel.mainCountText, isDone: viewModel.hasEnoughExercises, unit: unit)

                Spacer()

                Button(action: { viewModel.isPickerShown = true }) {
                    HStack(spacing: AppSizes.Space.related * unit) {
                        Image(systemName: "plus")
                            .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                        Text("Add")
                            .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                    }
                    .foregroundStyle(AppColors.background)
                    .padding(.horizontal, 3.5 * unit)
                    .frame(height: 8.5 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add exercises")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 1 * unit)
        .padding(.top, 1.5 * unit)
    }

    // No exercises yet: a dashed card that opens "Add exercises"
    private func emptyCard(unit: CGFloat) -> some View {
        Button(action: { viewModel.isPickerShown = true }) {
            VStack(spacing: AppSizes.Space.related * unit) {
                Image(systemName: "plus")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .frame(width: 9.5 * unit, height: 9.5 * unit)
                    .background(AppColors.textPrimary, in: Circle())

                Text(viewModel.isCatalogReady ? "Pick the exercises for this day" : "Loading the exercise list…")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4.5 * unit)
            .overlay(
                RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit)
                    .strokeBorder(AppColors.divider, style: StrokeStyle(lineWidth: 0.5 * unit, dash: [2 * unit, 1.5 * unit]))
            )
        }
        .buttonStyle(.plain)
    }

    // One exercise: number, name, "3 × 10-12 · rest 75 s · Quadriceps" and the × button.
    // A tap on the row opens the details.
    private func exerciseRow(_ exercise: ChosenExercise, number: Int, unit: CGFloat) -> some View {
        let name = viewModel.displayName(of: exercise.item)

        return HStack(spacing: AppSizes.Space.group * unit) {
            Button(action: { viewModel.detailExercise = exercise }) {
                HStack(spacing: AppSizes.Space.group * unit) {
                    Text("\(number)")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(width: 9.5 * unit, height: 9.5 * unit)
                        .background(viewModel.color.opacity(0.3), in: RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))

                    VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                        Text(name)
                            .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(viewModel.rowDetail(exercise))
                            .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows sets, reps and rest")

            Button(action: { withAnimation { viewModel.removeExercise(exercise) } }) {
                Image(systemName: "xmark")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 8.5 * unit, height: 8.5 * unit)
                    .background(AppColors.cardAlt, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(name)")
        }
        .padding(.horizontal, 3 * unit)
        .padding(.vertical, 3.2 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // The cool-down card: it can be switched off
    private func cooldownCard(unit: CGFloat) -> some View {
        @Bindable var viewModel = viewModel

        return HStack(spacing: AppSizes.Space.section * unit) {
            iconTile("leaf", unit: unit)

            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text("Cool-down")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                Text(viewModel.cooldownSummary)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            Toggle("Cool-down", isOn: $viewModel.hasCooldown)
                .labelsHidden()
                .tint(AppColors.greenSoft)
        }
        .padding(2.5 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // MARK: - "Undo" and the big button (they scroll with the rest of the card)

    // "Goblet Squat removed" with the "Undo" button
    private func undoMessage(_ removed: ChosenExercise, unit: CGFloat) -> some View {
        HStack {
            Text("\(viewModel.displayName(of: removed.item)) removed")
                .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                .foregroundStyle(AppColors.background)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            Button(action: { withAnimation { viewModel.undoRemove() } }) {
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

    // The big button: "Save to My plans", or what is still missing (then it is grey)
    private func saveButton(unit: CGFloat) -> some View {
        let isEnabled = viewModel.isSaveEnabled

        return Button(action: {
            if let plan = viewModel.pressSave() {
                onSave(plan)
            }
        }) {
            HStack {
                Text(viewModel.saveTitle)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(isEnabled ? AppColors.textPrimary : AppColors.textSecondary)
                    .frame(width: 11 * unit, height: 11 * unit)
                    .background(AppColors.background, in: Circle())
            }
            .foregroundStyle(isEnabled ? AppColors.background : AppColors.textSecondary)
            .padding(.leading, 6.5 * unit)
            .padding(.trailing, 2 * unit)
            .frame(height: 15 * unit)
            .background(isEnabled ? AppColors.textPrimary : AppColors.cardAlt, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Small pieces

    // A square tile with an icon, e.g. the flame of the warm-up
    private func iconTile(_ icon: String, unit: CGFloat) -> some View {
        Image(systemName: icon)
            .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
            .frame(width: 9.5 * unit, height: 9.5 * unit)
            .background(AppColors.cardAlt, in: RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
    }

    // "2 / 2" or "5 · min 4": green when the rule is met, grey otherwise
    private func countBadge(_ text: String, isDone: Bool, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
            .foregroundStyle(isDone ? Color.black : AppColors.textPrimary)
            .padding(.horizontal, 2.2 * unit)
            .frame(height: 6 * unit)
            .background(isDone ? AppColors.greenSoft : AppColors.cardAlt, in: Capsule())
    }

    // A small grey chip, e.g. "Brisk walk · 4 min"
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
