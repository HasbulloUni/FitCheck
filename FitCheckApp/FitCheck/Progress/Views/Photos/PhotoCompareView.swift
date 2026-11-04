//
//  PhotoCompareView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// Compare two photos: drag the line left and right to reveal "before" and "after".
// Under the slider, the two photos sit side by side in time order (older on the left, newer on the right).
// Tap one of them to change it: a sheet shows only the photos that keep this order.
// By default they are the first and the last photo.
struct PhotoCompareView: View {
    let viewModel: PhotosViewModel
    let onBack: () -> Void

    // Where the line is: from 0 (all "after") to 1 (all "before")
    @State private var split: CGFloat = 0.5

    // Which side is being changed (nil = the sheet is closed)
    @State private var pickingSide: CompareSide?

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ScrollView {
                VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                    header(unit: unit)

                    if let before = viewModel.beforePhoto, let after = viewModel.afterPhoto, viewModel.canCompare {
                        slider(before: before, after: after, unit: unit)
                        choosers(before: before, after: after, unit: unit)
                    } else {
                        notEnoughPhotos(unit: unit)
                    }
                }
                .padding(6 * unit)
            }
        }
        .background(AppColors.background)
        .sheet(item: $pickingSide) { side in
            PhotoChoiceSheet(
                title: side == .before ? "Choose the older photo" : "Choose the newer photo",
                photos: side == .before ? viewModel.beforeChoices : viewModel.afterChoices,
                chosenId: side == .before ? viewModel.beforePhoto?.id : viewModel.afterPhoto?.id,
                onChoose: { photo in
                    if side == .before { viewModel.chooseBefore(photo) } else { viewModel.chooseAfter(photo) }
                    pickingSide = nil
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header

    private func header(unit: CGFloat) -> some View {
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

            Text("Compare")
                .font(.system(size: AppSizes.Text.display * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
    }

    // MARK: - The two photos with the line

    private func slider(before: PhotoRecord, after: PhotoRecord, unit: CGFloat) -> some View {
        let width = 88 * unit
        let height = 100 * unit

        return ZStack {
            // "Before" fills everything, "after" is drawn on top and cut by the line
            PhotoImageView(data: before.imageData)
                .frame(width: width, height: height)

            PhotoImageView(data: after.imageData)
                .frame(width: width, height: height)
                .mask(alignment: .trailing) {
                    Rectangle().frame(width: width * (1 - split), height: height)
                }

            // The line and the round handle
            Rectangle()
                .fill(AppColors.background)
                .frame(width: 0.6 * unit, height: height)
                .offset(x: (split - 0.5) * width)

            Image(systemName: "arrow.left.and.right")
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(AppColors.background)
                .frame(width: 10 * unit, height: 10 * unit)
                .background(AppColors.textPrimary, in: Circle())
                .offset(x: (split - 0.5) * width)

            // The dates of the two sides
            HStack {
                dateBadge(before.date, unit: unit)
                Spacer()
                dateBadge(after.date, unit: unit)
            }
            .padding(2.4 * unit)
            .frame(width: width, height: height, alignment: .bottom)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    split = min(max(value.location.x / width, 0.02), 0.98)
                }
        )
    }

    private func dateBadge(_ date: Date, unit: CGFloat) -> some View {
        Text(ProgressFormat.dayMonth(date))
            .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 2.4 * unit)
            .padding(.vertical, 1 * unit)
            .background(AppColors.background, in: Capsule())
    }

    // MARK: - The two photos to tap, older on the left and newer on the right

    private func choosers(before: PhotoRecord, after: PhotoRecord, unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            chooserTile(title: "Before", photo: before, side: .before, unit: unit)
            chooserTile(title: "After", photo: after, side: .after, unit: unit)
        }
    }

    private func chooserTile(title: String, photo: PhotoRecord, side: CompareSide, unit: CGFloat) -> some View {
        Button(action: { pickingSide = side }) {
            VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                Text(title.uppercased())
                    .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                    .tracking(0.3 * unit)
                    .foregroundStyle(AppColors.textPrimary)

                PhotoImageView(data: photo.thumbnailData)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38 * unit)
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                            .foregroundStyle(AppColors.background)
                            .frame(width: 8 * unit, height: 8 * unit)
                            .background(AppColors.textPrimary, in: Circle())
                            .padding(2 * unit)
                    }

                Text(ProgressFormat.dayMonth(photo.date))
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) photo, \(ProgressFormat.dayMonth(photo.date)). Tap to change")
    }

    // MARK: - Fewer than 2 photos

    private func notEnoughPhotos(unit: CGFloat) -> some View {
        VStack(spacing: AppSizes.Space.related * unit) {
            Text("Add at least 2 photos")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Text("Then you can slide between two dates and see the change.")
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

// The two sides of the comparison
private enum CompareSide: Identifiable {
    case before
    case after

    var id: Int { self == .before ? 0 : 1 }
}

// MARK: - The sheet with the photos that can be chosen
// Newest first, the chosen one has a ring. Only the photos that keep "left older than right" are shown.
private struct PhotoChoiceSheet: View {
    let title: String
    let photos: [PhotoRecord]
    let chosenId: UUID?
    let onChoose: (PhotoRecord) -> Void

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100

            ScrollView {
                VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                    Text(title)
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: AppSizes.Space.related * unit), count: 3),
                        spacing: AppSizes.Space.related * unit
                    ) {
                        ForEach(photos.reversed()) { photo in
                            Button(action: { onChoose(photo) }) {
                                PhotoImageView(data: photo.thumbnailData)
                                    .frame(height: 40 * unit)
                                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
                                    .overlay {
                                        if photo.id == chosenId {
                                            RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit)
                                                .stroke(AppColors.textPrimary, lineWidth: 0.8 * unit)
                                        }
                                    }
                                    .overlay(alignment: .bottom) {
                                        Text(ProgressFormat.dayMonth(photo.date))
                                            .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                                            .foregroundStyle(AppColors.textPrimary)
                                            .padding(.horizontal, 2 * unit)
                                            .padding(.vertical, 0.8 * unit)
                                            .background(AppColors.background, in: Capsule())
                                            .padding(1.5 * unit)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(6 * unit)
            }
        }
        .background(AppColors.background)
    }
}

// MARK: - Previews
#Preview("Light") {
    PhotoCompareView(viewModel: ProgressPreviewData.photosViewModel(withData: true), onBack: {})
}

#Preview("Dark") {
    PhotoCompareView(viewModel: ProgressPreviewData.photosViewModel(withData: true), onBack: {})
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PhotoCompareView(viewModel: ProgressPreviewData.photosViewModel(withData: false), onBack: {})
}
