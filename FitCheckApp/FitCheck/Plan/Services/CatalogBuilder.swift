//
//  CatalogBuilder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import Foundation

// MARK: - Builds the catalog the generator uses
// Takes the exercises saved in the database (Exercise) and returns plain copies.
// It also reads two small files of the team:
//  - esclusi_sicurezza.json: the ids of the exercises that are never used (not safe)
//  - calisthenics_aggiunti.json: the bodyweight exercises added by hand
enum CatalogBuilder {

    // The muscles of the database and the group each one belongs to
    private static let groupOfMuscle: [String: String] = [
        "chest": "Chest", "shoulders": "Shoulders", "neck": "Shoulders",
        "lats": "Back", "middle back": "Back", "lower back": "Back", "traps": "Back",
        "biceps": "Arms", "triceps": "Arms", "forearms": "Arms",
        "abdominals": "Core", "glutes": "Glutes",
        "quadriceps": "Legs", "hamstrings": "Legs", "calves": "Legs",
        "adductors": "Legs", "abductors": "Legs"
    ]

    // The equipment of the database and the name used by the generator.
    // An exercise with no equipment is a bodyweight one. Other equipment (balls, foam roll) is not used.
    private static let equipmentName: [String: String] = [
        "barbell": "Barbell", "dumbbell": "Dumbbell", "cable": "Cable", "machine": "Machine",
        "kettlebells": "Kettlebell", "e-z curl bar": "EZ bar", "bands": "Bands",
        "body only": "Bodyweight", "": "Bodyweight"
    ]

    static func build(from exercises: [Exercise]) -> ExerciseCatalog {
        var items: [CatalogItem] = []
        var stretches: [StretchItem] = []

        for exercise in exercises {
            guard let muscle = exercise.primaryMuscles.first else { continue }

            if exercise.category == "stretching" {
                stretches.append(StretchItem(id: exercise.id, name: exercise.name, muscle: muscle))
                continue
            }

            // Only strength exercises with a known equipment and a known muscle
            guard exercise.category == "strength",
                  let equipment = equipmentName[exercise.equipment],
                  let group = groupOfMuscle[muscle] else { continue }

            items.append(CatalogItem(
                id: exercise.id,
                name: exercise.name,
                level: exercise.level,
                mechanic: exercise.mechanic,
                force: exercise.force,
                equipment: equipment,
                muscle: muscle,
                group: group,
                variants: [:],
                needsBar: false
            ))
        }

        return ExerciseCatalog(items: items, stretches: stretches)
    }

    // MARK: The ids of the exercises that are never used
    // Read from the file once, then kept.
    static let excludedIds: [String] = {
        guard let url = Bundle.main.url(forResource: "esclusi_sicurezza", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ExcludedFile.self, from: data) else {
            print("CatalogBuilder: esclusi_sicurezza.json not found or not readable")
            return []
        }
        return file.excluded.map { $0.id }
    }()

    // MARK: The bodyweight exercises added by hand
    static let calisthenicsExtras: [CatalogItem] = {
        guard let url = Bundle.main.url(forResource: "calisthenics_aggiunti", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ExtraFile.self, from: data) else {
            print("CatalogBuilder: calisthenics_aggiunti.json not found or not readable")
            return []
        }
        return file.exercises.map { record in
            CatalogItem(
                id: record.id,
                name: record.name,
                level: record.level,
                mechanic: record.mechanic,
                force: record.force,
                equipment: "Bodyweight",
                muscle: record.muscle,
                group: record.group,
                variants: record.variants,
                needsBar: record.needsBar ?? false
            )
        }
    }()
}

// MARK: - The shape of the two files (only to read them)
private struct ExcludedFile: Decodable {
    let excluded: [ExcludedRecord]
}

private struct ExcludedRecord: Decodable {
    let id: String
}

private struct ExtraFile: Decodable {
    let exercises: [ExtraRecord]
}

private struct ExtraRecord: Decodable {
    let id: String
    let name: String
    let muscle: String
    let group: String
    let mechanic: String
    let force: String
    let level: String
    let variants: [String: String]
    let needsBar: Bool?

    // The file writes "needs_bar"
    enum CodingKeys: String, CodingKey {
        case id, name, muscle, group, mechanic, force, level, variants
        case needsBar = "needs_bar"
    }
}
