//
//  SplashView.swift
//  FitCheck
//
//  The loading screen shown while the app opens.
//  It looks like the static launch screen (same background, same icon, same size),
//  so the user sees no jump between the two. No logic here, only animation.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var iconVisible = false
    @State private var spinnerVisible = false

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            // The icon stays exactly in the center, like on the launch screen
            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: AppSizes.Launch.iconWidth)
                .opacity(iconVisible ? 1 : 0)
                .scaleEffect(reduceMotion || iconVisible ? 1 : 0.94)
                .accessibilityLabel("FitLook")
                .overlay(alignment: .bottom) {
                    // Below the icon, so the icon does not move when it appears
                    ProgressView()
                        .tint(AppColors.textSecondary)
                        .opacity(spinnerVisible ? 1 : 0)
                        .offset(y: AppSizes.Space.screen * 5)
                }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                iconVisible = true
            }
        }
        .task {
            // The spinner appears only if loading lasts more than 0.3 seconds
            try? await Task.sleep(nanoseconds: 300_000_000)
            withAnimation(.easeIn(duration: 0.2)) {
                spinnerVisible = true
            }
        }
    }
}

#Preview("Light") {
    SplashView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashView()
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    // The splash needs no data: it is the same screen without a database
    SplashView()
}
