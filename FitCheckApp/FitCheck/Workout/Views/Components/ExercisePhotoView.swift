//
//  ExercisePhotoView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The big photo of the exercise. It takes ALL the free space the screen gives it.
// Tap the photo to see the second photo (and again to go back to the first one):
// the two photos show the start and the end of the movement.
// The "How to do it" button sits in the top right corner and opens the steps.
struct ExercisePhotoView: View {

    @State private var viewModel: ExercisePhotoViewModel
    let hasPhotos: Bool
    let unit: CGFloat
    let onHowTo: () -> Void

    init(paths: [String], unit: CGFloat, onHowTo: @escaping () -> Void) {
        _viewModel = State(initialValue: ExercisePhotoViewModel(paths: paths))
        hasPhotos = !paths.isEmpty
        self.unit = unit
        self.onHowTo = onHowTo
    }

    var body: some View {
        // Color.clear gives a flexible size: the photo is cropped to it and never pushes the layout
        Color.clear
            .overlay { photo }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 30 * unit)
            .background(AppColors.cardAlt)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
            .contentShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggle() }
            }
            .overlay(alignment: .topTrailing) { howToButton }
            .overlay(alignment: .bottom) { indicator }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(viewModel.hasTwoPhotos
                                ? "Exercise photo \(viewModel.index + 1) of 2. Tap to see the other one."
                                : "Exercise photo")
            .task { await viewModel.load() }
    }

    // The photo itself, or a quiet symbol while loading / when there is none
    @ViewBuilder
    private var photo: some View {
        if let image = viewModel.currentImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .id(viewModel.index)
                .transition(.opacity)
        } else if viewModel.state == .loading && hasPhotos {
            ProgressView()
        } else {
            Image(systemName: hasPhotos ? "figure.strengthtraining.traditional" : "figure.cooldown")
                .font(.system(size: 20 * unit))
                .foregroundStyle(AppColors.divider)
        }
    }

    private var howToButton: some View {
        Button(action: onHowTo) {
            Text("How to do it")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 3.5 * unit)
                .frame(height: 9 * unit)
                .background(AppColors.card, in: Capsule())
                .overlay(Capsule().stroke(AppColors.textPrimary, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .padding(3 * unit)
    }

    // Two dots tell there is a second photo and which one is on screen
    @ViewBuilder
    private var indicator: some View {
        if viewModel.hasTwoPhotos {
            HStack(spacing: AppSizes.Space.related * unit) {
                ForEach(0..<2, id: \.self) { position in
                    Capsule()
                        .fill(position == viewModel.index ? AppColors.textPrimary : AppColors.textPrimary.opacity(0.3))
                        .frame(width: position == viewModel.index ? 5 * unit : 2 * unit, height: 2 * unit)
                }
            }
            .padding(.horizontal, 3 * unit)
            .padding(.vertical, AppSizes.Space.group * unit)
            .background(AppColors.card.opacity(0.85), in: Capsule())
            .padding(.bottom, 3 * unit)
        }
    }
}

#Preview("Light") {
    ExercisePhotoView(paths: [], unit: 3.9, onHowTo: {})
        .frame(height: 300)
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ExercisePhotoView(paths: [], unit: 3.9, onHowTo: {})
        .frame(height: 300)
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
