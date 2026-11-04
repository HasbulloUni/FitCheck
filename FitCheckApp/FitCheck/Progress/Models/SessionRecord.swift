//
//  SessionRecord.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation
import SwiftData

// MARK: - A completed workout saved with SwiftData
// The Progress screen reads these rows. The workout screen will create one when a workout ends.
// Only plain data, with parallel arrays (the same position in two arrays belongs together),
// like PlanRecord does. The name and the color of the plan are copied here, so deleting a plan
// keeps its history.
@Model
final class SessionRecord {
    @Attribute(.unique) var id: UUID
    var date: Date                 // when the workout was completed
    var planId: String             // id of the plan (text of the UUID)
    var planName: String           // e.g. "Full body A"
    var colorIndex: Int            // position in PlanPalette.colors
    var minutes: Int               // how long the workout lasted

    // Sets done for each muscle group: muscleNames[0] goes with muscleSets[0]
    var muscleNames: [String]      // MuscleGroup raw values, e.g. "chest"
    var muscleSets: [Int]

    // Heaviest weight used for each exercise with weight (kg): the three arrays go together
    var loadExerciseIds: [String]
    var loadExerciseNames: [String]
    var loadWeights: [Double]

    init(
        date: Date,
        planId: String,
        planName: String,
        colorIndex: Int,
        minutes: Int,
        muscleNames: [String] = [],
        muscleSets: [Int] = [],
        loadExerciseIds: [String] = [],
        loadExerciseNames: [String] = [],
        loadWeights: [Double] = []
    ) {
        self.id = UUID()
        self.date = date
        self.planId = planId
        self.planName = planName
        self.colorIndex = colorIndex
        self.minutes = minutes
        self.muscleNames = muscleNames
        self.muscleSets = muscleSets
        self.loadExerciseIds = loadExerciseIds
        self.loadExerciseNames = loadExerciseNames
        self.loadWeights = loadWeights
    }
}
