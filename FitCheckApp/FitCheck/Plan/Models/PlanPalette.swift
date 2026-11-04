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
    // The 6 main colors of the app, the rainbow: red, orange, yellow, green, blue, purple.
    // The green is the "done / selected" green of the app (not the dark green of the labels).
    static let colors: [Color] = [
        AppColors.muscleRed,
        AppColors.muscleOrange,
        AppColors.muscleYellow,
        AppColors.greenSoft,
        AppColors.muscleBlue,
        AppColors.musclePurple
    ]

    // The first color that no plan is using (or the first one if all are taken)
    static func firstFree(taken: [Int]) -> Int {
        for index in colors.indices where !taken.contains(index) {
            return index
        }
        return 0
    }
}
