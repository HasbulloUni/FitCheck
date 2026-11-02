//
//  GoalItem.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// MARK: - The data of one goal
// Only data, no logic. Later it will come from the goals chosen by the user.
struct GoalItem: Identifiable {
    let id = UUID()
    let title: String       // e.g. "Minutes"
    let centerText: String  // text inside the ring, e.g. "85" or "1/3"
    let subtitle: String    // e.g. "95 min left"
    let progress: Double    // from 0 (nothing done) to 1 (goal reached)
    let color: Color        // color of the ring
}
