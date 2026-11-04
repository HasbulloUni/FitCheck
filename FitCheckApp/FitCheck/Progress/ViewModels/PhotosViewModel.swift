//
//  PhotosViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// The ViewModel of the photos: it owns the saved photos and the logic, the Views only draw.
// Everything stays on the phone, saved with SwiftData (PhotoRecord).
@Observable
final class PhotosViewModel {
    // All the photos, from the oldest to the newest
    private(set) var photos: [PhotoRecord] = []

    // The two photos chosen in "Compare" (nil = use the first and the last photo)
    private var beforeId: UUID? = nil
    private var afterId: UUID? = nil

    private var context: ModelContext?

    init() {}

    // Only for the previews: a ViewModel that already has some photos and no database
    init(previewPhotos: [PhotoRecord]) {
        photos = previewPhotos
    }

    // Called when the screen appears: loads the saved photos
    func configure(context: ModelContext) {
        self.context = context
        reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<PhotoRecord>(sortBy: [SortDescriptor(\.date)])
        photos = (try? context?.fetch(descriptor)) ?? []
    }

    // MARK: - What the cards show

    var latest: PhotoRecord? { photos.last }
    var first: PhotoRecord? { photos.first }
    var canCompare: Bool { photos.count >= 2 }

    // "8 photos"
    var countText: String {
        photos.count == 1 ? "1 photo" : "\(photos.count) photos"
    }

    // "10 days ago" (empty when there are no photos)
    var latestAgoText: String {
        guard let latest else { return "" }
        return ProgressFormat.daysAgo(from: latest.date)
    }

    // The photos grouped by month, newest month first (newest photo first inside each month)
    var groups: [PhotoGroup] {
        var result: [PhotoGroup] = []
        for photo in photos.reversed() {
            let title = ProgressFormat.monthNameYear(photo.date)
            if let index = result.firstIndex(where: { $0.id == title }) {
                let old = result[index]
                result[index] = PhotoGroup(id: old.id, title: old.title, photos: old.photos + [photo])
            } else {
                result.append(PhotoGroup(id: title, title: title, photos: [photo]))
            }
        }
        return result
    }

    // "3 Sep → 25 Oct" for the first and the last photo
    var journeyText: String {
        guard let first, let latest else { return "" }
        return "\(ProgressFormat.dayMonth(first.date)) → \(ProgressFormat.dayMonth(latest.date))"
    }

    // MARK: - Add and delete

    // Saves a photo picked by the user (data = the picture as the picker gives it)
    func add(imageData: Data) {
        guard let context else { return }
        guard let processed = PhotoImageProcessor.process(imageData) else { return }
        context.insert(PhotoRecord(date: .now, imageData: processed.big, thumbnailData: processed.small))
        try? context.save()
        reload()
    }

    func delete(_ photo: PhotoRecord) {
        guard let context else { return }
        context.delete(photo)
        try? context.save()
        reload()
    }

    // MARK: - Compare

    // The photo on the "before" side: the one chosen, or the oldest
    var beforePhoto: PhotoRecord? {
        photos.first(where: { $0.id == beforeId }) ?? photos.first
    }

    // The photo on the "after" side: the one chosen, or the newest
    var afterPhoto: PhotoRecord? {
        photos.first(where: { $0.id == afterId }) ?? photos.last
    }

    // The photos that can go on the left: never newer than the photo on the right
    var beforeChoices: [PhotoRecord] {
        guard let after = afterPhoto else { return photos }
        return photos.filter { $0.date <= after.date }
    }

    // The photos that can go on the right: never older than the photo on the left
    var afterChoices: [PhotoRecord] {
        guard let before = beforePhoto else { return photos }
        return photos.filter { $0.date >= before.date }
    }

    func chooseBefore(_ photo: PhotoRecord) {
        if let after = afterPhoto, photo.date > after.date { return }
        beforeId = photo.id
    }

    func chooseAfter(_ photo: PhotoRecord) {
        if let before = beforePhoto, photo.date < before.date { return }
        afterId = photo.id
    }

    func isBefore(_ photo: PhotoRecord) -> Bool { beforePhoto?.id == photo.id }
    func isAfter(_ photo: PhotoRecord) -> Bool { afterPhoto?.id == photo.id }
}
