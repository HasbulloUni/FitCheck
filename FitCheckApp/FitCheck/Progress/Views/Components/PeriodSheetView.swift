//
//  PeriodSheetView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The sheet "Choose a period": the unit (Week, Month, 3 months, Year, Custom), the wheel
// or the calendar, what is being shown, and the "Show progress" button.
// Only drawing: every choice is sent to the ViewModel through the closures.
struct PeriodSheetView: View {
    let selectedUnit: ProgressUnit
    let wheelItems: [PeriodWheelItem]
    let selectedIndex: Int
    let customStart: Date
    let customEnd: Date?
    let title: String            // the chosen period, e.g. "Nov 2026"
    let sessionsText: String     // e.g. "13 sessions"
    let minutesText: String      // e.g. "630 min"
    let unit: CGFloat
    let onSelectUnit: (ProgressUnit) -> Void
    let onSelectIndex: (Int) -> Void
    let onPickDate: (Date) -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {
                Text("Choose a period")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                PeriodUnitPicker(selected: selectedUnit, unit: unit, onSelect: onSelectUnit)

                Text(selectedUnit.hint)
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)

                if selectedUnit == .custom {
                    CustomRangeCalendarView(start: customStart, end: customEnd, unit: unit, onPick: onPickDate)
                } else {
                    // .id rebuilds the wheel when the unit changes, so it starts on the current period
                    PeriodWheelView(items: wheelItems, selectedIndex: selectedIndex, unit: unit, onSelect: onSelectIndex)
                        .id(selectedUnit)
                }

                showing

                Button(action: onDone) {
                    Text("Show progress")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4.2 * unit)
                        .background(AppColors.textPrimary, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6 * unit)
            .padding(.top, 6 * unit)
            .padding(.bottom, 4 * unit)
        }
        .background(AppColors.background)
    }

    // "Showing Nov 2026" on the left, sessions and minutes on the right
    private var showing: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                Text("Showing")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)

                Text(title)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSizes.Space.tight * unit) {
                Text(sessionsText)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                Text(minutesText)
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Previews
// The sheet only draws. This wrapper keeps the unit and the choice, so in the preview it really works.
private struct PeriodSheetPreview: View {
    let hasData: Bool
    @State private var viewModel = ProgressScreenViewModel()

    var body: some View {
        PeriodSheetView(
            selectedUnit: viewModel.unit,
            wheelItems: hasData ? ProgressPreviewData.wheelItems() : ProgressPreviewData.emptyWheelItems(),
            selectedIndex: viewModel.selectedWheelIndex,
            customStart: viewModel.customStart,
            customEnd: viewModel.customEnd,
            title: viewModel.capsuleTitle,
            sessionsText: hasData ? "13 sessions" : "0 sessions",
            minutesText: hasData ? "630 min" : "0 min",
            unit: 3.9,
            onSelectUnit: { viewModel.selectUnit($0) },
            onSelectIndex: { viewModel.selectWheelIndex($0) },
            onPickDate: { viewModel.pickCustomDate($0) },
            onDone: {}
        )
    }
}

#Preview("Light") {
    PeriodSheetPreview(hasData: true)
}

#Preview("Dark") {
    PeriodSheetPreview(hasData: true)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PeriodSheetPreview(hasData: false)
}
