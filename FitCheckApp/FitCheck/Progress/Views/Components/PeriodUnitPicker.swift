//
//  PeriodUnitPicker.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The buttons at the top of "Choose a period": Week, Month, 3 months, Year, Custom.
// The chosen one is black. Only drawing: it tells which one was tapped.
struct PeriodUnitPicker: View {
    let selected: ProgressUnit
    let unit: CGFloat
    let onSelect: (ProgressUnit) -> Void

    var body: some View {
        HStack(spacing: AppSizes.Space.tight * unit) {
            ForEach(ProgressUnit.allCases) { option in
                let isSelected = option == selected

                Button(action: { onSelect(option) }) {
                    Text(option.title)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                        .foregroundStyle(isSelected ? AppColors.background : AppColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 2.6 * unit)
                        .background(isSelected ? AppColors.textPrimary : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(0.8 * unit)
        .background(AppColors.cardAlt, in: Capsule())
    }
}

// The picker only draws: the chosen unit comes from outside.
// This small wrapper keeps the choice, so in the preview the buttons really switch.
private struct PeriodUnitPickerPreview: View {
    @State var selected: ProgressUnit = .month

    var body: some View {
        PeriodUnitPicker(selected: selected, unit: 3.9, onSelect: { selected = $0 })
            .padding(20)
            .background(AppColors.background)
    }
}

#Preview("Light") {
    PeriodUnitPickerPreview()
}

#Preview("Dark") {
    PeriodUnitPickerPreview()
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PeriodUnitPickerPreview(selected: .custom)
}
