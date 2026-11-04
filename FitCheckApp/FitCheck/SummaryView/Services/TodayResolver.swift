//
//  TodayResolver.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// What the Home shows in the "Today" card
enum TodayOutcome {
    case workout(PlanItem, fromGo: Bool)   // a plan to do today (fromGo: it replaced the rotation)
    case rest                              // today is a rest day of the routine
    case noPlan                            // nothing to show yet: no routine or no plan chosen
}

// Decides what today is, in this order:
//  1. a plan sent with "Go" today replaces everything else (even a rest day)
//  2. a training day of Edit week: the plan of that day in the rotation
//  3. any other day of a routine that exists: rest day
// After a "Go" the rotation is adjusted: the plan sent with Go counts as done on that day, so when
// it comes again later in the same week it is not repeated: that day takes the plan that Go replaced.
// Only logic, no drawing: it is a pure function, so it is easy to check by hand.
enum TodayResolver {

    // Monday = 0 ... Sunday = 6 (the Apple calendar has Sunday = 1 and Monday = 2)
    private static func mondayFirstPosition(_ weekday: Int) -> Int {
        (weekday + 5) % 7
    }

    // True when both dates are in the same week (weeks start on Monday)
    private static func isSameWeek(_ first: Date, _ second: Date) -> Bool {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar.dateInterval(of: .weekOfYear, for: first)?.contains(second) ?? false
    }

    // The plan the rotation gives to a training day, after the adjustment made by a "Go" of this week.
    // nil = the day has no plan.
    static func rotationPlanId(
        on date: Date,
        rotation: [RotationSlot],
        goPlanId: UUID?,
        goDate: Date?
    ) -> UUID? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let basePlanId = rotation.first(where: { $0.weekday == weekday })?.planId

        // The adjustment needs a "Go" sent on an earlier day of the same week
        guard let goPlanId, let goDate,
              goDate < calendar.startOfDay(for: date),
              isSameWeek(goDate, date) else { return basePlanId }

        // The plan that Go replaced (nil if that day had no plan or was a rest day: nothing to move)
        let goWeekday = calendar.component(.weekday, from: goDate)
        guard let replacedPlanId = rotation.first(where: { $0.weekday == goWeekday })?.planId,
              replacedPlanId != goPlanId else { return basePlanId }

        // The first training day after the Go day that would repeat the plan done with Go
        let goPosition = mondayFirstPosition(goWeekday)
        let repeatDay = rotation
            .filter { $0.planId == goPlanId && mondayFirstPosition($0.weekday) > goPosition }
            .min { mondayFirstPosition($0.weekday) < mondayFirstPosition($1.weekday) }

        if let repeatDay, repeatDay.weekday == weekday { return replacedPlanId }
        return basePlanId
    }

    static func resolve(
        today: Date,
        trainingWeekdays: [Int],       // the days chosen in Edit week (1 = Sunday ... 7 = Saturday)
        rotation: [RotationSlot],      // the plan of each training day
        plans: [PlanItem],
        goPlanId: UUID?,
        goDate: Date?
    ) -> TodayOutcome {
        let calendar = Calendar.current

        // 1. "Go" is valid only on the day it was pressed
        if let goPlanId, let goDate, calendar.isDate(goDate, inSameDayAs: today),
           let plan = plans.first(where: { $0.id == goPlanId }) {
            return .workout(plan, fromGo: true)
        }

        // 2. A training day: the plan of the rotation for this day
        let weekday = calendar.component(.weekday, from: today)
        if trainingWeekdays.contains(weekday) {
            let planId = rotationPlanId(on: today, rotation: rotation, goPlanId: goPlanId, goDate: goDate)
            if let planId, let plan = plans.first(where: { $0.id == planId }) {
                return .workout(plan, fromGo: false)
            }
            return .noPlan
        }

        // 3. The user has a routine and today is not part of it
        return trainingWeekdays.isEmpty ? .noPlan : .rest
    }
}
