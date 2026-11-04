//
//  WorkoutView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// The workout screen: opened by Start. One step at a time, always the same layout:
// header, title, a BIG photo that fills the free space, the set chips, the card, the Next button.
// The ViewModel owns everything; this View only draws and calls its functions.
struct WorkoutView: View {

    @State private var viewModel: WorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    let onClose: () -> Void

    init(plan: PlanItem, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: WorkoutViewModel(plan: plan))
        self.onClose = onClose
    }

    // Used by the previews: a ViewModel already filled with sample steps
    init(viewModel: WorkoutViewModel, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    var body: some View {
        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ZStack {
                AppColors.background.ignoresSafeArea()

                if viewModel.phase == .summary, let summary = viewModel.summary {
                    WorkoutSummaryView(planName: viewModel.plan.name, summary: summary,
                                       unit: unit, onDone: onClose)
                } else if let step = viewModel.currentStep {
                    stepScreen(step, unit: unit)
                }
            }
            .sheet(isPresented: $viewModel.isInfoOpen) {
                if let step = viewModel.currentStep {
                    ExerciseInfoSheet(step: step, unit: unit, onClose: { viewModel.isInfoOpen = false })
                        .presentationDetents([.medium, .large])
                }
            }
            .confirmationDialog("Finish the workout?",
                                isPresented: $viewModel.isLeaveConfirmOpen,
                                titleVisibility: .visible) {
                Button("Finish and save") { viewModel.finish() }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text(viewModel.leaveMessage)
            }
        }
        .onAppear { viewModel.begin(context: modelContext) }
        .onChange(of: viewModel.shouldClose) { _, shouldClose in
            if shouldClose { onClose() }
        }
    }

    // MARK: One step on the screen

    private func stepScreen(_ step: WorkoutStep, unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            WorkoutHeaderView(
                text: viewModel.headerText,
                unit: unit,
                onBack: { viewModel.requestLeave() },
                onFinish: { viewModel.requestLeave() }
            )

            // Title and muscles
            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text(step.name)
                    .font(.system(size: AppSizes.Text.title * unit * 1.1, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(step.muscles)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit))
                    .foregroundStyle(AppColors.textSecondary)
            }

            // The photo takes all the free space left by the other blocks
            ExercisePhotoView(paths: step.imagePaths, unit: unit,
                              onHowTo: { viewModel.isInfoOpen = true })
                .id(step.id)

            if step.isTimed {
                timedBlock(unit: unit)
            } else {
                exerciseBlock(step, unit: unit)
            }

            WorkoutBigButton(
                title: step.isTimed ? "Done · \(viewModel.nextTitle)" : viewModel.nextTitle,
                style: step.isTimed || viewModel.allSetsDone ? .yellow : .black,
                unit: unit,
                action: { viewModel.nextStep() }
            )
        }
        .padding(.horizontal, 5 * unit)
        .padding(.top, AppSizes.Space.section * unit)
        .padding(.bottom, AppSizes.Space.section * unit)
    }

    // The blocks of an exercise: chips, then the card that fits the moment
    @ViewBuilder
    private func exerciseBlock(_ step: WorkoutStep, unit: CGFloat) -> some View {
        SetChipsView(
            sets: viewModel.currentSets,
            activeIndex: viewModel.activeSetIndex,
            unit: unit,
            onSelect: { viewModel.selectSet($0) }
        )

        if viewModel.isEditingDoneSet {
            // A done set is being changed (the rest keeps running in the small bar)
            SetEditorCardView(
                reps: viewModel.activeSet.reps, weight: viewModel.activeSet.weight,
                isEditing: true, unit: unit,
                onReps: { viewModel.changeReps(by: $0) },
                onWeight: { viewModel.changeWeight(by: $0) },
                onMainButton: { viewModel.saveEdit() }
            )
            if viewModel.isResting {
                RestBarView(remaining: viewModel.restRemaining, total: viewModel.restTotal,
                            unit: unit, onSkip: { viewModel.skipRest() })
            }
        } else if viewModel.isResting {
            RestCardView(
                remaining: viewModel.restRemaining, total: viewModel.restTotal, unit: unit,
                nextSetNumber: viewModel.activeSetIndex + 1,
                onAdd: { viewModel.addRest() }, onSkip: { viewModel.skipRest() }
            )
        } else if viewModel.allSetsDone {
            SetsDoneCardView(setCount: viewModel.currentSets.count,
                             heaviest: viewModel.heaviestDone, unit: unit)
        } else {
            SetEditorCardView(
                reps: viewModel.activeSet.reps, weight: viewModel.activeSet.weight,
                isEditing: false, unit: unit,
                onReps: { viewModel.changeReps(by: $0) },
                onWeight: { viewModel.changeWeight(by: $0) },
                onMainButton: { viewModel.completeSet() }
            )
        }
    }

    // The block of a warm-up or cool-down step
    private func timedBlock(unit: CGFloat) -> some View {
        TimedStepCardView(
            remaining: viewModel.timedRemaining,
            total: viewModel.currentStep?.durationSeconds ?? 0,
            unit: unit
        )
    }
}

#Preview("Light") {
    WorkoutView(viewModel: WorkoutPreviewData.viewModel(onStep: 1), onClose: {})
        .modelContainer(for: [Exercise.self, SessionRecord.self], inMemory: true)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    WorkoutView(viewModel: WorkoutPreviewData.viewModel(onStep: 1), onClose: {})
        .modelContainer(for: [Exercise.self, SessionRecord.self], inMemory: true)
        .preferredColorScheme(.dark)
}

#Preview("Warm-up") {
    WorkoutView(viewModel: WorkoutPreviewData.viewModel(onStep: 0), onClose: {})
        .modelContainer(for: [Exercise.self, SessionRecord.self], inMemory: true)
}
