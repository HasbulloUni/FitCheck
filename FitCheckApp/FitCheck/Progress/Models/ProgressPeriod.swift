//
//  ProgressPeriod.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - One period of time
// Only data: ProgressPeriodBuilder creates it.
// All the dates are the start of a day. "end" is the last day counted: never after today.
struct ProgressPeriod: Equatable {
    let unit: ProgressUnit
    let start: Date          // first day
    let end: Date            // last day counted (today if the period is not finished)
    let naturalEnd: Date     // the day the period really ends (e.g. the last day of the month)
    let dayCount: Int        // days from start to end, both included

    // True while the period is not finished (e.g. the current month)
    var isInProgress: Bool {
        end < naturalEnd
    }
}
