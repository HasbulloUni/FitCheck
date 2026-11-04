//
//  ExercisePhotoViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The ViewModel of the big photo of the workout screen. An exercise has up to 2 photos
// (start and end of the movement). Each tap on the photo shows the other one,
// so the user sees how the exercise is done.
// (The photo of the other screens, ExerciseImageViewModel, still shows only one.)
@MainActor
@Observable
final class ExercisePhotoViewModel {

    enum LoadState {
        case loading
        case ready
        case failed
    }

    private(set) var state: LoadState = .loading
    private(set) var images: [UIImage] = []     // the photos that were loaded (max 2), in order
    private(set) var index = 0                  // 0 = first photo, 1 = second photo

    private let paths: [String]
    private let store: ExerciseImageStore

    init(paths: [String], store: ExerciseImageStore = .shared) {
        self.paths = paths
        self.store = store
    }

    // The photo to show now (nil while loading or if it failed)
    var currentImage: UIImage? {
        index < images.count ? images[index] : nil
    }

    // True when there is a second photo to switch to
    var hasTwoPhotos: Bool { images.count > 1 }

    // Tap on the photo: first photo -> second photo -> first photo...
    func toggle() {
        guard hasTwoPhotos else { return }
        index = (index + 1) % images.count
    }

    // Loads the first two photos of the exercise (from disk or internet, see ExerciseImageStore)
    func load() async {
        guard !paths.isEmpty else { state = .failed; return }
        state = .loading

        var loaded: [UIImage] = []
        for path in paths.prefix(2) {
            if let image = try? await store.image(for: path) {
                loaded.append(image)
            }
        }
        images = loaded
        index = 0
        state = loaded.isEmpty ? .failed : .ready
    }
}
