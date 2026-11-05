//
//  RotationCycle.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import Foundation

// A completed workout, reduced to what the rotation needs
struct CompletedWorkout {
    let planId: UUID
    let date: Date
}

// MARK: - Which plan is due next
// Nothing is saved for this: the answer comes from the completed workouts.
// A "cycle" is a round of the rotation where each plan is done once.
// - The plan that is due = the first plan of the rotation (in order) NOT done yet in the current cycle.
// - When all the plans are done, a new cycle starts and the first plan is due.
// - A plan done out of order does not move the pointer past the plans that were skipped:
//   A done, then C with "Go" => cycle {A, C}, so B is due.
// - Workouts of plans that are not in the rotation any more are ignored.
// Only logic, no drawing: a pure service.
enum RotationCycle {

    // The plans of the rotation in order (Monday first), each one once.
    // A day without a plan is skipped.
    static func order(from rotation: [RotationSlot]) -> [UUID] {
        var plans: [UUID] = []
        let sortedSlots = rotation.sorted { mondayFirst($0.weekday) < mondayFirst($1.weekday) }
        for slot in sortedSlots {
            if let planId = slot.planId, !plans.contains(planId) {
                plans.append(planId)
            }
        }
        return plans
    }

    // Monday = 0 ... Sunday = 6 (the Apple calendar has Sunday = 1)
    private static func mondayFirst(_ weekday: Int) -> Int {
        (weekday + 5) % 7
    }

    // The plans already done in the current cycle, looking only at the workouts before `date`.
    // The workouts are read from the oldest to the newest, so a cycle that was finished stays finished.
    static func plansDoneInCurrentCycle(order: [UUID], history: [CompletedWorkout], before date: Date) -> [UUID] {
        var done: [UUID] = []
        let ordered = history.filter { $0.date < date }.sorted { $0.date < $1.date }
        for workout in ordered where order.contains(workout.planId) {
            if done.contains(workout.planId) {
                done = []                       // the plan came again before the others: new cycle
            }
            done.append(workout.planId)
            if done.count == order.count {
                done = []                       // all the plans are done: the cycle starts again
            }
        }
        return done
    }

    // The position (in the order) of the plan that is due, looking at the workouts before `date`.
    // nil = the rotation has no plan.
    static func dueIndex(order: [UUID], history: [CompletedWorkout], before date: Date) -> Int? {
        guard !order.isEmpty else { return nil }
        let done = plansDoneInCurrentCycle(order: order, history: history, before: date)
        return order.firstIndex { !done.contains($0) } ?? 0
    }

    // The plan due at the moment `date` (the workouts before `date` count)
    static func duePlanId(rotation: [RotationSlot], history: [CompletedWorkout], before date: Date) -> UUID? {
        let plans = order(from: rotation)
        guard let index = dueIndex(order: plans, history: history, before: date) else { return nil }
        return plans[index]
    }
}
