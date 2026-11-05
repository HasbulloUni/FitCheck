//
//  WeekRotationProjector.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import Foundation

// Decides which plan each training day still to do will have in the week card.
// It uses the same rule as the Home (RotationCycle): the plan due is the first plan not done
// in the current cycle, and the next days follow the rotation.
// A plan sent with "Go" today counts as used (also if it is not completed yet), so it does not
// come back as "next" in the same round: Go on C => today C, then B, then A...
// Only logic, no drawing: a pure service.
enum WeekRotationProjector {

    // Returns the plan of every training day still to do, from today to `lastDay`.
    // The key is the day at midnight. Days already done and past days are not in the result.
    static func projectedPlans(
        order: [UUID],                 // the plans of the rotation in order (RotationCycle.order)
        history: [CompletedWorkout],   // the completed workouts of the current rotation
        weekData: WeekData,            // the training weekdays (the rule valid on each day)
        goPlanId: UUID?,               // the plan sent with Go today (nil = no Go)
        todayDone: Bool,               // a workout was already completed today
        today: Date,
        lastDay: Date
    ) -> [Date: UUID] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        var result: [Date: UUID] = [:]

        // The workouts that count: the real ones, plus the fake ones added while walking the days
        var workouts = history

        var day = todayStart
        while day <= calendar.startOfDay(for: lastDay) {
            let weekday = calendar.component(.weekday, from: day)
            let isToday = day == todayStart

            // The plan of this day, nil = nothing to show (not a training day, or already done)
            var planId: UUID? = nil
            if isToday {
                if !todayDone {
                    if let goPlanId {
                        planId = goPlanId   // Go replaces the rotation today
                    } else if weekData.plannedWeekdays(on: day).contains(weekday) {
                        // Only the workouts of earlier days count, like the Today card
                        planId = dueId(order: order, workouts: workouts, before: day)
                    }
                }
            } else if weekData.plannedWeekdays(on: day).contains(weekday) {
                planId = dueId(order: order, workouts: workouts, before: day)
            }

            if let planId {
                result[day] = planId
                // The plan is used: the days after it continue the rotation
                workouts.append(CompletedWorkout(planId: planId, date: day))
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    // The plan due on `day`, looking at the workouts before that day
    private static func dueId(order: [UUID], workouts: [CompletedWorkout], before day: Date) -> UUID? {
        guard let index = RotationCycle.dueIndex(order: order, history: workouts, before: day) else { return nil }
        return order[index]
    }
}
