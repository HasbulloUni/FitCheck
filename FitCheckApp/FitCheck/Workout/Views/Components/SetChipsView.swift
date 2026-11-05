//
//  SetChipsView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// One chip for each set: "Set 1", "Set 2"... A green check means done.
// The selected chip has a black border. Tapping a done set lets the user change it.
struct SetChipsView: View {
    let sets: [WorkoutSet]
    let activeIndex: Int
    let unit: CGFloat
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: AppSizes.Space.related * unit) {
            ForEach(sets.indices, id: \.self) { index in
                chip(index: index)
            }
        }
    }

    private func chip(index: Int) -> some View {
        let isDone = sets[index].isDone
        let isActive = index == activeIndex

        return Button { onSelect(index) } label: {
            HStack(spacing: AppSizes.Space.related * unit) {
                ZStack {
                    Circle()
                        .fill(isDone ? AppColors.greenSoft : (isActive ? AppColors.yellow : Color.clear))
                    if !isDone && !isActive {
                        Circle().stroke(AppColors.divider, lineWidth: 2)
                    }
                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
                            .foregroundStyle(isActive ? Color(light: 0x111111, dark: 0x111111) : AppColors.textSecondary)
                    }
                }
                .frame(width: 6.5 * unit, height: 6.5 * unit)

                Text("Set \(index + 1)")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                    .foregroundStyle(isDone || isActive ? AppColors.textPrimary : AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 12 * unit)
            .background(AppColors.card, in: Capsule())
            .overlay(Capsule().stroke(isActive ? AppColors.textPrimary : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Set \(index + 1)\(isDone ? ", done" : "")")
    }
}

#Preview("Light") {
    SetChipsView(
        sets: [WorkoutSet(reps: 10, weight: 60, isDone: true),
               WorkoutSet(reps: 10, weight: 60),
               WorkoutSet(reps: 10, weight: 60)],
        activeIndex: 1, unit: 3.9, onSelect: { _ in }
    )
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    SetChipsView(
        sets: [WorkoutSet(reps: 10, weight: 60, isDone: true),
               WorkoutSet(reps: 10, weight: 60),
               WorkoutSet(reps: 10, weight: 60)],
        activeIndex: 1, unit: 3.9, onSelect: { _ in }
    )
    .padding()
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}
