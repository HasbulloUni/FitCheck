//
//  PlanItem.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// MARK: - The data of one plan
// Only data, no logic. Later it will come from the plans created by the user.
// Each plan has its own color, chosen by the user when the plan is created.
struct PlanItem: Identifiable {
    let id = UUID()
    let letter: String    // e.g. "A"
    let name: String      // e.g. "Full body A"
    let details: String   // e.g. "67 min · 11 exercises"
    let color: Color      // the color of this plan
}
