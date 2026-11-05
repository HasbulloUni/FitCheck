//
//  OnboardingGateView.swift
//  FitCheck
//
//  Decides what the app opens: the onboarding the first time, then always the tabs.
//  An app that already has a saved week (installed before the onboarding) skips it.
//

import SwiftUI
import SwiftData

struct OnboardingGateView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompleted = false
    @Query private var profiles: [AppProfile]

    private var hasSavedWeek: Bool {
        profiles.first?.hasSavedWeekPlan ?? false
    }

    var body: some View {
        if hasCompleted || hasSavedWeek {
            RootTabView()
        } else {
            OnboardingFlowView(onFinish: { hasCompleted = true })
        }
    }
}

#Preview("First launch") {
    OnboardingGateView()
        .modelContainer(rootPreviewContainer(withData: false))
}
