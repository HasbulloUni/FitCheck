//
//  PhotoDetailView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// One photo, big, with its date and a "Delete photo" button (with a confirmation).
// It gets plain values (the picture and the date), not the saved row, so nothing breaks
// while the photo is being deleted.
struct PhotoDetailView: View {
    let imageData: Data
    let date: Date
    let onBack: () -> Void
    let onDelete: () -> Void

    @State private var isConfirmingDelete = false

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(spacing: AppSizes.Space.section * unit) {
                HStack(spacing: AppSizes.Space.group * unit) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(width: 10 * unit, height: 10 * unit)
                            .background(AppColors.card, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")

                    Text(ProgressFormat.dayMonthYear(date))
                        .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()
                }

                // The whole photo, never cropped
                PhotoImageView(data: imageData, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))

                Button(action: { isConfirmingDelete = true }) {
                    Text("Delete photo")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                        .foregroundStyle(AppColors.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3.8 * unit)
                        .background(AppColors.card, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(6 * unit)
        }
        .background(AppColors.background)
        .confirmationDialog("Delete this photo?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete photo", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It will be removed from this phone.")
        }
    }
}

#Preview("Light") {
    PhotoDetailView(imageData: ProgressPreviewData.thumbnailData(), date: .now, onBack: {}, onDelete: {})
}

#Preview("Dark") {
    PhotoDetailView(imageData: ProgressPreviewData.thumbnailData(), date: .now, onBack: {}, onDelete: {})
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    // The picture is not ready yet: a grey box
    PhotoDetailView(imageData: Data(), date: .now, onBack: {}, onDelete: {})
}
