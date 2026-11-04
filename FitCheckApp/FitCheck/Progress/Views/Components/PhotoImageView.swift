//
//  PhotoImageView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// Shows a saved photo from its data. It decodes the picture once (not at every redraw),
// and shows a grey box until it is ready.
// .fill covers the whole space (cropping the photo), .fit shows the whole photo.
struct PhotoImageView: View {
    let data: Data
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?

    var body: some View {
        AppColors.cardAlt
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
            }
            .clipped()
            .task(id: data) {
                image = UIImage(data: data)
            }
    }
}
