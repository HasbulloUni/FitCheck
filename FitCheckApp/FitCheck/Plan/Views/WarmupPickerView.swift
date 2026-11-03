//
//  WarmupPickerView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// "Warm-up": the user picks 1 or 2 moves. 8 minutes, always on.
// Two lists: the general moves to get warm, and the mobility moves for the muscles of the day.
// Same design as "Add exercises": round back button, big title, rows with a check in the plan color.
// It only draws: the data and the logic live in WarmupPickerViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other screens.
struct WarmupPickerView: View {
    @State private var viewModel: WarmupPickerViewModel
    let label: String                     // the name of the plan, next to the back button
    let accent: Color                     // the color of the plan
    let onDone: ([String]) -> Void        // "Done": gives the picked moves back
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 2 * unit) {
                        topBar(unit: unit)

                        HStack {
                            Text("Warm-up")
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
                        .padding(.top, 3 * unit)

                        Text(viewModel.subtitle)
                            .font(.system(size: 3.6 * unit, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)

                        if !viewModel.generalMoves.isEmpty {
                            section(viewModel.generalTitle, moves: viewModel.generalMoves, unit: unit)
                        }

                        if !viewModel.mobilityMoves.isEmpty {
                            section(viewModel.mobilityTitle, moves: viewModel.mobilityMoves, unit: unit)
                        }

                        if let note = viewModel.rampUpNote {
                            HStack(alignment: .top, spacing: 2 * unit) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 3.6 * unit, weight: .semibold))
                                Text(note)
                                    .font(.system(size: 3.2 * unit, weight: .regular))
                            }
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(3.5 * unit)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardAlt, in: RoundedRectangle(cornerRadius: 4.5 * unit))
                            .padding(.top, 2 * unit)
                        }
                    }
                    .padding(.horizontal, 5 * unit)
                    .padding(.top, 4 * unit)
                    .padding(.bottom, 4 * unit)
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

    // A small grey title and its moves
    private func section(_ title: String, moves: [String], unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 2 * unit) {
            Text(title)
                .font(.system(size: 2.8 * unit, weight: .bold))
                .tracking(0.3 * unit)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.leading, 1 * unit)
                .padding(.top, 2 * unit)

            ForEach(moves, id: \.self) { move in
                row(move, unit: unit)
            }
        }
    }

    // One move: the name, a small note if it has one, and the check on the right.
    // With 2 moves picked the others are faded until one is removed.
    private func row(_ move: String, unit: CGFloat) -> some View {
        let isSelected = viewModel.isSelected(move)
        let isAllowed = viewModel.canToggle(move)

        return Button(action: { viewModel.toggle(move) }) {
            HStack(spacing: 3 * unit) {
                VStack(alignment: .leading, spacing: 0.5 * unit) {
                    Text(WarmupPickerViewModel.title(of: move))
                        .font(.system(size: 3.9 * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)

                    if let note = WarmupPickerViewModel.note(of: move) {
                        Text(note)
                            .font(.system(size: 3.2 * unit, weight: .regular))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                Spacer()

                checkbox(isSelected: isSelected, unit: unit)
            }
            .padding(.horizontal, 4 * unit)
            .padding(.vertical, 3.5 * unit)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 4.5 * unit))
            .overlay(
                RoundedRectangle(cornerRadius: 4.5 * unit)
                    .stroke(accent, lineWidth: isSelected ? 0.5 * unit : 0)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isAllowed)
        .opacity(isAllowed ? 1 : 0.45)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // The square check: plan color with a black tick when picked, an empty outline otherwise
    private func checkbox(isSelected: Bool, unit: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 1.8 * unit)
                .fill(isSelected ? accent : Color.clear)
            RoundedRectangle(cornerRadius: 1.8 * unit)
                .stroke(isSelected ? accent : AppColors.divider, lineWidth: 0.5 * unit)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 3.2 * unit, weight: .bold))
                    .foregroundStyle(Color.black)
            }
        }
        .frame(width: 6.5 * unit, height: 6.5 * unit)
    }

    // The big black button, fixed at the bottom: it works with 1 or 2 moves
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
#Preview("Light") {
    WarmupPickerView(
        viewModel: WarmupPickerViewModel(
            generalMoves: ["Brisk walk", "Light stationary bike", "March on the spot"],
            mobilityMoves: ["Hip circles", "Ankle circles", "Leg swings front to back (holding a support)"],
            mobilityTitle: "MOBILITY FOR LEGS",
            rampUpExercise: "Goblet Squat",
            selected: ["Brisk walk", "Hip circles"]
        ),
        label: "Legs",
        accent: AppColors.muscleOrange,
        onDone: { _ in }
    )
}

#Preview("Dark") {
    WarmupPickerView(
        viewModel: WarmupPickerViewModel(
            generalMoves: ["Brisk walk", "Light stationary bike", "March on the spot"],
            mobilityMoves: ["Hip circles", "Ankle circles", "Leg swings front to back (holding a support)"],
            mobilityTitle: "MOBILITY FOR LEGS",
            rampUpExercise: "Goblet Squat",
            selected: ["Brisk walk"]
        ),
        label: "Legs",
        accent: AppColors.muscleOrange,
        onDone: { _ in }
    )
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    WarmupPickerView(
        viewModel: WarmupPickerViewModel(
            generalMoves: [],
            mobilityMoves: [],
            mobilityTitle: "MOBILITY",
            rampUpExercise: nil,
            selected: []
        ),
        label: "New plan",
        accent: AppColors.muscleBlue,
        onDone: { _ in }
    )
}
