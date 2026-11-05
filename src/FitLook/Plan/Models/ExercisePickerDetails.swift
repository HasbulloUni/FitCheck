//
//  ExercisePickerDetails.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - The extra data an exercise needs only in "Add exercises" (not in the generator)
// Only data. Built once from the database, next to CatalogItem.
struct ExercisePickerDetails {
    let images: [String]            // e.g. "Goblet_Squat/0.jpg", start and end of the movement
    let secondaryMuscles: [String]  // muscles also worked, besides the main one
    let instructions: [String]      // the steps, one text for each step
}
