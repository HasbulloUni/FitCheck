//
//  GoalProgressBuilder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import Foundation

// MARK: - Builds the goal progress from the saved sessions
// A small pure service: same input, same output. No SwiftData, no View.
enum GoalProgressBuilder {

    // ONE place to decide how the plan completion counts the planned days:
    // true  = from the 1st of the month up to today (included)
    // false = the whole month: the plan completion is the MONTHLY plan (all planned days)
    private static let countPlannedUpToToday = false

    // THE rule that decides if a day counts in the targets (Sessions, Minutes,
    // Week active, Plan completion). A day counts when:
    // - it is a planned day by the history rule (days before a week change keep the old days), OR
    // - at least one completed session was done on that day (what was done today always counts).
    // "completedDays" holds the days (at midnight) with a completed session.
    static func countsAsTrainingDay(_ date: Date, weekData: WeekData, completedDays: Set<Date>) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        if weekData.plannedWeekdays(on: date).contains(weekday) { return true }
        return completedDays.contains(calendar.startOfDay(for: date))
    }

    // Minutes target of a day that counts: the minutes of its plan, otherwise
    // - a planned day without a plan: the default minutes
    // - a day that counts only because of a session: the real minutes of that day's sessions
    private static func minutesTarget(
        of day: Date,
        weekData: WeekData,
        planId: UUID?,
        plans: [PlanItem],
        completedSessions: [SessionRecord]
    ) -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: day)
        if let plan = plans.first(where: { $0.id == planId }) { return plan.minutes }

        if weekData.plannedWeekdays(on: day).contains(weekday) {
            return GoalRules.defaultMinutesPerSession
        }
        // Not planned, counted because of a session
        let start = calendar.startOfDay(for: day)
        return completedSessions
            .filter { calendar.startOfDay(for: $0.date) == start }
            .reduce(0) { $0 + $1.minutes }
    }

    static func build(
        sessions: [SessionRecord],
        weekData: WeekData,
        rotation: [RotationSlot],
        history: [CompletedWorkout],
        plans: [PlanItem],
        now: Date
    ) -> GoalProgress {
        var calendar = Calendar.current
        calendar.firstWeekday = 2   // weeks start on Monday

        var progress = GoalProgress()

        // The days (at midnight) with a completed session, used by countsAsTrainingDay
        let completedSessions = sessions.filter { $0.isCompleted }
        let completedDays = Set(completedSessions.map { calendar.startOfDay(for: $0.date) })

        // MARK: This week
        if let week = calendar.dateInterval(of: .weekOfYear, for: now) {
            let weekSessions = sessions.filter { week.contains($0.date) }

            // Sessions: only the completed ones
            progress.sessionsDone = weekSessions.filter { $0.isCompleted }.count

            // Minutes: all saved sessions, also the interrupted ones
            progress.minutesDone = weekSessions.reduce(0) { $0 + $1.minutes }

            // Strength days: different days with at least one COMPLETED session with main exercises done.
            // The target is always the same number (GoalRules), so "done" is capped at the target
            // (3 days done still shows 2/2)
            let strengthDays = weekSessions
                .filter { $0.isCompleted && !$0.muscleNames.isEmpty }
                .map { calendar.startOfDay(for: $0.date) }
            progress.strengthDaysTarget = GoalRules.strengthDaysPerWeek
            progress.strengthDaysDone = min(Set(strengthDays).count, progress.strengthDaysTarget)

            // Targets: each day of the week uses the rule that was valid on that day
            var plannedDays = 0
            var plannedMinutes = 0

            // The plans of today and of the next training days come from the rotation cycle (RotationCycle):
            // today = the plan due before today; the next days continue the order after the workouts
            // of today. The days already passed keep the plan of their weekday.
            let todayStart = calendar.startOfDay(for: now)
            let order = RotationCycle.order(from: rotation)
            let dueBeforeToday = RotationCycle.dueIndex(order: order, history: history, before: todayStart)
            let dueAfterToday = RotationCycle.dueIndex(
                order: order, history: history,
                before: calendar.date(byAdding: .day, value: 1, to: todayStart) ?? todayStart
            )
            let todayWeekday = calendar.component(.weekday, from: todayStart)
            let todayIsTrainingDay = weekData.plannedWeekdays(on: todayStart).contains(todayWeekday)
            let todayDone = completedDays.contains(todayStart)
            // A training day not trained yet uses the plan due today, so the next one is one step further
            var futureSteps = (todayIsTrainingDay && !todayDone) ? 1 : 0

            var day = week.start
            while day < week.end {
                if countsAsTrainingDay(day, weekData: weekData, completedDays: completedDays) {
                    plannedDays += 1
                    let weekday = calendar.component(.weekday, from: day)
                    var dayPlanId = rotation.first(where: { $0.weekday == weekday })?.planId
                    if day == todayStart, let dueBeforeToday {
                        dayPlanId = order[dueBeforeToday]
                    } else if day > todayStart, let dueAfterToday,
                              weekData.plannedWeekdays(on: day).contains(weekday) {
                        dayPlanId = order[(dueAfterToday + futureSteps) % order.count]
                        futureSteps += 1
                    }
                    plannedMinutes += minutesTarget(
                        of: day, weekData: weekData, planId: dayPlanId,
                        plans: plans, completedSessions: completedSessions
                    )
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            progress.sessionsTarget = plannedDays
            progress.minutesTarget = plannedMinutes
        }

        // MARK: This month
        guard let month = calendar.dateInterval(of: .month, for: now) else { return progress }
        let monthSessions = sessions.filter { month.contains($0.date) }
        let completedThisMonth = monthSessions.filter { $0.isCompleted }

        // Week active: weeks of the month with at least one completed session
        let activeWeeks = completedThisMonth.compactMap {
            calendar.dateInterval(of: .weekOfYear, for: $0.date)?.start
        }
        // Target: weeks of the month with at least one planned day (history rule of each day)
        var plannedWeeks: Set<Date> = []
        var weekDay = month.start
        while weekDay < month.end {
            if countsAsTrainingDay(weekDay, weekData: weekData, completedDays: completedDays),
               let weekStart = calendar.dateInterval(of: .weekOfYear, for: weekDay)?.start {
                plannedWeeks.insert(weekStart)
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: weekDay) else { break }
            weekDay = next
        }
        progress.weeksActiveTarget = plannedWeeks.count
        progress.weeksActive = min(Set(activeWeeks).count, plannedWeeks.count)

        // Plan completion: the end of the counted period (today, or the end of the month)
        let periodEnd = countPlannedUpToToday ? now : month.end
        progress.planWorkoutsDone = completedThisMonth.filter { $0.date <= periodEnd }.count

        var planned = 0
        var day = month.start
        while day <= periodEnd && day < month.end {
            // Same rule as the week targets: planned day (history rule) or a day with a session
            if countsAsTrainingDay(day, weekData: weekData, completedDays: completedDays) {
                planned += 1
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        progress.planWorkoutsPlanned = planned

        // Muscle coverage: different muscle groups trained this month (max 6)
        var groups: [MuscleGroup] = []
        for session in monthSessions {
            for name in session.muscleNames {
                if let group = MuscleGroup(rawValue: name), !groups.contains(group) {
                    groups.append(group)
                }
            }
        }
        progress.musclesCovered = min(groups.count, GoalRules.muscleGroups)

        return progress
    }
}
