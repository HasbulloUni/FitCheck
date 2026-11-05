//
//  PhotosViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// The ViewModel of the Photos screen. It owns the saved photos and every step of the flow:
// adding (draft), looking (viewer), choosing two photos (selection) and comparing.
// The Views only draw what is here. Everything stays on the phone, saved with SwiftData.
@Observable
final class PhotosViewModel {

    // All the photos, from the oldest to the newest
    private(set) var photos: [PhotoRecord] = []

    // Filter by angle (nil = all the photos)
    var filter: PhotoAngle? = nil

    // The period chosen on the Progress screen: Photos shows only the photos of that period
    // (nil = no period yet, all the photos)
    var period: ProgressPeriod?

    // The flow: which screen is open
    var isViewerOpen = false
    var isCompareOpen = false

    // Add: the picked photo waiting for date and angle
    var draft: PhotoDraft?

    // The viewer: the photo shown
    var viewerId: UUID?

    // Add: the source chosen by the user (camera or library)
    var isChoosingSource = false
    var chosenSource: PhotoSource?     // the row tapped in the sheet, used when the sheet closes
    var isLibraryOpen = false
    var isCameraOpen = false
    var pendingCompare = false        // the Compare button of the Progress card was tapped: Compare opens once Photos is on screen
    var pendingAdd = false            // the card of Progress asked to add: the choice opens when Photos is on screen
    var cameraData: Data?             // the picture just taken, used when the camera closes

    // Compare: the two photos (both empty at the start) and the side the user is choosing
    enum CompareSide { case before, after }
    private(set) var beforeId: UUID?
    private(set) var afterId: UUID?
    var activeSide: CompareSide = .before

    // Small feedback after saving or deleting
    private(set) var toastText: String?
    private(set) var newPhotoId: UUID?

    // Asks the Progress screen to move to the period that contains a day (after saving a photo,
    // or when Photos opens with photos that are all outside the chosen period)
    var onShowDate: ((Date) -> Void)?

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

    // MARK: - What the screens show

    // The photos taken in the chosen period, oldest first
    var periodPhotos: [PhotoRecord] {
        guard let period else { return photos }
        return photos.filter { ProgressPeriodBuilder.contains(period, $0.date) }
    }

    // The photos of the period after the angle filter, oldest first
    var visiblePhotos: [PhotoRecord] {
        guard let filter else { return periodPhotos }
        return periodPhotos.filter { $0.angle == filter }
    }

    var latest: PhotoRecord? { visiblePhotos.last }
    var first: PhotoRecord? { visiblePhotos.first }
    var canCompare: Bool { photos.count >= 2 }     // Compare uses all the photos, not only the period

    // "8 photos" (the ones of the period)
    var countText: String {
        let count = periodPhotos.count
        return count == 1 ? "1 photo" : "\(count) photos"
    }

    // "10 days ago" (empty when there are no photos in the period)
    var latestAgoText: String {
        guard let latest = periodPhotos.last else { return "" }
        return ProgressFormat.daysAgo(from: latest.date)
    }

    // The name of the period, e.g. "Nov 2026"
    var periodTitle: String {
        guard let period else { return "" }
        return ProgressPeriodBuilder.title(of: period)
    }

    // "Nov 2026 · 3 photos"
    var headerSubtitle: String {
        "\(periodTitle) · \(countText)"
    }

    // "42 days since your first"
    var sinceFirstText: String {
        guard let first, let latest else { return "" }
        let days = ProgressPeriodBuilder.daysBetween(
            ProgressPeriodBuilder.startOfDay(first.date),
            ProgressPeriodBuilder.startOfDay(latest.date)
        )
        return "\(days) days since your first"
    }

    // Months get their own rows only when the period is longer than a month (3 months, year, long custom).
    // For a week or a month the photos are one single list.
    var separatesMonths: Bool {
        guard let period else { return true }
        switch period.unit {
        case .week, .month: return false
        case .quarter, .year: return true
        case .custom: return period.dayCount > 31
        }
    }

    // The visible photos grouped by month, newest month first (newest photo first inside each month)
    var groups: [PhotoGroup] {
        if separatesMonths { return grouped(visiblePhotos) }
        // One list, newest first, without month titles
        let list = Array(visiblePhotos.reversed())
        return list.isEmpty ? [] : [PhotoGroup(id: "all", title: "", photos: list)]
    }

    // Any list of photos (oldest first) grouped by month, newest month first
    func grouped(_ list: [PhotoRecord]) -> [PhotoGroup] {
        var result: [PhotoGroup] = []
        for photo in list.reversed() {
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

    func photo(withId id: UUID?) -> PhotoRecord? {
        guard let id else { return nil }
        return photos.first(where: { $0.id == id })
    }

    // MARK: - Add

    // Called when the user picks a picture: it is prepared and the "Ready to save" sheet opens
    func startDraft(imageData: Data, isFromCamera: Bool = false) {
        let day = ProgressPeriodBuilder.today()
        let angle = filter ?? .front
        // A big photo is resized away from the main thread, so the screen never freezes
        Task { @MainActor in
            let processed = await Task.detached(priority: .userInitiated) {
                PhotoImageProcessor.process(imageData)
            }.value
            guard let processed else {
                photoLoadFailed()
                return
            }
            draft = PhotoDraft(
                big: processed.big,
                small: processed.small,
                date: day,
                angle: angle,
                isFromCamera: isFromCamera
            )
        }
    }

    // Photos opens and there are photos, but none in the chosen period: the period moves to the latest photo,
    // so the screen never says "No photos here" while photos exist.
    func showLatestPhotoIfPeriodIsEmpty() {
        guard periodPhotos.isEmpty, let last = photos.last else { return }
        onShowDate?(last.date)
    }

    // The picked photo could not be opened: the user is told
    func photoLoadFailed() {
        showToast("Couldn't open this photo. Try another one.")
    }

    // Opens the sheet "Take photo / Photo library"
    func openSourceChoice() {
        isChoosingSource = true
    }

    // The user tapped a row of the sheet: it is remembered and the sheet closes
    func chooseSource(_ source: PhotoSource) {
        chosenSource = source
        isChoosingSource = false
    }

    // The sheet is closed: only now the camera or the library can open (two screens never open together)
    func sourceSheetClosed() {
        guard let source = chosenSource else { return }
        chosenSource = nil
        switch source {
        case .camera: isCameraOpen = true
        case .library: isLibraryOpen = true
        }
    }

    func cancelDraft() {
        draft = nil
    }

    func saveDraft() {
        guard let draft, let context else { return }
        let photo = PhotoRecord(date: draft.date, imageData: draft.big, thumbnailData: draft.small, angle: draft.angle)
        context.insert(photo)
        do {
            try context.save()
        } catch {
            context.rollback()
            showToast("Couldn't save the photo. Try again.")
            return   // the draft stays open
        }
        self.draft = nil
        filter = nil
        reload()
        // The new photo must be visible: if its day is outside the chosen period, the period moves to it
        onShowDate?(photo.date)
        newPhotoId = photo.id
        showToast("Photo saved on this iPhone.")
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            newPhotoId = nil
        }
    }

    // MARK: - Viewer

    func openViewer(_ photo: PhotoRecord) {
        viewerId = photo.id
        isViewerOpen = true
    }

    // "1 of 8" in the viewer
    var viewerPositionText: String {
        guard let index = visiblePhotos.firstIndex(where: { $0.id == viewerId }) else { return "" }
        return "\(index + 1) of \(visiblePhotos.count)"
    }

    func deleteViewerPhoto() {
        guard let context, let current = photo(withId: viewerId) else { return }
        let list = visiblePhotos
        let index = list.firstIndex(where: { $0.id == current.id }) ?? 0
        // The viewer moves to a neighbour before the photo disappears
        let neighbour = list.indices.contains(index + 1) ? list[index + 1] : (index > 0 ? list[index - 1] : nil)
        context.delete(current)
        do {
            try context.save()
        } catch {
            context.rollback()
            showToast("Couldn't delete the photo. Try again.")
            return
        }
        reload()
        if let neighbour {
            viewerId = neighbour.id
        } else {
            viewerId = nil
            isViewerOpen = false
        }
        showToast("Photo deleted")
    }

    // From the viewer: Compare opens with this photo already in "Before"
    func compareFromViewer() {
        guard let current = photo(withId: viewerId) else { return }
        isViewerOpen = false
        // The viewer closes first, then the compare screen opens
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.45))
            startCompare(before: current)
        }
    }

    // MARK: - Camera

    // Called when the camera closes: if a picture was taken the "Ready to save" sheet opens
    func cameraClosed() {
        guard let data = cameraData else { return }
        cameraData = nil
        startDraft(imageData: data, isFromCamera: true)
    }

    // MARK: - Compare

    // Opens the compare screen. "Before" and "After" start empty (or with one photo already chosen)
    func startCompare(before: PhotoRecord? = nil) {
        beforeId = before?.id
        afterId = nil
        activeSide = before == nil ? .before : .after
        isCompareOpen = true
    }

    // Back from Compare (Photos is always under it)
    func closeCompare() {
        isCompareOpen = false
    }

    var beforePhoto: PhotoRecord? { photo(withId: beforeId) }
    var afterPhoto: PhotoRecord? { photo(withId: afterId) }
    var hasBothPhotos: Bool { beforePhoto != nil && afterPhoto != nil }

    // "6 weeks" or "9 days" between the two photos
    var compareGapText: String {
        guard let before = beforePhoto, let after = afterPhoto else { return "" }
        let days = abs(ProgressPeriodBuilder.daysBetween(
            ProgressPeriodBuilder.startOfDay(before.date),
            ProgressPeriodBuilder.startOfDay(after.date)
        ))
        let weeks = Int((Double(days) / 7).rounded())
        if weeks >= 2 { return "\(weeks) weeks" }
        return days == 1 ? "1 day" : "\(days) days"
    }

    // Tapping a photo of the filmstrip fills the side that is active, then moves to the empty side
    func choose(_ photo: PhotoRecord) {
        switch activeSide {
        case .before:
            beforeId = photo.id
            if afterId == photo.id { afterId = nil }
            if afterId == nil { activeSide = .after }
        case .after:
            afterId = photo.id
            if beforeId == photo.id { beforeId = nil }
            if beforeId == nil { activeSide = .before }
        }
    }

    // MARK: - Toast

    private func showToast(_ text: String) {
        toastText = text
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            toastText = nil
        }
    }
}
