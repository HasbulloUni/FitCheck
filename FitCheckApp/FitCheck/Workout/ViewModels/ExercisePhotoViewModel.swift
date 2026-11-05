//
//  ExercisePhotoViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The ViewModel of the big photo of the workout screen. An exercise has up to 2 photos
// (start and end of the movement). Each tap on the photo, or on the switch "1 | 2",
// shows the other one, so the user sees how the exercise is done.
// (The photo of the other screens, ExerciseImageViewModel, still shows only one.)
@MainActor
@Observable
final class ExercisePhotoViewModel {

    private(set) var images: [UIImage?]         // one place for each photo (max 2); nil = not loaded yet
    private(set) var index = 0                  // 0 = first photo, 1 = second photo
    private(set) var didFail = false            // true when no photo could be loaded

    private let paths: [String]
    private let store: ExerciseImageStore

    init(paths: [String], store: ExerciseImageStore = .shared) {
        self.paths = Array(paths.prefix(2))
        self.store = store
        self.images = Array(repeating: nil, count: min(paths.count, 2))
    }

    // How many photos the exercise has (0, 1 or 2): the switch is shown from 2.
    // It does not wait for the download, so the buttons are always there.
    var photoCount: Int { paths.count }

    var hasTwoPhotos: Bool { photoCount > 1 }

    // The photo to show now (nil while it is loading)
    var currentImage: UIImage? {
        index < images.count ? images[index] : nil
    }

    // Tap on the photo: first photo -> second photo -> first photo...
    func toggle() {
        guard hasTwoPhotos else { return }
        index = (index + 1) % photoCount
    }

    // The switch "1 | 2" under "How to do it"
    func select(_ position: Int) {
        guard position < photoCount else { return }
        index = position
    }

    // Loads the photos one after the other (from disk or internet, see ExerciseImageStore):
    // the first one appears as soon as it is ready.
    func load() async {
        var loadedAny = false
        for (position, path) in paths.enumerated() {
            if let image = try? await store.image(for: path) {
                images[position] = image
                loadedAny = true
            }
        }
        didFail = !loadedAny
    }
}
