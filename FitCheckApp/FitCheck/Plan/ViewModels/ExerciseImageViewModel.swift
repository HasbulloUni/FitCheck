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
    private(set) var frames: [UIImage] = []     // the loaded photos, in order
    private(set) var frameIndex = 0             // the photo shown now

    private let paths: [String]
    private let store: ExerciseImageStore

    init(paths: [String], store: ExerciseImageStore = .shared) {
        self.paths = paths
        self.store = store
    }

    // The photo to show now (nil while loading or if it failed)
    var currentImage: UIImage? {
        frames.isEmpty ? nil : frames[frameIndex % frames.count]
    }

    // Loads all the photos. If at least one arrives, the state is ready.
    func load() async {
        if paths.isEmpty { state = .failed; return }
        state = .loading

        var loaded: [UIImage] = []
        for path in paths {
            if let image = try? await store.image(for: path) { loaded.append(image) }
        }

        frames = loaded
        state = loaded.isEmpty ? .failed : .ready
    }

    // Switches between the photos every second to show the movement.
    // It stops by itself when the view disappears (the task is cancelled).
    func animate() async {
        guard frames.count > 1 else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { break }
            frameIndex = (frameIndex + 1) % frames.count
        }
    }
}
