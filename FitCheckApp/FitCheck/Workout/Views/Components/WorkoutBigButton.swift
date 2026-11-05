//
//  WorkoutBigButton.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The big rounded button of the workout screens: yellow (main action) or black (next).
struct WorkoutBigButton: View {

    enum Style {
        case yellow
        case black
    }

    let title: String
    let style: Style
    let unit: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                .foregroundStyle(style == .yellow ? Color(light: 0x111111, dark: 0x111111) : AppColors.background)
                .frame(maxWidth: .infinity)
                .frame(height: 15 * unit)
                .background(style == .yellow ? AppColors.yellow : AppColors.textPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Light") {
    VStack(spacing: 12) {
        WorkoutBigButton(title: "Complete set", style: .yellow, unit: 3.9, action: {})
        WorkoutBigButton(title: "Next exercise", style: .black, unit: 3.9, action: {})
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    VStack(spacing: 12) {
        WorkoutBigButton(title: "Complete set", style: .yellow, unit: 3.9, action: {})
        WorkoutBigButton(title: "Next exercise", style: .black, unit: 3.9, action: {})
    }
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
