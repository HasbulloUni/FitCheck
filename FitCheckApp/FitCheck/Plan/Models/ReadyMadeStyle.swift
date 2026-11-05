//
//  ReadyMadeStyle.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// The two ways to build a ready-made plan.
// The training days are already chosen in "Edit your week", so the user only picks the style.
enum ReadyMadeStyle: String, CaseIterable, Identifiable {
    case fullBody       // every training day trains the whole body
    case muscleGroups   // the muscle groups are shared between the training days

    var id: String { rawValue }

    // The name shown in the list
    var title: String {
        switch self {
        case .fullBody:     return "Full body"
        case .muscleGroups: return "Muscle groups"
        }
    }
}
