//
//  PhotosScreenView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData
import PhotosUI

// The Photos screen, the only place where photos live.
// Top to bottom: Back and title, the latest photo, the angle filter, the grid by month.
// At the bottom: "Compare" and "Add photo". Comparing is a selection mode of this same grid.
// Adding opens a small sheet; tapping a photo opens the viewer.
struct PhotosScreenView: View {
    @Bindable var viewModel: PhotosViewModel
    let onBack: () -> Void

    // The picture chosen in the photo library
    @State private var pickedItem: PhotosPickerItem?

    // The same speed for every change caused by the angle filter
    private let filterAnimation = Animation.smooth(duration: 0.38)

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                header(unit: unit)

                if viewModel.photos.isEmpty {
                    emptyState(unit: unit)
                } else {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                            // The latest photo, the chips and the grids: when the filter changes, the photo and
                            // the grids fade and move a little, the chips stay (their highlight slides)
                            topBlock(unit: unit)
                                .id("latest-\(viewModel.latest?.id.uuidString ?? "none")")
                                .transition(.opacity)
                            // The same bar as in Compare: "Jump to" and the angles
                            PhotoNavigationBar(jumpItems: jumpItems(proxy: proxy), angle: $viewModel.filter, unit: unit)
                                .id("navigationBar")
                            Group {
                                if viewModel.visiblePhotos.isEmpty {
                                    nothingInPeriod(unit: unit)
                                } else {
                                    monthGrids(unit: unit)
                                }
                            }
                            .id(viewModel.filter?.rawValue ?? "all")
                            .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                        }
                        .animation(filterAnimation, value: viewModel.filter)
                        .padding(.bottom, AppSizes.Space.section * unit)
                    }
                    .scrollIndicators(.hidden)
                    }
                }
            }
            .padding(.horizontal, AppSizes.Space.screen * unit)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .safeAreaInset(edge: .bottom) {
                bottomBar(unit: unit)
            }
            .overlay(alignment: .top) {
                toast(unit: unit)
            }
        }
        .background(AppColors.background)
        // Add: first the choice (camera or library), then the sheet "Ready to save".
        // The choice is a sheet: the camera or the library open only after it is closed.
        .sheet(isPresented: $viewModel.isChoosingSource, onDismiss: { viewModel.sourceSheetClosed() }) {
            PhotoSourceSheet(onChoose: { viewModel.chooseSource($0) })
        }
        .photosPicker(isPresented: $viewModel.isLibraryOpen, selection: $pickedItem, matching: .images)
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    viewModel.startDraft(imageData: data)
                }
                pickedItem = nil   // ready for the next photo
            }
        }
        .fullScreenCover(isPresented: $viewModel.isCameraOpen, onDismiss: { viewModel.cameraClosed() }) {
            CameraPicker(onCaptured: { viewModel.cameraData = $0 })
                .ignoresSafeArea()
        }
        .sheet(isPresented: Binding(
            get: { viewModel.draft != nil },
            set: { if !$0 { viewModel.cancelDraft() } }
        )) {
            PhotoAddSheet(viewModel: viewModel)
        }
        // When the card of Progress asked to add, the choice opens once this screen is on screen
        .onAppear {
            viewModel.showLatestPhotoIfPeriodIsEmpty()
            // The Compare button of the Progress card: Photos is the page under Compare
            if viewModel.pendingCompare {
                viewModel.pendingCompare = false
                viewModel.startCompare()
            }
            if viewModel.pendingAdd {
                viewModel.pendingAdd = false
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.5))
                    viewModel.openSourceChoice()
                }
            }
        }
        // Compare opens on top of Photos: its Back button comes back here
        .navigationDestination(isPresented: $viewModel.isCompareOpen) {
            PhotoCompareView(viewModel: viewModel)
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
        }
        // View one photo
        .navigationDestination(isPresented: $viewModel.isViewerOpen) {
            PhotoViewerView(viewModel: viewModel)
                .navigationBarBackButtonHidden(true)
                .toolbar(.hidden, for: .navigationBar)
        }
        // (The compare screen is opened by the Progress screen, which owns the navigation)
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

            VStack(alignment: .leading, spacing: 0) {
                Text("Photos")
                    .font(.system(size: AppSizes.Text.display * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                if !viewModel.photos.isEmpty {
                    Text(viewModel.headerSubtitle)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(.top, AppSizes.Space.related * unit)
    }

    // MARK: - The latest photo (or the hint while choosing)

    @ViewBuilder
    private func topBlock(unit: CGFloat) -> some View {
        if let latest = viewModel.latest {
            Button(action: { viewModel.openViewer(latest) }) {
                PhotoImageView(data: latest.imageData)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4 / 4.6, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
                    .overlay(alignment: .topLeading) {
                        Text("Latest")
                            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, AppSizes.Space.group * unit)
                            .padding(.vertical, 1.4 * unit)
                            .background(AppColors.yellow, in: Capsule())
                            .padding(3.4 * unit)
                    }
                    .overlay(alignment: .bottom) {
                        latestCaption(latest, unit: unit)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open latest photo")
        }
    }

    private func latestCaption(_ latest: PhotoRecord, unit: CGFloat) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Text(ProgressFormat.dayMonth(latest.date))
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                Text("\(ProgressFormat.daysAgo(from: latest.date)) · \(latest.angle.title)")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
            }
            Spacer()
            Text(viewModel.sinceFirstText)
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, AppSizes.Space.section * unit)
        .padding(.top, 10 * unit)
        .padding(.bottom, 3.4 * unit)
        .background(
            LinearGradient(colors: [.clear, Color.black.opacity(0.65)], startPoint: .top, endPoint: .bottom)
        )
    }

    // MARK: - Jump to: the top of the list, a month, or the oldest photo

    private func jumpItems(proxy: ScrollViewProxy) -> [PhotoJumpItem] {
        var items: [PhotoJumpItem] = []
        if viewModel.latest != nil {
            items.append(PhotoJumpItem(id: "latest", title: "Latest photo", systemImage: "arrow.up.to.line") {
                withAnimation { proxy.scrollTo("navigationBar", anchor: .top) }
            })
        }
        // The photos are listed newest first: a month starts with its newest photo
        for group in viewModel.grouped(viewModel.visiblePhotos) {
            if let newestOfMonth = group.photos.first {
                items.append(PhotoJumpItem(id: group.id, title: group.title, systemImage: "calendar") {
                    withAnimation { proxy.scrollTo(newestOfMonth.id, anchor: .top) }
                })
            }
        }
        if let oldest = viewModel.first {
            items.append(PhotoJumpItem(id: "first", title: "First photo", systemImage: "arrow.down.to.line") {
                withAnimation { proxy.scrollTo(oldest.id, anchor: .bottom) }
            })
        }
        return items
    }

    // MARK: - The grids, one for each month

    private func monthGrids(unit: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: AppSizes.Space.related * unit), count: 3)

        return VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
            ForEach(viewModel.groups) { group in
                VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                    // Month titles only for periods longer than a month
                    if !group.title.isEmpty {
                        Text(group.title.uppercased())
                            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                            .tracking(0.3 * unit)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    LazyVGrid(columns: columns, spacing: AppSizes.Space.related * unit) {
                        ForEach(group.photos) { photo in
                            cell(photo, unit: unit)
                                .id(photo.id)
                        }
                    }
                }
            }
        }
    }

    private func cell(_ photo: PhotoRecord, unit: CGFloat) -> some View {
        Button(action: { viewModel.openViewer(photo) }) {
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
                .scaleEffect(viewModel.newPhotoId == photo.id ? 1.04 : 1)
                .animation(.spring(duration: 0.5), value: viewModel.newPhotoId)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(ProgressFormat.dayMonth(photo.date)), \(photo.angle.title)")
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private func bottomBar(unit: CGFloat) -> some View {
        if viewModel.photos.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: AppSizes.Space.related * unit) {
                barButton(title: "Compare", icon: "square.split.2x1", isMain: false, isEnabled: viewModel.canCompare, unit: unit) {
                    viewModel.startCompare()
                }
                barButton(title: "Add photo", icon: "plus", isMain: true, isEnabled: true, unit: unit) {
                    viewModel.openSourceChoice()
                }
            }
            .padding(.horizontal, AppSizes.Space.screen * unit)
            .padding(.vertical, AppSizes.Space.group * unit)
        }
    }

    private func barButton(
        title: String, icon: String?, isMain: Bool, isEnabled: Bool, unit: CGFloat, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            barLabel(title: title, icon: icon, isMain: isMain, unit: unit)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }

    private func barLabel(title: String, icon: String?, isMain: Bool, unit: CGFloat) -> some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
            }
            Text(title)
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
        }
        .foregroundStyle(isMain ? Color.black : AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3.8 * unit)
        .background(isMain ? AppColors.yellow : AppColors.card, in: Capsule())
    }

    // MARK: - Photos exist, but not in this period (or not with this angle)

    private func nothingInPeriod(unit: CGFloat) -> some View {
        VStack(spacing: AppSizes.Space.related * unit) {
            Text("No photos here")
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
            Text("Nothing in \(viewModel.periodTitle)\(viewModel.filter.map { " with the \($0.title.lowercased()) angle" } ?? ""). Change the period on the Progress screen.")
                .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // MARK: - Empty state

    private func emptyState(unit: CGFloat) -> some View {
        VStack(spacing: AppSizes.Space.section * unit) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: AppSizes.Text.hero * unit))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 50 * unit, height: 66 * unit)
                .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))

            VStack(spacing: AppSizes.Space.related * unit) {
                Text("Start your before")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                Text("Add a first photo today. In a few weeks you can slide between then and now. Photos stay on this phone.")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            barButton(title: "Add first photo", icon: "plus", isMain: true, isEnabled: true, unit: unit) {
                viewModel.openSourceChoice()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toast

    @ViewBuilder
    private func toast(unit: CGFloat) -> some View {
        if let text = viewModel.toastText {
            HStack(spacing: AppSizes.Space.group * unit) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.green)
                Text(text)
            }
            .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
            .foregroundStyle(AppColors.background)
            .padding(.horizontal, AppSizes.Space.section * unit)
            .padding(.vertical, AppSizes.Space.group * unit)
            .background(AppColors.textPrimary, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
            .padding(.top, AppSizes.Space.section * unit)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Previews
#Preview("Light") {
    NavigationStack {
        PhotosScreenView(viewModel: ProgressPreviewData.photosViewModel(withData: true), onBack: {})
    }
    .modelContainer(progressPreviewContainer(withData: true))
}

#Preview("Dark") {
    NavigationStack {
        PhotosScreenView(viewModel: ProgressPreviewData.photosViewModel(withData: true), onBack: {})
    }
    .modelContainer(progressPreviewContainer(withData: true))
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    NavigationStack {
        PhotosScreenView(viewModel: ProgressPreviewData.photosViewModel(withData: false), onBack: {})
    }
    .modelContainer(progressPreviewContainer(withData: false))
}
