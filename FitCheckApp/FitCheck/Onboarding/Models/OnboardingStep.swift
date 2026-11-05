//
//  OnboardingStep.swift
//  FitCheck
//
//  The screens of the first launch, in order.
//  Welcome has no progress bar, the other four are the 4 steps of the bar.
//

import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome
    case level
    case week
    case choice
    case yourPlan

    // How many steps the progress bar has (Welcome is not counted)
    static let barSteps = 4

    // 1...4 for the screens with the bar, nil for Welcome
    var barPosition: Int? {
        self == .welcome ? nil : rawValue
    }
}

// What the user picked on "Choose a plan"
enum PlanChoice: Equatable {
    case ready(ReadyMadeStyle)   // Ready-made: Full body or Muscle groups
    case custom                  // Custom: one plan for each training day, made by hand
}
