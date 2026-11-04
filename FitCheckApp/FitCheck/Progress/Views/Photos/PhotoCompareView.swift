//
//  PhotoCompareView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// Compare two photos. It opens with "Before" and "After" empty: the user picks each one
// from the filmstrip. With both chosen, a yellow line can be dragged to reveal one or the other.
// Under the filmstrip, a native menu jumps straight to a month or to the end of the list.
struct PhotoCompareView: View {
    @Bindable var viewModel: PhotosViewModel

    // Where the line is: from 0 (all "after") to 1 (all "before")
    @State private var split: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ScrollView {
                VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                    header(unit: unit)

                    if viewModel.photos.count < 2 {
                        notEnoughPhotos(unit: unit)
                    } else {
                        if let before = viewModel.beforePhoto, let after = viewModel.afterPhoto {
                            slider(before: before, after: after, unit: unit)
                            stats(before: before, after: after, unit: unit)
                        } else {
                            slots(unit: unit)
                        }
                        sidePicker(unit: unit)
                        filmstrip(unit: unit)
                    }
                }
                .padding(6 * unit)
            }
            .scrollIndicators(.hidden)
        }
        .background(AppColors.background)
    }

    // MARK: - Header

    private func header(unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            Button(action: { viewModel.isCompareOpen = false }) {
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

    // MARK: - Both photos chosen: the slider

    private func slider(before: PhotoRecord, after: PhotoRecord, unit: CGFloat) -> some View {
        let width = 88 * unit
        let height = 108 * unit

        return ZStack {
            // "Before" fills everything, "After" is drawn on top and cut by the line
            PhotoImageView(data: before.imageData)
                .frame(width: width, height: height)

            PhotoImageView(data: after.imageData)
                .frame(width: width, height: height)
                .mask(alignment: .trailing) {
                    Rectangle().frame(width: width * (1 - split), height: height)
                }

            // The line and the round handle
            Rectangle()
                .fill(AppColors.yellow)
                .frame(width: 0.7 * unit, height: height)
                .offset(x: (split - 0.5) * width)

            Image(systemName: "arrow.left.and.right")
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(Color.black)
                .frame(width: 11 * unit, height: 11 * unit)
                .background(AppColors.yellow, in: Circle())
                .offset(x: (split - 0.5) * width)

            // The two labels
            HStack {
                label("Before · \(ProgressFormat.dayMonth(before.date))", unit: unit)
                Spacer()
                label("After · \(ProgressFormat.dayMonth(after.date))", unit: unit)
            }
            .padding(3 * unit)
            .frame(width: width, height: height, alignment: .top)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    split = min(max(value.location.x / width, 0.03), 0.97)
                }
        )
    }

    private func label(_ text: String, unit: CGFloat) -> some View {
        Text(text)
            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 3 * unit)
            .padding(.vertical, 1.4 * unit)
            .background(Color.black.opacity(0.6), in: Capsule())
    }

    private func stats(before: PhotoRecord, after: PhotoRecord, unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            stat(value: viewModel.compareGapText, caption: "between the two", unit: unit)
            stat(
                value: before.angle.title,
                caption: before.angle == after.angle ? "same angle" : "vs \(after.angle.title)",
                unit: unit
            )
        }
    }

    private func stat(value: String, caption: String, unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
            Text(value)
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
            Text(caption)
                .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .progressCard(unit: unit)
    }

    // MARK: - Not both chosen yet: two empty slots

    private func slots(unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            slot(title: "Before", photo: viewModel.beforePhoto, side: .before, unit: unit)
            slot(title: "After", photo: viewModel.afterPhoto, side: .after, unit: unit)
        }
    }

    private func slot(title: String, photo: PhotoRecord?, side: PhotosViewModel.CompareSide, unit: CGFloat) -> some View {
        let isActive = viewModel.activeSide == side

        return Button(action: { viewModel.activeSide = side }) {
            ZStack {
                if let photo {
                    PhotoImageView(data: photo.thumbnailData)
                } else {
                    AppColors.card
                    VStack(spacing: AppSizes.Space.related * unit) {
                        Image(systemName: "plus")
                            .font(.system(size: AppSizes.Text.title * unit, weight: .semibold))
                        Text("Choose \(title)")
                            .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
            .overlay {
                RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit)
                    .stroke(isActive ? AppColors.yellow : Color.clear, lineWidth: 0.8 * unit)
            }
            .overlay(alignment: .topLeading) {
                Text(photo.map { "\(title) · \(ProgressFormat.dayMonth($0.date))" } ?? title)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                    .foregroundStyle(isActive ? Color.black : AppColors.textPrimary)
                    .padding(.horizontal, 2.6 * unit)
                    .padding(.vertical, 1.2 * unit)
                    .background(isActive ? AppColors.yellow : AppColors.background, in: Capsule())
                    .padding(2 * unit)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Which side the filmstrip fills

    private func sidePicker(unit: CGFloat) -> some View {
        HStack(spacing: 0) {
            sideButton(title: "Before", isSelected: viewModel.activeSide == .before, unit: unit) {
                viewModel.activeSide = .before
            }
            sideButton(title: "After", isSelected: viewModel.activeSide == .after, unit: unit) {
                viewModel.activeSide = .after
            }
        }
        .padding(unit)
        .background(AppColors.card, in: Capsule())
    }

    private func sideButton(title: String, isSelected: Bool, unit: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(isSelected ? AppColors.background : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2.4 * unit)
                .background(isSelected ? AppColors.textPrimary : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filmstrip: all the photos, oldest on the left; the two in use are marked

    private func filmstrip(unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                    ScrollView(.horizontal) {
                        HStack(spacing: AppSizes.Space.related * unit) {
                            ForEach(viewModel.photos) { photo in
                                filmCell(photo, unit: unit)
                                    .id(photo.id)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)

                    jumpMenu(proxy: proxy, unit: unit)
                }
            }
        }
    }

    private func filmCell(_ photo: PhotoRecord, unit: CGFloat) -> some View {
        let isBefore = photo.id == viewModel.beforeId
        let isAfter = photo.id == viewModel.afterId

        return Button(action: { viewModel.choose(photo) }) {
            PhotoImageView(data: photo.thumbnailData)
                .aspectRatio(3 / 4, contentMode: .fit)
                .frame(width: 15 * unit)
                .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit))
                .overlay {
                    if isBefore || isAfter {
                        RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit)
                            .stroke(isBefore ? AppColors.yellow : AppColors.textPrimary, lineWidth: 0.8 * unit)
                    }
                }
                .overlay(alignment: .bottomLeading) {
                    if isBefore || isAfter {
                        Text(isBefore ? "Before" : "After")
                            .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                            .foregroundStyle(isBefore ? Color.black : AppColors.background)
                            .padding(.horizontal, 1.4 * unit)
                            .padding(.vertical, 0.5 * unit)
                            .background(isBefore ? AppColors.yellow : AppColors.textPrimary, in: Capsule())
                            .padding(unit)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ProgressFormat.dayMonth(photo.date))
    }

    // MARK: - Native menu to jump to the end of the list (or to a month)

    private func jumpMenu(proxy: ScrollViewProxy, unit: CGFloat) -> some View {
        Menu {
            if let latest = viewModel.photos.last {
                Button("Latest photo", systemImage: "arrow.right.to.line") {
                    withAnimation { proxy.scrollTo(latest.id, anchor: .trailing) }
                }
            }
            ForEach(viewModel.grouped(viewModel.photos)) { group in
                if let oldestOfMonth = group.photos.last {
                    Button(group.title, systemImage: "calendar") {
                        withAnimation { proxy.scrollTo(oldestOfMonth.id, anchor: .leading) }
                    }
                }
            }
            if let first = viewModel.photos.first {
                Button("First photo", systemImage: "arrow.left.to.line") {
                    withAnimation { proxy.scrollTo(first.id, anchor: .leading) }
                }
            }
        } label: {
            HStack(spacing: AppSizes.Space.related * unit) {
                Image(systemName: "calendar")
                Text("Jump to")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
            }
            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 4 * unit)
            .padding(.vertical, 2.4 * unit)
            .background(AppColors.card, in: Capsule())
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
private func compareViewModel(withData: Bool, bothChosen: Bool) -> PhotosViewModel {
    let viewModel = ProgressPreviewData.photosViewModel(withData: withData)
    viewModel.startCompare(before: bothChosen ? viewModel.photos.first : nil)
    if bothChosen, let latest = viewModel.photos.last {
        viewModel.choose(latest)
    }
    return viewModel
}

#Preview("Light") {
    PhotoCompareView(viewModel: compareViewModel(withData: true, bothChosen: true))
}

#Preview("Dark") {
    PhotoCompareView(viewModel: compareViewModel(withData: true, bothChosen: false))
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PhotoCompareView(viewModel: compareViewModel(withData: false, bothChosen: false))
}
