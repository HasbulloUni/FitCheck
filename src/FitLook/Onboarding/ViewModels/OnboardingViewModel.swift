//
//  OnboardingViewModel.swift
//  FitCheck
//
//  The logic of the first launch: which screen is open, what the user chose,
//  and the plans that will be saved at the end. The views only show it.
//

import SwiftUI

@Observable
final class OnboardingViewModel {

    // MARK: - Where we are

    private(set) var step: OnboardingStep = .welcome

    // MARK: - What the user chooses

    var name = ""
    var level: ReadyMadeLevel = .beginner
    var choice: PlanChoice = .ready(.fullBody)

    // The week reuses the logic of Edit week (days 2 to 5, reminders): same rules, no copy
    let week = EditWeekViewModel(week: WeekData(), savedPlan: nil, plans: [])

    // The plans of the user, one for each training day (Ready-made or Custom)
    private(set) var plans: [PlanItem] = []

    // Custom only: the position (0, 1, 2...) of the day whose plan is being made now. nil = not building.
    private(set) var customIndex: Int? = nil

    // MARK: - Texts and checks

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Monday first
    var orderedWeekdays: [Int] {
        [2, 3, 4, 5, 6, 7, 1].filter { week.draft.workoutWeekdays.contains($0) }
    }

    var dayCount: Int { orderedWeekdays.count }

    var isCustom: Bool { choice == .custom }

    // Text of the big button of each screen
    var buttonTitle: String {
        switch step {
        case .welcome, .level, .week: return "Continue"
        case .choice:                 return "See my plan"
        case .yourPlan:               return "Set plan"
        }
    }

    // The big button works only when the screen has what it needs
    var canContinue: Bool {
        switch step {
        case .welcome, .level: return true
        case .week:            return week.canSave
        case .choice:          return dayCount >= EditWeekRules.minWorkoutDays
        case .yourPlan:        return !plans.isEmpty
        }
    }

    // MARK: - Moving between screens

    // Skip: the rest of the onboarding is skipped. The days the user already chose are kept;
    // without a valid choice the app starts with 3 days (Mon, Wed, Fri), Beginner and Full body.
    // Returns true when the plans are ready to be saved.
    func skipAll() -> Bool {
        if !week.canSave {
            for weekday in week.draft.workoutWeekdays { week.toggleDay(weekday) }
            for weekday in [2, 4, 6] { week.toggleDay(weekday) }
        }
        guard let program = ReadyMadeCatalog.program(level: level, style: .fullBody, days: dayCount)
                ?? ReadyMadeCatalog.program(level: .beginner, style: .fullBody, days: dayCount) else { return false }
        plans = ReadyMadePlanFactory.makePlans(from: program, takenColorIndexes: [])
        return true
    }

    func goNext() {
        switch step {
        case .welcome: step = .level
        case .level:   step = .week
        case .week:    step = .choice
        case .choice:  continueFromChoice()
        case .yourPlan: break    // the flow view saves and closes
        }
    }

    func goBack() {
        switch step {
        case .welcome: break
        case .level:   step = .welcome
        case .week:    step = .level
        case .choice:  step = .week
        case .yourPlan:
            plans = []
            step = .choice
        }
    }

    // MARK: - Choose a plan

    private func continueFromChoice() {
        switch choice {
        case .ready(let style):
            // Ready-made: the plans are made now, saved only at the end
            let program = ReadyMadeCatalog.program(level: level, style: style, days: dayCount)
                ?? ReadyMadeCatalog.program(level: .beginner, style: style, days: dayCount)
            guard let program else { return }
            plans = ReadyMadePlanFactory.makePlans(from: program, takenColorIndexes: [])
            step = .yourPlan
        case .custom:
            plans = []
            customIndex = 0
        }
    }

    // MARK: - Custom: one plan for each day

    var takenColorIndexes: [Int] { plans.compactMap { $0.colorIndex } }
    var otherPlanNames: [String] { plans.map { $0.name } }

    // The plan of the previous day, shown again when the user goes Back from Day 2 or 3 (nil = a new plan)
    private(set) var customEditing: PlanItem? = nil

    // "Day 1 of 3"
    var customProgressText: String {
        "Day \((customIndex ?? 0) + 1) of \(dayCount)"
    }

    // The name of the day when the user writes none: "Day 1", "Day 2"...
    var customDayName: String { "Day \((customIndex ?? 0) + 1)" }

    // The big button of the creator: "Next: Day 2", and "See my plan" on the last day
    var customButtonTitle: String {
        let next = (customIndex ?? 0) + 1
        return next >= dayCount ? "See my plan" : "Next: Day \(next + 1)"
    }

    func savedCustomPlan(_ plan: PlanItem) {
        customEditing = nil
        plans.append(plan)
        let next = plans.count
        if next >= dayCount {
            customIndex = nil
            step = .yourPlan
        } else {
            customIndex = next
        }
    }

    // Back from the plan creator: everything made so far is dropped, the user is on "Choose a plan" again
    func cancelCustom() {
        customEditing = nil
        customIndex = nil
        plans = []
        choice = .ready(.fullBody)
    }

    // The Back of the plan creator: on Day 2 or 3 it goes to the day before (its plan is shown again);
    // on Day 1 it goes back to "Choose a plan"
    func backFromCustom() {
        guard let index = customIndex, index > 0, let previous = plans.popLast() else {
            cancelCustom()
            return
        }
        customEditing = previous
        customIndex = index - 1
    }

    // Custom: the user tapped "Custom" on Choose a plan (needs the training days first)
    func startCustom() {
        guard dayCount >= EditWeekRules.minWorkoutDays else { return }
        choice = .custom
        plans = []
        customEditing = nil
        customIndex = 0
    }

    // MARK: - Your plan: the user edited one day

    func replacePlan(_ plan: PlanItem) {
        guard let position = plans.firstIndex(where: { $0.id == plan.id }) else { return }
        plans[position] = plan
    }
}
