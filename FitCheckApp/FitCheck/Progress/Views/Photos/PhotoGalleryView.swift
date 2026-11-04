//
//  PhotoGalleryView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// The gallery: all the photos catalogued by month, newest first.
// On top: the first and the last photo with "Compare". Then the grid, which starts with "Add photo".
// Tapping a photo opens it. With no photos the same screen shows a short invitation.
struct PhotoGalleryView: View {
    let viewModel: PhotosViewModel
    let onBack: () -> Void

    // The photo opened full screen, and the compare screen
    @State private var openedPhoto: PhotoRecord?
    @State private var isCompareOpen = false

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ScrollView {
                VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                    header(unit: unit)

                    if viewModel.photos.isEmpty {
                        emptyState(unit: unit)
                    } else {
                        if viewModel.canCompare {
                            journeyCard(unit: unit)
                        }
                        monthGrids(unit: unit)
                    }
                }
                .padding(6 * unit)
            }
        }
        .background(AppColors.background)
        .navigationDestination(item: $openedPhoto) { photo in
            PhotoDetailView(
                imageData: photo.imageData,
                date: photo.date,
                onBack: { openedPhoto = nil },
                onDelete: {
                    openedPhoto = nil
                    viewModel.delete(photo)
                }
            )
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
        .navigationDestination(isPresented: $isCompareOpen) {
            PhotoCompareView(viewModel: viewModel, onBack: { isCompareOpen = false })
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header: Back, title, add

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

            Text("Photos")
                .font(.system(size: AppSizes.Text.display * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            AddPhotoButton(onPicked: { viewModel.add(imageData: $0) }) {
                Image(systemName: "plus")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(AppColors.background)
                    .frame(width: 10 * unit, height: 10 * unit)
                    .background(AppColors.textPrimary, in: Circle())
            }
            .accessibilityLabel("Add photo")
        }
    }

    // MARK: - First photo → last photo

    private func journeyCard(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
            Text(viewModel.journeyText)
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            HStack(spacing: AppSizes.Space.related * unit) {
                if let first = viewModel.first {
                    PhotoImageView(data: first.thumbnailData)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
                }
                if let latest = viewModel.latest {
                    PhotoImageView(data: latest.thumbnailData)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
                }
            }

            Button(action: { isCompareOpen = true }) {
                Text("Compare")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(AppColors.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3.6 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .progressCard(unit: unit)
    }

    // MARK: - The grids, one for each month

    private func monthGrids(unit: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppSizes.Space.related * unit), count: 3)

        return VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { groupIndex, group in
                VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                    Text(group.title.uppercased())
                        .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                        .tracking(0.3 * unit)
                        .foregroundStyle(AppColors.textPrimary)

                    LazyVGrid(columns: columns, spacing: AppSizes.Space.related * unit) {
                        // "Add photo" is the first square of the first month
                        if groupIndex == 0 {
                            AddPhotoButton(onPicked: { viewModel.add(imageData: $0) }) {
                                addTile(unit: unit)
                            }
                        }

                        ForEach(group.photos) { photo in
                            Button(action: { openedPhoto = photo }) {
                                PhotoImageView(data: photo.thumbnailData)
                                    .aspectRatio(3 / 4, contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
                                    .overlay(alignment: .bottomLeading) {
                                        Text(ProgressFormat.dayMonth(photo.date))
                                            .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
                                            .foregroundStyle(AppColors.textPrimary)
                                            .padding(.horizontal, 1.8 * unit)
                                            .padding(.vertical, 0.7 * unit)
                                            .background(AppColors.background, in: Capsule())
                                            .padding(1.4 * unit)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func addTile(unit: CGFloat) -> some View {
        VStack(spacing: unit) {
            Image(systemName: "plus")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
            Text("Add photo")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
        }
        .foregroundStyle(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .aspectRatio(3 / 4, contentMode: .fit)
        .background(AppColors.cardAlt, in: RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
    }

    // MARK: - No photos

    private func emptyState(unit: CGFloat) -> some View {
        VStack(spacing: AppSizes.Space.group * unit) {
            Image(systemName: "camera.fill")
                .font(.system(size: AppSizes.Text.hero * unit))
                .foregroundStyle(AppColors.textSecondary)

            Text("No photos yet")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Text("Add your first photo to see results. Photos stay on this phone.")
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            AddPhotoButton(onPicked: { viewModel.add(imageData: $0) }) {
                Text("+ Add photo")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(AppColors.background)
                    .padding(.horizontal, 8 * unit)
                    .padding(.vertical, 3.6 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

// MARK: - Previews
#Preview("Light") {
    NavigationStack {
        PhotoGalleryView(viewModel: ProgressPreviewData.photosViewModel(withData: true), onBack: {})
    }
    .modelContainer(progressPreviewContainer(withData: true))
}

#Preview("Dark") {
    NavigationStack {
        PhotoGalleryView(viewModel: ProgressPreviewData.photosViewModel(withData: true), onBack: {})
    }
    .modelContainer(progressPreviewContainer(withData: true))
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    NavigationStack {
        PhotoGalleryView(viewModel: ProgressPreviewData.photosViewModel(withData: false), onBack: {})
    }
    .modelContainer(progressPreviewContainer(withData: false))
}
