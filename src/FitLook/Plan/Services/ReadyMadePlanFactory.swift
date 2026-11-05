//
//  ReadyMadePlanFactory.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// Turns the plans of a ready-made program into PlanItem, the same type the Home saves.
// Each plan gets its own color: the first free one of PlanPalette (when the 6 are taken they start again).
enum ReadyMadePlanFactory {

    static func makePlans(from program: ReadyMadeProgram, takenColorIndexes: [Int]) -> [PlanItem] {
        var taken = takenColorIndexes
        var result: [PlanItem] = []

        for plan in program.plans {
            // All 6 taken: the colors can be used again
            if taken.count >= PlanPalette.colors.count {
                taken = []
            }
            let colorIndex = PlanPalette.firstFree(taken: taken)
            taken.append(colorIndex)

            result.append(
                PlanItem(
                    id: UUID(),
                    name: plan.name,
                    icon: plan.icon,
                    color: PlanPalette.colors[colorIndex],
                    exerciseCount: plan.exercises.count,
                    minutes: plan.minutes,
                    exerciseIds: plan.exercises.map { $0.id },
                    colorIndex: colorIndex,
                    exerciseSets: plan.exercises.map { $0.sets },
                    warmupMoves: plan.warmup,
                    hasCooldown: true,
                    hasWarmup: true
                )
            )
        }
        return result
    }
}
