//
//  OnboardingFlowView.swift
//  FitCheck
//
//  The first launch: Welcome, Level, Your week, Choose a plan, Your plan.
//  It shows one screen at a time and the big button at the bottom.
//

import SwiftUI
import SwiftData

struct OnboardingFlowView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext

    let onFinish: () -> Void

    // True when the first save failed: the user can try again
    @State private var saveFailed = false
    @State private var isSaving = false   // a second tap on the big button is ignored

    var body: some View {
        // The only GeometryReader of the flow: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                if let position = viewModel.step.barPosition {
                    OnboardingHeaderView(position: position, unit: unit, onBack: { viewModel.goBack() },
                                         onSkip: { skip() })
                        .padding(.horizontal, AppSizes.Space.screen * unit)
                        .padding(.top, AppSizes.Space.section * unit)
                }

                ScrollView {
                    currentStep(unit: unit)
                        .padding(.horizontal, AppSizes.Space.screen * unit)
                        .padding(.top, AppSizes.Space.section * unit)
                        .padding(.bottom, AppSizes.Space.section * unit)
                }
                .scrollDismissesKeyboard(.interactively)

                bigButton(unit: unit)
            }
            .overlay(alignment: .topTrailing) {
                // Welcome has no header, so its Skip sits at the top right, in the centre of the rainbow
                if viewModel.step == .welcome {
                    Button(action: skip) {
                        // Visible in light and dark: card color behind, primary text color on top
                        Text("Skip")
                            .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: WelcomeStepView.skipWidth * unit,
                                   height: WelcomeStepView.skipHeight * unit)
                            .background(AppColors.card, in: Capsule())
                            .overlay(Capsule().stroke(AppColors.divider, lineWidth: 0.3 * unit))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, AppSizes.Space.screen * unit)
                    .padding(.top, AppSizes.Space.section * unit)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.step)
            .alert("Couldn't save your plan", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
        .background(AppColors.background)
        // Custom: the plan creator of the app, once for each training day
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.customIndex != nil },
            set: { if !$0 { viewModel.cancelCustom() } }
        )) {
            customCreator
        }
    }

    // MARK: - Screens

    @ViewBuilder
    private func currentStep(unit: CGFloat) -> some View {
        switch viewModel.step {
        case .welcome:
            WelcomeStepView(name: $viewModel.name, unit: unit)
        case .level:
            LevelStepView(level: $viewModel.level, unit: unit)
        case .week:
            WeekStepView(viewModel: viewModel.week, unit: unit)
        case .choice:
            PlanChoiceStepView(choice: $viewModel.choice, level: viewModel.level, dayCount: viewModel.dayCount,
                               unit: unit, onPickCustom: { viewModel.startCustom() })
        case .yourPlan:
            YourPlanStepView(weekdays: viewModel.orderedWeekdays, plans: viewModel.plans, level: viewModel.level,
                             unit: unit, onEdit: { viewModel.replacePlan($0) })
        }
    }

    // The big button, fixed at the bottom (same look as "Save changes" in Edit week)
    private func bigButton(unit: CGFloat) -> some View {
        Button(action: tapContinue) {
            Text(viewModel.buttonTitle)
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                .foregroundStyle(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4.5 * unit)
                .background(AppColors.textPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canContinue)
        .opacity(viewModel.canContinue ? 1 : 0.3)
        .padding(.horizontal, AppSizes.Space.screen * unit)
        .padding(.top, AppSizes.Space.group * unit)
        .padding(.bottom, AppSizes.Space.group * unit)
    }

    // Saves what is chosen and opens the app
    private func finishOnboarding() {
        guard !isSaving else { return }
        isSaving = true
        let saved = OnboardingSaver.save(
            name: viewModel.trimmedName,
            draft: viewModel.week.draft,
            plans: viewModel.plans,
            context: modelContext
        )
        if saved {
            onFinish()
        } else {
            isSaving = false
            saveFailed = true
        }
    }

    // Skip: the whole onboarding is skipped (default week and plan)
    private func skip() {
        viewModel.cancelCustom()   // closes the plan creator if it is open
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if viewModel.skipAll() { finishOnboarding() }
    }

    private func tapContinue() {
        if viewModel.step == .yourPlan {
            finishOnboarding()
        } else {
            viewModel.goNext()
        }
    }

    // MARK: - Custom plan creator

    // AddPlanView is the same screen of "New plan"; .id restarts it for each day.
    // In the onboarding its top shows the progress bar (step 3 of 4).
    private var customCreator: some View {
        AddPlanView(
            editing: viewModel.customEditing,
            takenColorIndexes: viewModel.takenColorIndexes,
            otherPlanNames: viewModel.otherPlanNames,
            onboardingStep: OnboardingStep.choice.rawValue,
            onboardingDayText: viewModel.customProgressText,
            fallbackName: viewModel.customDayName,
            finalButtonTitle: viewModel.customButtonTitle,
            onSkip: { skip() },
            onBack: { viewModel.backFromCustom() },
            onSave: { viewModel.savedCustomPlan($0) }
        )
        .id(viewModel.customIndex)
    }
}

#Preview("Light") {
    OnboardingFlowView(onFinish: {})
        .modelContainer(rootPreviewContainer(withData: false))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    OnboardingFlowView(onFinish: {})
        .modelContainer(rootPreviewContainer(withData: false))
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    OnboardingFlowView(onFinish: {})
        .modelContainer(rootPreviewContainer(withData: false))
}
