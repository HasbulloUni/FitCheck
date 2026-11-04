//
//  PeriodWheelView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The wheel of "Choose a period": one bar for each week, month, 3 months or year.
// The bars slide under a fixed frame in the middle; the bar inside the frame is the chosen period.
// The height of a bar is the minutes of that period, the number above it too.
struct PeriodWheelView: View {
    let items: [PeriodWheelItem]
    let selectedIndex: Int
    let unit: CGFloat
    let onSelect: (Int) -> Void

    // The bar that is in the middle of the wheel
    @State private var scrolledId: Int?

    // The wheel is as wide as the content of the sheet: 100 - 2 x 6 = 88 units
    private var wheelWidth: CGFloat { 88 * unit }
    private var itemWidth: CGFloat { 17 * unit }

    var body: some View {
        // Lets the first and the last bar reach the middle
        let sideSpace = (wheelWidth - itemWidth) / 2
        let tallest = max(items.map { $0.minutes }.max() ?? 1, 1)

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(items) { item in
                    barView(item, tallest: tallest)
                        .frame(width: itemWidth)
                        .id(item.id)
                        .onTapGesture {
                            withAnimation { scrolledId = item.id }
                        }
                }
            }
            .scrollTargetLayout()
        }
        .contentMargins(.horizontal, sideSpace, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledId, anchor: .center)
        .frame(width: wheelWidth, height: 46 * unit)
        // The frame of the chosen bar, always in the middle
        .overlay {
            RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit)
                .stroke(AppColors.textPrimary, lineWidth: 0.5 * unit)
                .frame(width: itemWidth + unit)
                .padding(.vertical, unit)
                .allowsHitTesting(false)
        }
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
        .onAppear {
            scrolledId = selectedIndex
        }
        .onChange(of: scrolledId) { _, newValue in
            if let newValue, newValue != selectedIndex {
                onSelect(newValue)
            }
        }
        .onChange(of: selectedIndex) { _, newValue in
            if scrolledId != newValue {
                withAnimation { scrolledId = newValue }
            }
        }
    }

    // MARK: - One bar

    private func barView(_ item: PeriodWheelItem, tallest: Int) -> some View {
        let isSelected = item.id == selectedIndex
        let distance = abs(item.id - selectedIndex)
        let barHeight = max(1.6 * unit, CGFloat(item.minutes) / CGFloat(tallest) * 22 * unit)

        return VStack(spacing: AppSizes.Space.tight * unit) {
            Text("\(item.minutes)")
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            RoundedRectangle(cornerRadius: AppSizes.Radius.small * unit)
                .fill(isSelected ? AppColors.textPrimary : AppColors.divider)
                .frame(width: 6.4 * unit, height: barHeight)

            Text(item.label)
                .font(.system(size: AppSizes.Text.caption * unit, weight: isSelected ? .heavy : .semibold))
                .foregroundStyle(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.vertical, 3 * unit)
        // The further from the middle, the fainter
        .opacity(max(0.3, 1 - Double(distance) * 0.22))
    }
}

// The wheel only draws: the chosen bar comes from outside.
// This small wrapper keeps the choice, so in the preview the wheel really works.
private struct PeriodWheelPreview: View {
    let items: [PeriodWheelItem]
    @State var selectedIndex: Int

    var body: some View {
        PeriodWheelView(items: items, selectedIndex: selectedIndex, unit: 3.9, onSelect: { selectedIndex = $0 })
            .padding(20)
            .background(AppColors.background)
    }
}

#Preview("Light") {
    PeriodWheelPreview(items: ProgressPreviewData.wheelItems(), selectedIndex: 17)
}

#Preview("Dark") {
    PeriodWheelPreview(items: ProgressPreviewData.wheelItems(), selectedIndex: 17)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    // No sessions: every bar has the smallest height
    PeriodWheelPreview(items: ProgressPreviewData.emptyWheelItems(), selectedIndex: 17)
}
