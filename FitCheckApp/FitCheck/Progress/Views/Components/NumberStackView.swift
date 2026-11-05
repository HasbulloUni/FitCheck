//
//  NumberStackView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The number stack, like an Apple widget stack: swipe left or right and the number changes.
// After the last one it comes back to the first, and the other way round.
// The page that leaves gets smaller, fades and blurs while the next one slides in.
// It swipes sideways (not up and down) so it never fights with the scroll of the screen.
struct NumberStackView: View {
    let numbers: [StackNumber]
    let unit: CGFloat

    // The number on screen, and how far the finger has dragged it
    @State private var index = 0
    @State private var dragX: CGFloat = 0

    // The card is 43% of the screen wide: two cards side by side with the Home margins
    private var cardWidth: CGFloat { 43 * unit }
    private var cardHeight: CGFloat { 24 * unit }

    var body: some View {
        ZStack {
            if numbers.isEmpty {
                Color.clear
            } else {
                // The page before, the current one and the next one
                ForEach([-1, 0, 1], id: \.self) { relative in
                    page(numbers[wrapped(index + relative)], relative: relative)
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .overlay(alignment: .bottom) { dots }
        .contentShape(Rectangle())
        .simultaneousGesture(swipe)
    }

    // MARK: - One page

    private func page(_ number: StackNumber, relative: Int) -> some View {
        // Distance of this page from the middle of the card: from 0 to 1
        let position = CGFloat(relative) * cardWidth + dragX
        let distance = min(abs(position) / cardWidth, 1)

        return VStack(alignment: .leading, spacing: 0) {
            Text(number.title)
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: unit) {
                Text(number.value)
                    .font(.system(size: AppSizes.Text.display * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                if !number.unit.isEmpty {
                    Text(number.unit)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Text(number.detail)
                .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 6 * unit, alignment: .topLeading)   // room for 2 lines
        }
        .padding(.horizontal, AppSizes.Space.section * unit)
        .padding(.top, AppSizes.Space.section * unit)
        .padding(.bottom, 5.5 * unit)   // space for the dots
        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
        .scaleEffect(1 - distance * 0.16)
        .opacity(1 - distance * 0.9)
        .blur(radius: distance * 1.3 * unit)
        .offset(x: position)
    }

    // MARK: - The dots (the active one is longer)

    private var dots: some View {
        HStack(spacing: unit) {
            ForEach(0..<numbers.count, id: \.self) { position in
                Capsule()
                    .fill(position == index ? AppColors.textPrimary : AppColors.divider)
                    .frame(width: position == index ? 3 * unit : unit, height: unit)
            }
        }
        .padding(.bottom, 2.2 * unit)
        .animation(.easeOut(duration: 0.2), value: index)
        .allowsHitTesting(false)
    }

    // MARK: - The swipe

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                // Only a sideways drag moves the card: a vertical one is left to the scroll
                if abs(value.translation.width) > abs(value.translation.height) {
                    dragX = value.translation.width
                }
            }
            .onEnded { value in
                let moved = value.translation.width
                let isSideways = abs(moved) > abs(value.translation.height)
                let isFarEnough = abs(moved) > cardWidth * 0.25
                let isFastEnough = abs(value.predictedEndTranslation.width) > cardWidth * 0.6

                if isSideways && (isFarEnough || isFastEnough) {
                    changePage(forward: moved < 0, from: moved)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { dragX = 0 }
                }
            }
    }

    // Goes to the next page (swipe left) or the previous one (swipe right), in a loop.
    // The new page takes the place the dragged one had, then slides to the middle.
    private func changePage(forward: Bool, from moved: CGFloat) {
        var noAnimation = Transaction()
        noAnimation.disablesAnimations = true
        withTransaction(noAnimation) {
            index = wrapped(index + (forward ? 1 : -1))
            dragX = moved + (forward ? cardWidth : -cardWidth)
        }
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { dragX = 0 }
        }
    }

    // Keeps the position between 0 and the last number, going around
    private func wrapped(_ value: Int) -> Int {
        guard !numbers.isEmpty else { return 0 }
        return ((value % numbers.count) + numbers.count) % numbers.count
    }
}

// MARK: - Previews
#Preview("Light") {
    NumberStackView(numbers: ProgressPreviewData.summary().numbers, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    NumberStackView(numbers: ProgressPreviewData.summary().numbers, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    NumberStackView(numbers: ProgressPreviewData.emptySummary().numbers, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}
