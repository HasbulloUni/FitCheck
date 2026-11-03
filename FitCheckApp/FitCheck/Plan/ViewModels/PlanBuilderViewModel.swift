//
//  PlanBuilderViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of "New plan": it owns the choices of the user and creates the plan.
// The View only draws.
@Observable
final class PlanBuilderViewModel {

    // MARK: The choices of the user
    var category: PlanCategory = .gym
    var goal: PlanGoal = .tone
    var level: PlanLevel = .easy
    var daysPerWeek = 3
    var minutes = 60
    var style: SplitStyle = .fullBody

    // The training days picked in "Edit your week" (1 = Sunday ... 7 = Saturday).
    // Empty = unknown: the plan is built as if the days were far from each other.
    var weekdays: [Int] = []

    // MARK: The plan that was created
    var editor: PlanEditorViewModel? = nil
    var isEditorShown = false

    // The exercises copied from the database. It is built once.
    private var catalog: ExerciseCatalog? = nil

    // MARK: The options shown on the screen
    var minutesOptions: [Int] { SafetyRules.sessionMinutesOptions }
    var daysOptions: [Int] { SafetyRules.daysOptions }

    // The styles that exist for the number of days picked
    var availableStyles: [SplitStyle] {
        PlanSplits.options(forDays: daysPerWeek).map { $0.style }
    }

    // True when the exercises of the database are ready
    var isCatalogReady: Bool { catalog != nil }

    // MARK: Actions

    // Called with the exercises saved in the database. It does nothing if they are already loaded
    // or if the database is still empty.
    func loadCatalog(from exercises: [Exercise]) {
        if catalog != nil || exercises.isEmpty { return }
        catalog = CatalogBuilder.build(from: exercises)
    }

    // When the number of days changes, the style must still be one of the available ones
    func keepStyleValid() {
        if !availableStyles.contains(style), let first = availableStyles.first {
            style = first
        }
    }

    // Builds the plan and opens the screen where the user can look at it and change it
    func createPlan() {
        guard let catalog = catalog else { return }
        let week = WeeklyPlanGenerator.generate(
            catalog: catalog,
            category: category,
            goal: goal,
            level: level,
            days: daysPerWeek,
            minutes: minutes,
            preferredStyle: style,
            weekdays: weekdays
        )
        editor = PlanEditorViewModel(
            week: week, catalog: catalog, category: category, goal: goal, level: level, minutes: minutes
        )
        isEditorShown = true
    }
}
