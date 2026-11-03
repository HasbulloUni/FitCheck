//
//  GoalsPeriod.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The two periods of the Goals screen
// Only data, no logic. Both are always visible: the week goals first, the month goals below.
enum GoalsPeriod: String {
    case week
    case month

    // Title of the section, e.g. "THIS WEEK"
    var title: String {
        switch self {
        case .week:  return "This week"
        case .month: return "This month"
        }
    }

    // Small text on the right of the title
    var resetText: String {
        switch self {
        case .week:  return "Resets Monday"
        case .month: return "Resets on the 1st"
        }
    }
}
