//
//  ExerciseImageStore.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import UIKit

// Gives the photo of an exercise. The photos are NOT inside the app: they are downloaded
// from the Free Exercise DB (GitHub) the first time and then kept on the phone.
// Order: memory -> disk -> internet. After the first time it also works offline.
actor ExerciseImageStore {

    static let shared = ExerciseImageStore()

    // The start of every photo address. The path of the exercise ("3_4_Sit-Up/0.jpg") goes after it.
    private let baseURL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/"

    private let memory = NSCache<NSString, UIImage>()
    private let folder: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        folder = caches.appendingPathComponent("ExerciseImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    enum StoreError: Error { case badAddress, badImage }

    // The photo for a path like "3_4_Sit-Up/0.jpg". Throws if it is not saved and the download fails.
    func image(for path: String) async throws -> UIImage {
        let key = path as NSString

        if let cached = memory.object(forKey: key) { return cached }

        let file = folder.appendingPathComponent(path.replacingOccurrences(of: "/", with: "__"))
        if let data = try? Data(contentsOf: file), let image = UIImage(data: data) {
            memory.setObject(image, forKey: key)
            return image
        }

        guard let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: baseURL + encoded) else { throw StoreError.badAddress }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let image = UIImage(data: data) else { throw StoreError.badImage }

        try? data.write(to: file, options: .atomic)
        memory.setObject(image, forKey: key)
        return image
    }

    // Downloads the photos in the background (e.g. all the exercises of today's plan),
    // so in the gym the screen does not wait for the network. Errors are ignored.
    /* UNUSED (commented out, 4 Nov 2026) func prefetch(_ paths: [String]) async {
        for path in paths {
            _ = try? await image(for: path)
        }
    } */
}
