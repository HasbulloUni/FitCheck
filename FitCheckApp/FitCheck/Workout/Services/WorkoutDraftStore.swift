//
//  WorkoutDraftStore.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import Foundation

// MARK: - A workout in progress, saved so it can be resumed
// If the app is closed in the middle of a workout, the sets done are kept here for a few hours.
// Only plain numbers, saved on the phone with UserDefaults. It is deleted when the workout ends.
struct WorkoutDraft: Codable {
    var planId: String
    var savedAt: Date
    var stepIndex: Int
    var elapsedSeconds: Int
    var sets: [[WorkoutSet]]
}

enum WorkoutDraftStore {
    private static let key = "workoutDraft"
    static let maxAgeHours = 12.0

    static func save(_ draft: WorkoutDraft) {
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // The draft of this plan, only if it is recent and fits the steps of the workout
    static func load(planId: String, steps: [WorkoutStep]) -> WorkoutDraft? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let draft = try? JSONDecoder().decode(WorkoutDraft.self, from: data),
              draft.planId == planId else { return nil }

        let isRecent = Date().timeIntervalSince(draft.savedAt) < maxAgeHours * 3600
        let fits = draft.sets.count == steps.count
            && draft.stepIndex >= 0 && draft.stepIndex < steps.count
            && zip(draft.sets, steps).allSatisfy { $0.count == $1.setCount }
        if !isRecent || !fits {
            clear()
            return nil
        }
        return draft
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
