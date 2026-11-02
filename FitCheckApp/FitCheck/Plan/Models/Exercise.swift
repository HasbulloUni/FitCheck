//
//  Exercise.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftData

// MARK: - One exercise of the database
// Saved with SwiftData. The data comes from exercises.json (Free Exercise DB).
// Missing values in the file become an empty text "" (or an empty array), so nothing is optional.
@Model
final class Exercise {
    // The id of the file, e.g. "3_4_Sit-Up". Unique: an exercise is never saved twice.
    @Attribute(.unique) var id: String

    var name: String            // e.g. "3/4 Sit-Up"
    var category: String        // "strength", "stretching", "cardio"...
    var level: String           // "beginner", "intermediate", "expert"
    var mechanic: String        // "compound", "isolation" or ""
    var force: String           // "push", "pull", "static" or ""
    var equipment: String       // "barbell", "body only"... or "" if none

    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var instructions: [String]  // the steps, one text for each step
    var images: [String]        // e.g. "3_4_Sit-Up/0.jpg"

    init(id: String, name: String, category: String, level: String,
         mechanic: String, force: String, equipment: String,
         primaryMuscles: [String], secondaryMuscles: [String],
         instructions: [String], images: [String]) {
        self.id = id
        self.name = name
        self.category = category
        self.level = level
        self.mechanic = mechanic
        self.force = force
        self.equipment = equipment
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.instructions = instructions
        self.images = images
    }
}
