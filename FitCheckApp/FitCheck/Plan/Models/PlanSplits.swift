//
//  PlanSplits.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - How the muscles are shared between the training days
// Only data. A day is a list of muscles, each with a weight and the kind of its exercises.
// Weights and kinds are our estimates (see coach/come-funziona-l-algoritmo.md).
enum PlanSplits {

    private static let c = MoveType.compound
    private static let i = MoveType.isolation

    // MARK: The muscles
    private static let quadriceps = MuscleSlot(group: "Legs", muscle: "quadriceps", weight: 2.0, types: [c, c, i])
    private static let hamstrings = MuscleSlot(group: "Legs", muscle: "hamstrings", weight: 1.5, types: [c, i, i])
    private static let glutes = MuscleSlot(group: "Glutes", muscle: nil, weight: 1.0, types: [c, i])
    private static let calves = MuscleSlot(group: "Legs", muscle: "calves", weight: 0.6, types: [i, i])
    private static let chest = MuscleSlot(group: "Chest", muscle: nil, weight: 2.0, types: [c, c, i, i])
    private static let back = MuscleSlot(group: "Back", muscle: nil, weight: 2.2, types: [c, c, c, i])
    private static let shoulders = MuscleSlot(group: "Shoulders", muscle: nil, weight: 1.5, types: [c, i, i])
    private static let biceps = MuscleSlot(group: "Arms", muscle: "biceps", weight: 0.9, types: [i, i])
    private static let triceps = MuscleSlot(group: "Arms", muscle: "triceps", weight: 0.8, types: [i, i])
    private static let core = MuscleSlot(group: "Core", muscle: nil, weight: 0.9, types: [i, i])

    // MARK: The days
    private static let fullBody = [quadriceps, hamstrings, glutes, chest, back, shoulders, biceps, triceps, core, calves]

    private static let push = [
        MuscleSlot(group: "Chest", muscle: nil, weight: 4.0, types: [c, c, i, i, i]),
        MuscleSlot(group: "Shoulders", muscle: nil, weight: 3.0, types: [c, i, i, i]),
        MuscleSlot(group: "Arms", muscle: "triceps", weight: 2.0, types: [i, i, i])
    ]
    private static let pull = [
        MuscleSlot(group: "Back", muscle: nil, weight: 4.0, types: [c, c, c, i, i]),
        MuscleSlot(group: "Arms", muscle: "biceps", weight: 2.0, types: [i, i, i]),
        MuscleSlot(group: "Shoulders", muscle: "shoulders", weight: 1.0, types: [i, i]),
        core
    ]
    private static let legs = [
        MuscleSlot(group: "Legs", muscle: "quadriceps", weight: 3.0, types: [c, c, i, i]),
        MuscleSlot(group: "Legs", muscle: "hamstrings", weight: 2.5, types: [c, i, i]),
        MuscleSlot(group: "Glutes", muscle: nil, weight: 1.5, types: [c, i, i]),
        MuscleSlot(group: "Legs", muscle: "calves", weight: 1.0, types: [i, i]),
        core
    ]
    private static let upper = [chest, back, shoulders, biceps, triceps]
    private static let chestTriceps = [
        MuscleSlot(group: "Chest", muscle: nil, weight: 4.0, types: [c, c, i, c, i, i]),
        MuscleSlot(group: "Arms", muscle: "triceps", weight: 2.0, types: [i, i, i, i])
    ]
    private static let backBiceps = [
        MuscleSlot(group: "Back", muscle: nil, weight: 4.0, types: [c, c, c, i, i, i]),
        MuscleSlot(group: "Arms", muscle: "biceps", weight: 2.0, types: [i, i, i, i])
    ]
    private static let shouldersCore = [
        MuscleSlot(group: "Shoulders", muscle: nil, weight: 3.0, types: [c, i, i, c, i]),
        core,
        MuscleSlot(group: "Back", muscle: "traps", weight: 1.0, types: [c, i])
    ]
    private static let armsOnly = [
        MuscleSlot(group: "Arms", muscle: "biceps", weight: 2.0, types: [i, i, i, i]),
        MuscleSlot(group: "Arms", muscle: "triceps", weight: 2.0, types: [i, i, i, i]),
        MuscleSlot(group: "Arms", muscle: "forearms", weight: 0.7, types: [i, i]),
        core
    ]

    // MARK: The splits for each number of days
    // The first style of the list is the default one.
    static func options(forDays days: Int) -> [SplitOption] {
        switch max(2, min(5, days)) {
        case 2:
            return [
                SplitOption(style: .fullBody, days: [
                    SplitDay(label: "Full body A", slots: fullBody),
                    SplitDay(label: "Full body B", slots: fullBody)
                ]),
                SplitOption(style: .upperLower, days: [
                    SplitDay(label: "Upper", slots: upper),
                    SplitDay(label: "Lower", slots: legs)
                ])
            ]
        case 3:
            return [
                SplitOption(style: .fullBody, days: [
                    SplitDay(label: "Full body A", slots: fullBody),
                    SplitDay(label: "Full body B", slots: fullBody),
                    SplitDay(label: "Full body C", slots: fullBody)
                ]),
                SplitOption(style: .pushPullLegs, days: [
                    SplitDay(label: "Push", slots: push),
                    SplitDay(label: "Pull", slots: pull),
                    SplitDay(label: "Legs", slots: legs)
                ])
            ]
        case 4:
            return [
                SplitOption(style: .upperLower, days: [
                    SplitDay(label: "Upper A", slots: upper),
                    SplitDay(label: "Lower A", slots: legs),
                    SplitDay(label: "Upper B", slots: upper),
                    SplitDay(label: "Lower B", slots: legs)
                ]),
                SplitOption(style: .bodyPart, days: [
                    SplitDay(label: "Chest + triceps", slots: chestTriceps),
                    SplitDay(label: "Back + biceps", slots: backBiceps),
                    SplitDay(label: "Legs", slots: legs),
                    SplitDay(label: "Shoulders + core", slots: shouldersCore)
                ])
            ]
        default:
            return [
                SplitOption(style: .pushPullLegsUpperLower, days: [
                    SplitDay(label: "Push", slots: push),
                    SplitDay(label: "Pull", slots: pull),
                    SplitDay(label: "Legs", slots: legs),
                    SplitDay(label: "Upper", slots: upper),
                    SplitDay(label: "Lower", slots: legs)
                ]),
                SplitOption(style: .bodyPart, days: [
                    SplitDay(label: "Chest", slots: chestTriceps),
                    SplitDay(label: "Back", slots: backBiceps),
                    SplitDay(label: "Legs", slots: legs),
                    SplitDay(label: "Shoulders + core", slots: shouldersCore),
                    SplitDay(label: "Arms", slots: armsOnly)
                ])
            ]
        }
    }
}
