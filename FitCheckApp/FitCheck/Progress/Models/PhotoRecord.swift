//
//  PhotoRecord.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation
import SwiftData

// MARK: - A progress photo saved with SwiftData
// Everything stays on the phone: the picture is saved inside the database.
// The big picture goes to an external file managed by SwiftData (.externalStorage),
// the small one (thumbnailData) stays in the row so the grids open fast.
@Model
final class PhotoRecord {
    @Attribute(.unique) var id: UUID
    var date: Date                                  // the day the photo was added
    @Attribute(.externalStorage) var imageData: Data
    var thumbnailData: Data

    init(date: Date, imageData: Data, thumbnailData: Data) {
        self.id = UUID()
        self.date = date
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }
}
