//
//  WorkoutFormat.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - Texts of numbers for the workout screens
enum WorkoutFormat {

    // 62.5 -> "62.5", 60 -> "60"
    static func weight(_ kg: Double) -> String {
        kg.formatted(.number.precision(.fractionLength(0...1)))
    }

    // 45 -> "0:45", 125 -> "2:05"
    static func clock(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        return String(format: "%d:%02d", safe / 60, safe % 60)
    }
}
