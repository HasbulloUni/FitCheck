//
//  PlanPalette.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// MARK: - The colors a plan can have
// Only data. The user picks one when the plan is created.
// Two plans never share a color: the screen "Add your plan" blocks the colors already taken.
enum PlanPalette {
    static let colors: [Color] = [
        AppColors.muscleBlue,
        AppColors.musclePurple,
        AppColors.muscleOrange,
        AppColors.muscleGreen,
        AppColors.muscleYellow,
        AppColors.muscleRed
    ]

    // The first color that no plan is using (or the first one if all are taken)
    static func firstFree(taken: [Int]) -> Int {
        for index in colors.indices where !taken.contains(index) {
            return index
        }
        return 0
    }
}
