//
//  ExerciseImageView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// The photo of an exercise, reusable on any screen (workout, plan editor, picker).
// Use it like this: ExerciseImageView(paths: exercise.images)
struct ExerciseImageView: View {

    @State private var viewModel: ExerciseImageViewModel

    // canSwitch: a tap on the photo shows the other photo of the exercise (detail screen only)
    init(paths: [String], canSwitch: Bool = false) {
        _viewModel = State(initialValue: ExerciseImageViewModel(paths: paths, canSwitch: canSwitch))
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .ready:
                if let image = viewModel.currentImage {
                    // Fills and crops ("zoom") the whole space the caller gives this view
                    // (a square in the exercise rows), instead of leaving empty bars
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            case .failed:
                // Photo missing from the app: a quiet placeholder, never a crash
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipped()
        .overlay {
            // Small transparent hint that the photo can be tapped (bottom right).
            // The photo is as wide as the screen here, so its width gives the unit (1% of it).
            if viewModel.hasTwoPhotos {
                GeometryReader { geo in
                    let unit = geo.size.width / 100
                    Image(systemName: "hand.tap")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.4), radius: 2)
                        .padding(AppSizes.Space.group * unit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .overlay {
            // The tap layer exists only when the photo can switch, so in the rows of the
            // lists the tap still goes to the button around the photo
            if viewModel.hasTwoPhotos {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.toggle() }
            }
        }
        .accessibilityLabel("Exercise photo")
        .accessibilityHint(viewModel.hasTwoPhotos ? "Double tap to show the other photo" : "")
        .task {
            await viewModel.load()
        }
    }
}
