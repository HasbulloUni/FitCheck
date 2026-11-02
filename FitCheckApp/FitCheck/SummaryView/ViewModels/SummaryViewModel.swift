//
//  SummaryViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// The ViewModel of the Home: it owns the data and the logic, the View only draws.
// Every list starts empty, as the screen did before.
@Observable
final class SummaryViewModel {
    // Week data: starts empty, it only knows the current day
    var weekData = WeekData()

    // The name of the user: empty until the user sets it
    var userName = ""

    // Today's workout: nil means the user has not added one yet
    var todayPlan: TodayPlan? = nil

    // Goals chosen by the user: empty at the start
    var goals: [GoalItem] = []

    // Plans created by the user: empty at the start
    var plans: [PlanItem] = []

    // The 7 days shown in the week card
    var weekDays: [WeekDay] { weekData.days() }

    // Workouts done / planned this week, shown in the header
    var doneThisWeek: Int { weekDays.filter { $0.state == .done }.count }
    var plannedThisWeek: Int { weekData.plannedWeekdays.count }
}
