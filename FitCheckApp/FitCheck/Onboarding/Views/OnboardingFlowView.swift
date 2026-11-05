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

    var body: some View {
        // The only GeometryReader of the flow: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: 0) {
                if let position = viewModel.step.barPosition {
                    OnboardingHeaderView(position: position, unit: unit, onBack: { viewModel.goBack() })
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
            .animation(.easeInOut(duration: 0.2), value: viewModel.step)
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
            WelcomeStepView(name: $viewModel.name, unit: unit, onSkip: { viewModel.skipName() })
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

    private func tapContinue() {
        if viewModel.step == .yourPlan {
            OnboardingSaver.save(
                name: viewModel.trimmedName,
                draft: viewModel.week.draft,
                plans: viewModel.plans,
                context: modelContext
            )
            onFinish()
        } else {
            viewModel.goNext()
        }
    }

    // MARK: - Custom plan creator

    // AddPlanView is the same screen of "New plan"; .id restarts it for each day.
    // In the onboarding its top shows the progress bar (step 3 of 4) and the Ready-made | Custom switch.
    private var customCreator: some View {
        AddPlanView(
            editing: nil,
            takenColorIndexes: viewModel.takenColorIndexes,
            otherPlanNames: viewModel.otherPlanNames,
            onboardingStep: OnboardingStep.choice.rawValue,
            onboardingDayText: viewModel.customProgressText,
            onReadyMade: { viewModel.backToReadyMade() },
            fallbackName: viewModel.customDayName,
            finalButtonTitle: viewModel.customButtonTitle,
            onBack: { viewModel.cancelCustom() },
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
