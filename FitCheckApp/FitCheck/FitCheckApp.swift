//
//  FitCheckApp.swift
//  FitCheck
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI
import SwiftData

@main
struct FoundationApp: App {
    // The database of the app (for now it only holds the exercises)
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Exercise.self)
        } catch {
            fatalError("Cannot create the database: \(error)")
        }
        // First launch: fill the database from exercises.json
        ExerciseImporter.importIfNeeded(into: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
