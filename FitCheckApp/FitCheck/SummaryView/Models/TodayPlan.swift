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
}
