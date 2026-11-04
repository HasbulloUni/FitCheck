//
//  PhotoCompareView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// Compare two photos: drag the line left and right to reveal "before" and "after".
// Under the photos, two rows of dates choose which photo is "before" and which is "after".
// By default they are the first and the last photo.
struct PhotoCompareView: View {
    let viewModel: PhotosViewModel
    let onBack: () -> Void

    // Where the line is: from 0 (all "after") to 1 (all "before")
    @State private var split: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ScrollView {
                VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                    header(unit: unit)

                    if let before = viewModel.beforePhoto, let after = viewModel.afterPhoto, viewModel.canCompare {
                        slider(before: before, after: after, unit: unit)
                        chooser(title: "Before", unit: unit, isChosen: { viewModel.isBefore($0) }) {
                            viewModel.chooseBefore($0)
                        }
                        chooser(title: "After", unit: unit, isChosen: { viewModel.isAfter($0) }) {
                            viewModel.chooseAfter($0)
                        }
                    } else {
                        notEnoughPhotos(unit: unit)
                    }
                }
                .padding(6 * unit)
            }
        }
        .background(AppColors.background)
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

    // MARK: - A row of dates to choose a photo

    private func chooser(
        title: String,
        unit: CGFloat,
        isChosen: @escaping (PhotoRecord) -> Bool,
        onChoose: @escaping (PhotoRecord) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            Text(title.uppercased())
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .tracking(0.3 * unit)
                .foregroundStyle(AppColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSizes.Space.related * unit) {
                    ForEach(viewModel.photos) { photo in
                        let chosen = isChosen(photo)

                        Button(action: { onChoose(photo) }) {
                            Text(ProgressFormat.dayMonth(photo.date))
                                .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                                .foregroundStyle(chosen ? AppColors.background : AppColors.textPrimary)
                                .padding(.horizontal, 4 * unit)
                                .padding(.vertical, 2.4 * unit)
                                .background(chosen ? AppColors.textPrimary : AppColors.card, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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
