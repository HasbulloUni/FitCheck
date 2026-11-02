//
//  ExerciseImporter.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import Foundation
import SwiftData

// MARK: - One exercise as written in exercises.json
// Only to read the file: some values can be null, so they are optional here.
private struct ExerciseRecord: Decodable {
    let id: String
    let name: String
    let category: String
    let level: String
    let mechanic: String?
    let force: String?
    let equipment: String?
    let primaryMuscles: [String]
    let secondaryMuscles: [String]
    let instructions: [String]
    let images: [String]
}

// MARK: - Fills the database with the exercises
enum ExerciseImporter {

    // Reads exercises.json and saves the exercises. It does nothing if they are already saved,
    // so it is safe to call at every launch.
    static func importIfNeeded(into context: ModelContext) {
        let saved = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        if saved > 0 { return }

        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([ExerciseRecord].self, from: data) else {
            print("ExerciseImporter: exercises.json not found or not readable")
            return
        }

        for record in records {
            context.insert(Exercise(
                id: record.id,
                name: record.name,
                category: record.category,
                level: record.level,
                mechanic: record.mechanic ?? "",
                force: record.force ?? "",
                equipment: record.equipment ?? "",
                primaryMuscles: record.primaryMuscles,
                secondaryMuscles: record.secondaryMuscles,
                instructions: record.instructions,
                images: record.images
            ))
        }

        try? context.save()
    }
}
