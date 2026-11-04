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

    init(paths: [String]) {
        _viewModel = State(initialValue: ExerciseImageViewModel(paths: paths))
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
                // No internet and not saved yet: a quiet placeholder, never a crash
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipped()
        .accessibilityLabel("Exercise photo")
        .task {
            await viewModel.load()
        }
    }
}
