//
//  PhotoImageView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// Shows a saved photo from its data. It decodes the picture once (not at every redraw),
// and shows a grey box until it is ready.
// .fill covers the whole space (cropping the photo), .fit shows the whole photo with no bands.
struct PhotoImageView: View {
    let data: Data
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    var body: some View {
        Group {
            if contentMode == .fit {
                fitBody
            } else {
                fillBody
            }
        }
        .task(id: data) {
            image = UIImage(data: data)
        }
    }

    // Grey box with the photo covering it (the photo can be cropped)
    private var fillBody: some View {
        AppColors.cardAlt
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .clipped()
    }

    // The whole photo, with no grey box around it: the view is exactly as big as the photo,
    // so a clip shape or a border put on it follows the photo edges
    @ViewBuilder
    private var fitBody: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            AppColors.cardAlt   // placeholder while the photo is decoding
        }
    }
}

// MARK: - Previews
#Preview("Light") {
    PhotoImageView(data: ProgressPreviewData.photosViewModel(withData: true).latest?.imageData ?? Data(), contentMode: .fit)
}

#Preview("Dark") {
    PhotoImageView(data: ProgressPreviewData.photosViewModel(withData: true).latest?.imageData ?? Data(), contentMode: .fit)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PhotoImageView(data: Data(), contentMode: .fit)
}
