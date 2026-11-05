//
//  ReadyMadeViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The ViewModel of the "Ready-made" sheet: it only remembers which style is chosen.
// The algorithm that builds the plans comes later: it will receive the chosen style.
@Observable
final class ReadyMadeViewModel {

    // Full body is chosen the first time; after "Set week" the sheet comes back with the same choice
    private(set) var selected: ReadyMadeStyle

    init(selected: ReadyMadeStyle = .fullBody) {
        self.selected = selected
    }

    func select(_ style: ReadyMadeStyle) {
        selected = style
    }

    func isSelected(_ style: ReadyMadeStyle) -> Bool {
        selected == style
    }
}
