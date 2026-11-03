//
//  ChosenExercise.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - One exercise of a plan made by hand ("Add your plan")
// Only data: the exercise of the database and the sets chosen by the user.
// Repetitions, rest and effort are not saved here: they come from Prescription (goal and level).
struct ChosenExercise: Identifiable {
    let item: CatalogItem
    var sets: Int               // between SafetyRules.minSets and SafetyRules.maxSets

    var id: String { item.id }
}
