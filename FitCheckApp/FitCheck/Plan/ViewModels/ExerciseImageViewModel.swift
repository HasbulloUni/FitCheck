//
//  ExerciseImageViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The ViewModel of the exercise photo: loads the photos of one exercise (usually 2:
// start and end of the movement) and says what the screen must show.
// By default it shows one still photo; with canSwitch a tap alternates photo 1 and photo 2.
@MainActor
@Observable
final class ExerciseImageViewModel {

    enum LoadState {
        case loading
        case ready
        case failed
    }

    private(set) var state: LoadState = .loading
    private(set) var image: UIImage? = nil      // the first photo of the exercise (start of the movement)
    private(set) var secondImage: UIImage? = nil   // the second photo (end of the movement), only if asked
    private(set) var index = 0                  // 0 = first photo, 1 = second photo

    private let paths: [String]
    private let store: ExerciseImageStore
    private let loadsSecondPhoto: Bool

    // canSwitch: true only on the detail screen, where a tap shows the other photo.
    // Everywhere else (rows, lists) only the first photo is loaded, as before.
    init(paths: [String], canSwitch: Bool = false, store: ExerciseImageStore = .shared) {
        self.paths = paths
        self.loadsSecondPhoto = canSwitch
        self.store = store
    }

    // The photo to show now (nil while loading or if it failed)
    var currentImage: UIImage? { index == 1 ? (secondImage ?? image) : image }

    // True when a tap can switch: the exercise has 2 photos and the screen asked for it
    var hasTwoPhotos: Bool { loadsSecondPhoto && paths.count > 1 }

    // Tap on the photo: first photo -> second photo -> first photo...
    func toggle() {
        guard hasTwoPhotos, secondImage != nil else { return }
        index = index == 0 ? 1 : 0
    }

    // Loads the first photo, and the second one too when the screen can switch
    func load() async {
        guard let path = paths.first else { state = .failed; return }
        state = .loading

        if let loaded = try? await store.image(for: path) {
            image = loaded
            state = .ready
        } else {
            state = .failed
        }

        if loadsSecondPhoto, paths.count > 1 {
            secondImage = try? await store.image(for: paths[1])
        }
    }
}
