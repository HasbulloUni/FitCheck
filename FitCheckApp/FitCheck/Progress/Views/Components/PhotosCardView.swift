//
//  PhotosCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The "Photos" card: the last photo with its date, "Compare" and "+".
// Tapping the photo opens the gallery. With no photos the same card shows an empty box
// and a "+ Add photo" button.
struct PhotosCardView: View {
    let thumbnail: Data?        // the small picture of the last photo (nil = no photos)
    let dateText: String        // e.g. "25 Oct"
    let countText: String       // e.g. "8 photos"
    let agoText: String         // e.g. "10 days ago"
    let canCompare: Bool        // at least 2 photos
    let unit: CGFloat
    let onOpen: () -> Void
    let onCompare: () -> Void
    let onAdd: (Data) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            ProgressCardTitle(text: "Photos", unit: unit)

            if let thumbnail {
                withPhoto(thumbnail)
            } else {
                noPhotos
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .progressCard(unit: unit, height: 50 * unit)
    }

    // MARK: - With photos

    private func withPhoto(_ thumbnail: Data) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            // The photo takes all the space that is left
            Button(action: onOpen) {
                PhotoImageView(data: thumbnail)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
                    .overlay(alignment: .bottomLeading) {
                        Text(dateText)
                            .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(.horizontal, 2 * unit)
                            .padding(.vertical, 0.8 * unit)
                            .background(AppColors.background, in: Capsule())
                            .padding(unit * 1.6)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open photos")

            Text("\(countText) · \(agoText)")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: AppSizes.Space.related * unit) {
                Button(action: onCompare) {
                    Text("Compare")
                        .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2.2 * unit)
                        .background(AppColors.cardAlt, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canCompare)
                .opacity(canCompare ? 1 : 0.4)

                AddPhotoButton(onPicked: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                        .foregroundStyle(AppColors.background)
                        .frame(width: 8.4 * unit, height: 7.6 * unit)
                        .background(AppColors.textPrimary, in: Capsule())
                }
                .accessibilityLabel("Add photo")
            }
        }
    }

    // MARK: - No photos

    private var noPhotos: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            AppColors.cardAlt
                .overlay {
                    Image(systemName: "camera.fill")
                        .font(.system(size: AppSizes.Text.display * unit))
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))

            Text("No photos yet")
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Text("Add your first photo to see results")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)

            AddPhotoButton(onPicked: onAdd) {
                Text("+ Add photo")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 2.2 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
        }
    }
}

// MARK: - Previews
#Preview("Light") {
    PhotosCardView(
        thumbnail: ProgressPreviewData.thumbnailData(),
        dateText: "25 Oct", countText: "8 photos", agoText: "10 days ago",
        canCompare: true, unit: 3.9, onOpen: {}, onCompare: {}, onAdd: { _ in }
    )
    .frame(width: 43 * 3.9)
    .padding(20)
    .background(AppColors.background)
}

#Preview("Dark") {
    PhotosCardView(
        thumbnail: ProgressPreviewData.thumbnailData(),
        dateText: "25 Oct", countText: "8 photos", agoText: "10 days ago",
        canCompare: true, unit: 3.9, onOpen: {}, onCompare: {}, onAdd: { _ in }
    )
    .frame(width: 43 * 3.9)
    .padding(20)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    PhotosCardView(
        thumbnail: nil,
        dateText: "", countText: "", agoText: "",
        canCompare: false, unit: 3.9, onOpen: {}, onCompare: {}, onAdd: { _ in }
    )
    .frame(width: 43 * 3.9)
    .padding(20)
    .background(AppColors.background)
}
