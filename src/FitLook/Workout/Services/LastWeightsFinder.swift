//
//  LastWeightsFinder.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation
import SwiftData

// MARK: - The weight used the last time, for each exercise
// It reads the saved workouts (SessionRecord), newest first. The weight belongs to the
// exercise, not to the plan: the same exercise in two plans starts from the same weight.
enum LastWeightsFinder {

    // Dictionary: exercise id -> kg used the last time
    static func lastWeights(in context: ModelContext) -> [String: Double] {
        var descriptor = FetchDescriptor<SessionRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 60      // the last 60 workouts are more than enough
        let records = (try? context.fetch(descriptor)) ?? []

        var result: [String: Double] = [:]
        for record in records {
            for (index, id) in record.loadExerciseIds.enumerated() where result[id] == nil {
                if index < record.loadWeights.count {
                    result[id] = record.loadWeights[index]
                }
            }
        }
        return result
    }
}
