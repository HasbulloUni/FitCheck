//
//  ProgressScreenView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// The Progress screen. Named ProgressScreenView so it does not hide
// SwiftUI's own ProgressView (the spinner used in ExerciseImageView).
// Top to bottom: the title, the period capsule, the sessions, photos with minutes and
// the number stack, the muscle balance and the load gains.
struct ProgressScreenView: View {
    // The ViewModel owns the data: this View only draws it
    @State private var viewModel = ProgressScreenViewModel()
    @Environment(\.modelContext) private var modelContext

    // Changes when the Progress tab is tapped again: the screen returns to its main page
    var popToRootTrigger = 0

    var body: some View {
        // The NavigationStack lets the gallery open INSIDE the tab: the navbar stays visible
        NavigationStack {
            // The only GeometryReader of the screen: it measures the width of the device
            GeometryReader { geo in
                let unit = geo.size.width / 100   // 1% of the screen width
                let summary = viewModel.summary
                let photos = viewModel.photosViewModel

                ScrollView {
                    VStack(spacing: AppSizes.Space.section * unit) {
                        Text("Progress")
                            .font(.system(size: AppSizes.Text.display * unit, weight: .heavy))
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        PeriodCapsuleView(
                            title: viewModel.capsuleTitle,
                            canGoPrevious: viewModel.canGoPrevious,
                            canGoNext: viewModel.canGoNext,
                            unit: unit,
                            onPrevious: { viewModel.goPrevious() },
                            onNext: { viewModel.goNext() },
                            onOpen: { viewModel.isPeriodSheetOpen = true }
                        )

                        VStack(spacing: AppSizes.Space.related * unit) {
                            SessionsCardView(slices: summary.planSlices, total: summary.sessionCount, unit: unit)

                            // Photos on the left, minutes and the number stack on the right
                            HStack(alignment: .top, spacing: AppSizes.Space.related * unit) {
                                PhotosCardView(
                                    thumbnail: photos.periodPhotos.last?.thumbnailData,
                                    dateText: photos.periodPhotos.last.map { ProgressFormat.dayMonth($0.date) } ?? "",
                                    countText: photos.countText,
                                    agoText: photos.latestAgoText,
                                    canCompare: photos.canCompare,
                                    hasPhotosOutsidePeriod: !photos.photos.isEmpty,
                                    unit: unit,
                                    onOpen: { viewModel.isGalleryOpen = true },
                                    onCompare: {
                                        // Opens the compare screen with Before and After empty:
                                        // Photos goes under it first, so Back lands on Photos
                                        photos.filter = nil
                                        viewModel.openCompareFromCard()
                                    },
                                    onAdd: {
                                        // Opens Photos, where the choice "Take photo / Photo library" appears
                                        photos.pendingAdd = true
                                        viewModel.isGalleryOpen = true
                                    }
                                )
                                .frame(width: 43 * unit)

                                VStack(spacing: AppSizes.Space.related * unit) {
                                    MinutesCardView(
                                        minutes: summary.minutes,
                                        hasSessions: summary.sessionCount > 0,
                                        unit: unit
                                    )
                                    NumberStackView(numbers: summary.numbers, unit: unit)
                                }
                                .frame(width: 43 * unit)
                            }

                            MuscleBalanceCardView(
                                muscles: summary.muscleSets,
                                most: summary.mostMuscle,
                                least: summary.leastMuscle,
                                unit: unit
                            )

                            LoadGainsCardView(gains: summary.loadGains, topLoads: summary.topLoads, unit: unit)
                        }
                    }
                    .padding(AppSizes.Space.screen * unit)
                }
                // The sheet "Choose a period"
                .sheet(isPresented: $viewModel.isPeriodSheetOpen) {
                    PeriodSheetView(
                        selectedUnit: viewModel.unit,
                        wheelItems: viewModel.wheelItems,
                        selectedIndex: viewModel.selectedWheelIndex,
                        customStart: viewModel.customStart,
                        customEnd: viewModel.customEnd,
                        title: viewModel.capsuleTitle,
                        sessionsText: viewModel.sessionsText,
                        minutesText: viewModel.minutesText,
                        unit: unit,
                        onSelectUnit: { viewModel.selectUnit($0) },
                        onSelectIndex: { viewModel.selectWheelIndex($0) },
                        onPickDate: { viewModel.pickCustomDate($0) },
                        onDone: { viewModel.isPeriodSheetOpen = false }
                    )
                    .presentationDetents([.fraction(0.75), .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .background(AppColors.background)
            .onAppear {
                viewModel.configure(context: modelContext)
                viewModel.photosViewModel.period = viewModel.period
            }
            // A second tap on the Progress tab: back to the main page, from Photos, Compare or the viewer
            .onChange(of: popToRootTrigger) { _, _ in
                withAnimation { viewModel.popToRoot() }
            }
            // Photos follows the period chosen with the capsule
            .onChange(of: viewModel.period) { _, newPeriod in
                viewModel.photosViewModel.period = newPeriod
            }
            // Tapping the photo opens Photos: Back returns here
            .navigationDestination(isPresented: $viewModel.isGalleryOpen) {
                PhotosScreenView(
                    viewModel: viewModel.photosViewModel,
                    onBack: { viewModel.isGalleryOpen = false }
                )
                .navigationBarBackButtonHidden(true)   // the screens have their own Back
                .toolbar(.hidden, for: .navigationBar)
            }
            // (The compare screen is opened by the Photos screen, so Back from Compare always lands on Photos)
            // The screen has its own title: no system title bar
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview("Light") {
    ProgressScreenView()
        .modelContainer(progressPreviewContainer(withData: true))
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ProgressScreenView()
        .modelContainer(progressPreviewContainer(withData: true))
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    ProgressScreenView()
        .modelContainer(progressPreviewContainer(withData: false))
}
