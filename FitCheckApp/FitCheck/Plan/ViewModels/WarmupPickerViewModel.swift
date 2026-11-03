//
//  WarmupPickerViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of "Warm-up": the user picks 1 to 3 moves (SafetyRules.minWarmupMoves...maxWarmupMoves).
// The warm-up is always on and cannot be skipped.
@Observable
final class WarmupPickerViewModel {

    let items: [CatalogItem]                          // the safe warm-up exercises
    let details: [String: ExercisePickerDetails]      // for the photo of each one
    private(set) var selected: [String]

    init(items: [CatalogItem], details: [String: ExercisePickerDetails], selected: [String]) {
        self.items = items
        self.details = details
        self.selected = selected
    }

    // MARK: The choice

    func isSelected(_ item: CatalogItem) -> Bool {
        selected.contains(item.id)
    }

    // A picked move can always be removed. A new one only while there are less than 3.
    func canToggle(_ item: CatalogItem) -> Bool {
        isSelected(item) || selected.count < SafetyRules.maxWarmupMoves
    }

    func toggle(_ item: CatalogItem) {
        if let position = selected.firstIndex(of: item.id) {
            selected.remove(at: position)
        } else if canToggle(item) {
            selected.append(item.id)
        }
    }

    func images(of item: CatalogItem) -> [String] {
        details[item.id]?.images ?? []
    }

    // MARK: Texts

    // e.g. "1 / 3"
    var countText: String { "\(selected.count) / \(SafetyRules.maxWarmupMoves)" }

    var canFinish: Bool { selected.count >= SafetyRules.minWarmupMoves }

    // e.g. "Done · 2 moves"
    var doneTitle: String {
        if !canFinish { return "Pick 1 to 3 moves" }
        return selected.count == 1 ? "Done · 1 move" : "Done · \(selected.count) moves"
    }

    var title: String { "Warm-up" }
}
