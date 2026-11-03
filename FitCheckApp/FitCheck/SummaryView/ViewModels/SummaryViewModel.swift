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

    // The goals of the week and of the month: the Home shows them, the numbers start at zero
    var goalsViewModel = GoalsViewModel()

    // Plans created by the user: empty at the start
    var plans: [PlanItem] = []

    // True while the screen "Add your plan" is open
    var isAddPlanOpen = false

    func openAddPlan() {
        isAddPlanOpen = true
    }

    func closeAddPlan() {
        isAddPlanOpen = false
    }

    // Save plan: the new plan goes to My plans and the Home is shown again
    func addPlan(_ plan: PlanItem) {
        plans.append(plan)
        closeAddPlan()
    }

    // Delete a plan from My plans (the Home asks the user first)
    func deletePlan(_ plan: PlanItem) {
        plans.removeAll { $0.id == plan.id }
    }

    // What the user saved in "Edit your week" (days, duration, reminders): nil until the first save
    var savedWeekPlan: EditWeekDraft? = nil

    // True while the screen "Edit your week" is open
    var isEditWeekOpen = false

    // Which week the card shows: 0 = this week, 1 = next week... (the user swipes to change it)
    var weekOffset = 0

    // How many weeks ahead the user can swipe
    static let maxWeeksAhead = 8

    // The 7 days shown in the week card
    var weekDays: [WeekDay] { weekData.days(weekOffset: weekOffset) }

    // The title of the card
    var weekTitle: String {
        switch weekOffset {
        case 0:  return "This week"
        case 1:  return "Next week"
        default: return "In \(weekOffset) weeks"
        }
    }

    // Swipe to the next week
    func showNextWeek() {
        if weekOffset < Self.maxWeeksAhead {
            weekOffset += 1
        }
    }

    // Swipe back: never before this week, because the past cannot be trained
    func showPreviousWeek() {
        if weekOffset > 0 {
            weekOffset -= 1
        }
    }

    // Workouts done / planned this week, shown in the header
    var doneThisWeek: Int { weekData.days().filter { $0.state == .done }.count }
    var plannedThisWeek: Int { weekData.plannedWeekdays.count }

    // The pencil of the week card: opens "Edit your week"
    func openEditWeek() {
        isEditWeekOpen = true
    }

    // Save changes: the chosen days go to the week card, the rest is kept for the next time
    func saveWeek(_ draft: EditWeekDraft) {
        // Valid from today on: the days before today keep what they had
        weekData.changeWeek(plannedWeekdays: draft.workoutWeekdays)

        savedWeekPlan = draft

        // The reminders are updated in the background: the permission is asked now
        Task { await ReminderScheduler.updateReminders(for: draft) }

        closeEditWeek()
    }

    // Back (or Save): closes "Edit your week" and the Home is shown again
    func closeEditWeek() {
        isEditWeekOpen = false
    }
}
