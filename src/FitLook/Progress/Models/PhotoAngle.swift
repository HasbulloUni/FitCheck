//
//  PhotoAngle.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// The side of the body a progress photo shows.
// Comparing two photos makes sense only when the angle is the same.
enum PhotoAngle: String, CaseIterable, Identifiable {
    case front
    case side
    case back

    var id: String { rawValue }

    var title: String {
        switch self {
        case .front: return "Front"
        case .side: return "Side"
        case .back: return "Back"
        }
    }
}
