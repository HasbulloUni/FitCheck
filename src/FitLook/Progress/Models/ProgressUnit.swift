//
//  ProgressUnit.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - The units of the period selector
// Only data, no logic. Week, month, 3 months and year use the wheel; custom uses the calendar.
enum ProgressUnit: String, CaseIterable, Identifiable {
    case week
    case month
    case quarter
    case year
    case custom

    var id: String { rawValue }

    // Text of the button in the sheet
    var title: String {
        switch self {
        case .week:    return "Week"
        case .month:   return "Month"
        case .quarter: return "3 months"
        case .year:    return "Year"
        case .custom:  return "Custom"
        }
    }

    // Small hint above the wheel or the calendar
    var hint: String {
        switch self {
        case .week:    return "Swipe to choose a week"
        case .month:   return "Swipe to choose a month"
        case .quarter: return "Swipe to choose 3 months"
        case .year:    return "Swipe to choose a year"
        case .custom:  return "Tap the first day, then the last day"
        }
    }

    // Used in the title "Vs previous week"
    var previousWord: String {
        switch self {
        case .week:    return "week"
        case .month:   return "month"
        case .quarter: return "3 months"
        case .year:    return "year"
        case .custom:  return "period"
        }
    }

    // Used in the detail "24% more than last week"
    var lastWord: String {
        switch self {
        case .week:    return "last week"
        case .month:   return "last month"
        case .quarter: return "the 3 months before"
        case .year:    return "last year"
        case .custom:  return "the days before"
        }
    }
}
