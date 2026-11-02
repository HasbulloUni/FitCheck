//
//  DurationPicker.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// One button for each duration in EditWeekRules.durations, e.g. "60 min", "90 min": the chosen one is black.
// Only drawing: it receives the list of durations and tells which one was tapped.
struct DurationPicker: View {
    let durations: [Int]                   // minutes, taken from EditWeekRules.durations
    let selected: Int                      // the chosen duration
    let unit: CGFloat
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 2.5 * unit) {
            ForEach(durations, id: \.self) { minutes in
                let isSelected = minutes == selected

                Button(action: { onSelect(minutes) }) {
                    Text(EditWeekRules.durationTitle(minutes))
                        .font(.system(size: 4 * unit, weight: .bold))
                        .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4.5 * unit)
                        .background(isSelected ? AppColors.textPrimary : AppColors.card, in: Capsule())
                        .overlay(Capsule().stroke(AppColors.divider, lineWidth: 0.3 * unit))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Previews
// The picker only draws: the chosen duration comes from outside.
// This small wrapper keeps the choice, so in the preview the buttons really switch.
private struct DurationPickerPreview: View {
    @State var selected = EditWeekRules.defaultDuration
    let durations: [Int]

    var body: some View {
        DurationPicker(durations: durations, selected: selected, unit: 3.9, onSelect: { selected = $0 })
            .padding(20)
            .background(AppColors.background)
    }
}

#Preview("Light") {
    DurationPickerPreview(durations: EditWeekRules.durations)
}

#Preview("Dark") {
    DurationPickerPreview(durations: EditWeekRules.durations)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    DurationPickerPreview(durations: [])
}
