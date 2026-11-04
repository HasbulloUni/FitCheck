//
//  PhotoImageProcessor.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import UIKit

// MARK: - Makes a picked photo small enough to save
// Photos from the camera are huge. We save a big version (to look at and compare)
// and a small one (for the grids), both as JPEG.
enum PhotoImageProcessor {

    // The longest side of each version, in pixels
    private static let bigSide: CGFloat = 1600
    private static let smallSide: CGFloat = 400

    // Returns nil if the data is not an image
    static func process(_ data: Data) -> (big: Data, small: Data)? {
        guard let image = UIImage(data: data) else { return nil }
        guard
            let big = resized(image, longestSide: bigSide)?.jpegData(compressionQuality: 0.8),
            let small = resized(image, longestSide: smallSide)?.jpegData(compressionQuality: 0.7)
        else { return nil }
        return (big, small)
    }

    private static func resized(_ image: UIImage, longestSide: CGFloat) -> UIImage? {
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, longestSide / longest)   // never makes the photo bigger
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // one point = one pixel
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
