//
//  ExerciseImageStore.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import UIKit

// Gives the photo of an exercise. The photos are INSIDE the app (folder ExerciseImages),
// so they always work: no internet, no waiting, no download.
// Order: memory -> app folder. A photo path like "3_4_Sit-Up/0.jpg" is the file "3_4_Sit-Up__0.jpg".
actor ExerciseImageStore {

    static let shared = ExerciseImageStore()

    private let memory = NSCache<NSString, UIImage>()

    enum StoreError: Error { case notFound, badImage }

    // The photo for a path like "3_4_Sit-Up/0.jpg". Throws if the app has no such photo.
    func image(for path: String) async throws -> UIImage {
        let key = path as NSString

        if let cached = memory.object(forKey: key) { return cached }

        guard let url = fileURL(for: path) else { throw StoreError.notFound }
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            throw StoreError.badImage
        }

        memory.setObject(image, forKey: key)
        return image
    }

    // Finds the file in the app. Xcode copies the folder files flat into the app, but if the
    // folder is kept as a folder, the second lookup finds it.
    private func fileURL(for path: String) -> URL? {
        let name = path.replacingOccurrences(of: "/", with: "__")
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        return Bundle.main.url(forResource: base, withExtension: ext)
            ?? Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "ExerciseImages")
    }
}
