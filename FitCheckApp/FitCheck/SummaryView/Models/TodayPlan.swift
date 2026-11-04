//
//  TodayPlan.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// MARK: - The data shown in the card
// Only data, no logic. Later it will come from the user's plans.
struct TodayPlan {
    let name: String          // e.g. "Full body A"
    let minutes: Int          // e.g. 67
    let exerciseCount: Int    // e.g. 11
    var planId: UUID? = nil   // the plan of My plans this card comes from
    var result: TodayResult? = nil   // the numbers of the workout done today (nil = not done yet)
    var fromGo = false        // true when the plan was sent with "Go" and replaced the routine
}

// MARK: - What was done today
// Only data: the Home builds it from the SessionRecord saved when the workout ends.
struct TodayResult {
    let minutes: Int
    let sets: Int
    let topWeight: Double?    // the heaviest weight used today (kg), nil if no exercise had weight
}
