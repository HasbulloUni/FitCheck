//
//  PlanPreviewContainer.swift
//  FitCheck
//
//  Only for the Xcode previews of the plan screens and the Home.
//

import SwiftUI
import SwiftData

// The preview database lives in memory: "With data" fills it from exercises.json.
@MainActor
func planPreviewContainer(withData: Bool) -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, AppProfile.self, PlanRecord.self, configurations: configuration)
    if withData {
        ExerciseImporter.importIfNeeded(into: container.mainContext)
    }
    return container
}
