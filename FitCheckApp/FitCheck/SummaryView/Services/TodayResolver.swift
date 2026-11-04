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
// Only logic, no drawing: it is a pure function, so it is easy to check by hand.
enum TodayResolver {
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
            let slot = rotation.first(where: { $0.weekday == weekday })
            if let planId = slot?.planId, let plan = plans.first(where: { $0.id == planId }) {
                return .workout(plan, fromGo: false)
            }
            return .noPlan
        }

        // 3. The user has a routine and today is not part of it
        return trainingWeekdays.isEmpty ? .noPlan : .rest
    }
}
