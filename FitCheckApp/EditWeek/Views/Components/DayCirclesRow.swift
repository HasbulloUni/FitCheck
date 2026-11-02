//
//  DayCirclesRow.swift
//  FitCheck
//
//  Created by AFP FED 11 on 02/11/2026.
//

import SwiftUI

// The seven round buttons M T W T F S S: the user taps a day to make it a training day.
// Only drawing: the logic (maximum days...) lives in EditWeekViewModel.
// Every size is a multiple of "unit" (1% of the screen width), like the other components.
struct DayCirclesRow: View {
    let selectedWeekdays: [Int]            // training days (1 = Sunday ... 7 = Saturday)
    let unit: CGFloat
    let onToggle: (Int) -> Void            // called with the number of the tapped day

    // Monday first. The numbers are the ones of the Apple calendar.
    private let days: [(number: Int, letter: String)] = [
        (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S"), (1, "S")
    ]

    var body: some View {
        HStack(spacing: 1 * unit) {
            ForEach(days, id: \.number) { day in
                let isSelected = selectedWeekdays.contains(day.number)

                Button(action: { onToggle(day.number) }) {
                    // The circle is drawn first and it fills all the space of its column:
                    // its size does not depend on the letter. The letter is put on top of it.
                    Circle()
                        .fill(isSelected ? AppColors.textPrimary : AppColors.card)
                        .overlay(Circle().stroke(AppColors.divider, lineWidth: 0.3 * unit))
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            Text(day.letter)
                                .font(.system(size: 3 * unit, weight: .bold))
                                .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Previews
// The row only draws: the chosen days come from outside.
// This small wrapper keeps the choice, so in the preview the circles really switch.
private struct DayCirclesRowPreview: View {
    @State var selectedWeekdays: [Int]

    var body: some View {
        DayCirclesRow(
            selectedWeekdays: selectedWeekdays,
            unit: 7,
            onToggle: { day in
                if selectedWeekdays.contains(day) {
                    selectedWeekdays.removeAll { $0 == day }
                } else {
                    selectedWeekdays.append(day)
                }
            }
        )
        .padding(20)
        .background(AppColors.background)
    }
}

#Preview("Light") {
    DayCirclesRowPreview(selectedWeekdays: [2, 4, 6])
}

#Preview("Dark") {
    DayCirclesRowPreview(selectedWeekdays: [2, 4, 6])
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    DayCirclesRowPreview(selectedWeekdays: [])
}
