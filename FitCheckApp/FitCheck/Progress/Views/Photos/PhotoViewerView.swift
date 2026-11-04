//
//  PhotoViewerView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// One photo at a time, full screen. Swipe left and right to move between the dates.
// "Compare with…" goes back to the grid in selection mode with this photo already chosen.
// The trash asks for a confirmation before deleting.
struct PhotoViewerView: View {
    @Bindable var viewModel: PhotosViewModel

    @State private var isConfirmingDelete = false

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width
            let photos = viewModel.visiblePhotos
            let current = viewModel.photo(withId: viewModel.viewerId)

            VStack(spacing: AppSizes.Space.group * unit) {
                topBar(unit: unit)

                // The pages: one for each photo
                TabView(selection: $viewModel.viewerId) {
                    ForEach(photos) { photo in
                        PhotoImageView(data: photo.imageData, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
                            .tag(Optional(photo.id))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                dots(photos: photos, unit: unit)

                if let current {
                    info(current, unit: unit)
                }

                buttons(current: current, unit: unit)
            }
            .padding(.horizontal, 6 * unit)
            .padding(.bottom, AppSizes.Space.group * unit)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)   // this screen is always dark, like the photo viewers of the system
        .confirmationDialog("Delete this photo?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete photo", role: .destructive) { viewModel.deleteViewerPhoto() }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("It will be removed from this phone.")
        }
    }

    // MARK: - Top bar

    private func topBar(unit: CGFloat) -> some View {
        HStack {
            Button(action: { viewModel.isViewerOpen = false }) {
                Image(systemName: "xmark")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(Color.white)
                    .frame(width: 10 * unit, height: 10 * unit)
                    .background(Color.white.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()

            Text(viewModel.viewerPositionText)
                .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .padding(.top, AppSizes.Space.related * unit)
    }

    // MARK: - Dots

    private func dots(photos: [PhotoRecord], unit: CGFloat) -> some View {
        HStack(spacing: 1.4 * unit) {
            ForEach(photos) { photo in
                let isCurrent = photo.id == viewModel.viewerId
                Capsule()
                    .fill(isCurrent ? AppColors.yellow : Color.white.opacity(0.3))
                    .frame(width: isCurrent ? 4.6 * unit : 1.6 * unit, height: 1.6 * unit)
            }
        }
        .animation(.easeOut(duration: 0.2), value: viewModel.viewerId)
    }

    // MARK: - Date and angle

    private func info(_ photo: PhotoRecord, unit: CGFloat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                Text(ProgressFormat.dayMonthYear(photo.date))
                    .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    .foregroundStyle(Color.white)
                Text("\(photo.angle.title) · \(ProgressFormat.daysAgo(from: photo.date))")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            Spacer()
        }
    }

    // MARK: - Buttons

    private func buttons(current: PhotoRecord?, unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            Button(action: { viewModel.compareFromViewer() }) {
                HStack(spacing: AppSizes.Space.related * unit) {
                    Image(systemName: "square.split.2x1")
                    Text("Compare")
                }
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 3.6 * unit)
                .background(AppColors.yellow, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canCompare)
            .opacity(viewModel.canCompare ? 1 : 0.4)

            Button(action: { isConfirmingDelete = true }) {
                Image(systemName: "trash")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(AppColors.red)
                    .frame(width: 14 * unit, height: 12 * unit)
                    .background(Color.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete photo")
        }
    }
}

// MARK: - Previews
private func viewerViewModel(withData: Bool) -> PhotosViewModel {
    let viewModel = ProgressPreviewData.photosViewModel(withData: withData)
    viewModel.viewerId = viewModel.latest?.id
    return viewModel
}

#Preview("Light") {
    PhotoViewerView(viewModel: viewerViewModel(withData: true))
}

#Preview("Dark") {
    PhotoViewerView(viewModel: viewerViewModel(withData: true))
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PhotoViewerView(viewModel: viewerViewModel(withData: false))
}
