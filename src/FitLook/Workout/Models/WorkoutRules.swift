//
//  WorkoutRules.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// MARK: - The numbers of the workout screen in one place
// To change a rule, change it here.
enum WorkoutRules {
    static let defaultReps = 10            // first value of the reps of a new set
    static let minReps = 1
    static let maxReps = 50

    static let weightStep = 2.5            // kg for each tap on + or -
    static let maxWeight = 300.0

    static let restSeconds = 90            // rest after a set
    static let restExtraSeconds = 15       // the "+15 s" button

    static let warmupMoveSeconds = 60      // a warm-up move (arm circles...)
    static let treadmillSeconds = 8 * 60   // Walking Treadmill: 8 minutes (it can go to 10)
    static let cooldownSeconds = 5 * 60    // the stretching at the end

    // A workout counts as done when at least this share of the sets of the main exercises is done
    // (warm-up and cool-down do not count). 0.5 = half of the sets.
    static let completionShare = 0.5

    // MARK: Layout of the exercise screen (in units: 1 unit = 1% of the screen width)
    // The photo has a FIXED height: all the screen minus the other blocks.
    // The card under the chips always has the same height, so rest, edit and "all done"
    // never move the photo.
    static let cardHeightUnits: CGFloat = 58        // Reps/Weight card, rest card, all done card
    static let otherBlocksUnits: CGFloat = 140      // header, title, chips, card, Next button, spaces
    static let minPhotoUnits: CGFloat = 30          // the photo is never smaller than this
}
