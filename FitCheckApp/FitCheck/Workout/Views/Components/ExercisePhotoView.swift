//
//  ExercisePhotoView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The photo of the exercise, with a FIXED height: it never grows or shrinks when the card
// below changes (set, rest, edit...). The screen gives it the height.
// Tap the photo, or the switch "1 | 2" under "How to do it", to see the second photo:
// the two photos show the start and the end of the movement.
struct ExercisePhotoView: View {

    @State private var viewModel: ExercisePhotoViewModel
    let hasPhotos: Bool
    let height: CGFloat
    let unit: CGFloat
    let onHowTo: (() -> Void)?     // nil = no "How to do it" button (the info sheet already is that)

    init(paths: [String], height: CGFloat, unit: CGFloat, onHowTo: (() -> Void)? = nil) {
        _viewModel = State(initialValue: ExercisePhotoViewModel(paths: paths))
        hasPhotos = !paths.isEmpty
        self.height = height
        self.unit = unit
        self.onHowTo = onHowTo
    }

    var body: some View {
        // Color.clear has the fixed size: the photo is cropped to it and never changes the layout
        Color.clear
            .overlay { photo }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(AppColors.cardAlt)
            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
            .contentShape(RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { viewModel.toggle() }
            }
            .overlay(alignment: .topTrailing) {
                // "How to do it" with the photo switch right under it
                VStack(alignment: .trailing, spacing: AppSizes.Space.related * unit) {
                    if let onHowTo { howToButton(action: onHowTo) }
                    photoSwitch
                }
                .padding(AppSizes.Space.group * unit)
            }
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
        } else if hasPhotos && !viewModel.didFail {
            ProgressView()
        } else {
            Image(systemName: hasPhotos ? "figure.strengthtraining.traditional" : "figure.cooldown")
                .font(.system(size: 20 * unit))
                .foregroundStyle(AppColors.divider)
        }
    }

    private func howToButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("How to do it")
                .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, 3.5 * unit)
                .frame(height: 9 * unit)
                .background(AppColors.card, in: Capsule())
                .overlay(Capsule().stroke(AppColors.textPrimary, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    // The switch of the two photos: "1" and "2". The selected one is black.
    // It is always shown when the exercise has 2 photos (it does not wait for the download).
    @ViewBuilder
    private var photoSwitch: some View {
        if viewModel.hasTwoPhotos {
            HStack(spacing: 0) {
                ForEach(0..<2, id: \.self) { position in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { viewModel.select(position) }
                    } label: {
                        Text("\(position + 1)")
                            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                            .foregroundStyle(position == viewModel.index ? AppColors.background : AppColors.textPrimary)
                            .frame(width: 9 * unit, height: 9 * unit)
                            .background(position == viewModel.index ? AppColors.textPrimary : Color.clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Photo \(position + 1)")
                }
            }
            .padding(AppSizes.Space.tight * unit)
            .background(AppColors.card, in: Capsule())
            .overlay(Capsule().stroke(AppColors.textPrimary, lineWidth: 2))
        }
    }
}

#Preview("Light") {
    ExercisePhotoView(paths: ["Barbell_Squat/0.jpg", "Barbell_Squat/1.jpg"], height: 220, unit: 3.9, onHowTo: {})
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ExercisePhotoView(paths: [], height: 220, unit: 3.9, onHowTo: {})
        .padding()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
