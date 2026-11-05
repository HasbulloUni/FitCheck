//
//  PhotoDraft.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import Foundation

// A photo the user just picked and has not saved yet.
// It lives only while the "Ready to save" sheet is open.
struct PhotoDraft {
    let big: Data              // the picture that will be saved
    let small: Data            // the small version, also used for the preview in the sheet
    var date: Date             // the day of the photo (today by default)
    var angle: PhotoAngle      // front, side or back
    let isFromCamera: Bool     // taken now with the camera: the date is today and is not asked
}
