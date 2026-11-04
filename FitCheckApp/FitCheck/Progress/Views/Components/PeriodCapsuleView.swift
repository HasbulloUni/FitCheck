//
//  PeriodCapsuleView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The period switcher under the title: a white capsule with the period in the middle.
// The arrows (outside the capsule) jump from period to period: week to week, month to month...
// Tapping the capsule opens "Choose a period".
struct PeriodCapsuleView: View {
    let title: String            // e.g. "Nov 2026"
    let canGoPrevious: Bool
    let canGoNext: Bool
    let unit: CGFloat            // 1% of the screen width
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onOpen: () -> Void

    var body: some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            arrowButton(systemName: "chevron.left", isEnabled: canGoPrevious, label: "Previous period", action: onPrevious)

            Button(action: onOpen) {
                Text(title)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8 * unit)
                    .frame(minWidth: 38 * unit)
                    .padding(.vertical, 3.4 * unit)
                    .background(AppColors.card, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose a period, now \(title)")

            arrowButton(systemName: "chevron.right", isEnabled: canGoNext, label: "Next period", action: onNext)
        }
        .frame(maxWidth: .infinity)
    }

    // One arrow: faded when there is nowhere to go
    private func arrowButton(systemName: String, isEnabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 8 * unit, height: 10 * unit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.25)
        .accessibilityLabel(label)
    }
}

#Preview("Light") {
    PeriodCapsuleView(title: "Nov 2026", canGoPrevious: true, canGoNext: false, unit: 3.9,
                      onPrevious: {}, onNext: {}, onOpen: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    PeriodCapsuleView(title: "27 Oct – 2 Nov", canGoPrevious: true, canGoNext: true, unit: 3.9,
                      onPrevious: {}, onNext: {}, onOpen: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    // The first period of the wheel: nowhere to go back
    PeriodCapsuleView(title: "2026", canGoPrevious: false, canGoNext: false, unit: 3.9,
                      onPrevious: {}, onNext: {}, onOpen: {})
        .padding(20)
        .background(AppColors.background)
}
