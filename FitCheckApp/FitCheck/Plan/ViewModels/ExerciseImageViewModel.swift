//
//  ExerciseImageViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of the exercise photo: loads the photos of one exercise (usually 2:
// start and end of the movement) and says what the screen must show.
@MainActor
@Observable
final class ExerciseImageViewModel {

    enum LoadState {
        case loading
        case ready
        case failed
    }

    private(set) var state: LoadState = .loading
    private(set) var image: UIImage? = nil      // the one photo shown (the first of the exercise)

    private let paths: [String]
    private let store: ExerciseImageStore

    init(paths: [String], store: ExerciseImageStore = .shared) {
        self.paths = paths
        self.store = store
    }

    // The photo to show now (nil while loading or if it failed)
    var currentImage: UIImage? { image }

    // Loads only the first photo: one still image, never an alternating animation.
    func load() async {
        guard let path = paths.first else { state = .failed; return }
        state = .loading

        if let loaded = try? await store.image(for: path) {
            image = loaded
            state = .ready
        } else {
            state = .failed
        }
    }
}
