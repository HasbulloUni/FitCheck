//
//  WarmupPickerViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of "Warm-up": the user picks 1 or 2 moves (SafetyRules.minWarmupMoves...maxWarmupMoves).
// The warm-up always lasts 8 minutes and cannot be skipped.
@Observable
final class WarmupPickerViewModel {

    let generalMoves: [String]      // to get warm, about 4 min (walk, bike...)
    let mobilityMoves: [String]     // for the muscles of the day
    let mobilityTitle: String       // e.g. "MOBILITY FOR LEGS"
    let rampUpExercise: String?     // the exercise that gets the 2 ramp-up sets (nil = no exercises yet)
    private(set) var selected: [String]

    init(generalMoves: [String], mobilityMoves: [String], mobilityTitle: String,
         rampUpExercise: String?, selected: [String]) {
        self.generalMoves = generalMoves
        self.mobilityMoves = mobilityMoves
        self.mobilityTitle = mobilityTitle
        self.rampUpExercise = rampUpExercise
        self.selected = selected
    }

    // MARK: The choice

    func isSelected(_ move: String) -> Bool {
        selected.contains(move)
    }

    // A picked move can always be removed. A new one only while there are less than 2.
    func canToggle(_ move: String) -> Bool {
        isSelected(move) || selected.count < SafetyRules.maxWarmupMoves
    }

    func toggle(_ move: String) {
        if let position = selected.firstIndex(of: move) {
            selected.remove(at: position)
        } else if canToggle(move) {
            selected.append(move)
        }
    }

    // MARK: Texts

    // e.g. "1 / 2"
    var countText: String { "\(selected.count) / \(SafetyRules.maxWarmupMoves)" }

    var canFinish: Bool { selected.count >= SafetyRules.minWarmupMoves }

    // e.g. "Done · 2 moves"
    var doneTitle: String {
        if !canFinish { return "Pick 1 or 2 moves" }
        return selected.count == 1 ? "Done · 1 move" : "Done · \(selected.count) moves"
    }

    // e.g. "GET WARM · 4 MIN"
    var generalTitle: String { "GET WARM" }

    // e.g. "8 min, always on. Pick 1 or 2 moves."
    var subtitle: String {
        "Each move is \(SafetyRules.minutesPerWarmupMove) min. Pick 1 or 2 moves."
    }

    // e.g. "Ramp-up sets on Goblet Squat are added for you."
    var rampUpNote: String? {
        rampUpExercise.map { "Ramp-up sets on \($0) are added for you." }
    }

    // "Leg swings front to back (holding a support)" -> "Leg swings front to back"
    static func title(of move: String) -> String {
        guard let open = move.firstIndex(of: "(") else { return move }
        return move[..<open].trimmingCharacters(in: .whitespaces)
    }

    // "Leg swings front to back (holding a support)" -> "holding a support" (nil if there is none)
    static func note(of move: String) -> String? {
        guard let open = move.firstIndex(of: "("), let close = move.lastIndex(of: ")"), open < close else {
            return nil
        }
        return String(move[move.index(after: open)..<close])
    }
}
