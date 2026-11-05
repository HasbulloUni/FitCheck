//
//  ValuePickerSheet.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The sheet with the native iPhone wheel, opened by a tap on the number of reps or weight.
// Scrolling the wheel is much faster than tapping + or - (the weight goes 2.5 kg at a time).
struct ValuePickerSheet: View {
    let viewModel: WorkoutViewModel
    let kind: WorkoutViewModel.PickerKind
    let unit: CGFloat
    let onDone: () -> Void

    private var title: String {
        let name = kind == .reps ? "Reps" : "Weight"
        return "\(name) · Set \(viewModel.activeSetIndex + 1)"
    }

    var body: some View {
        VStack(spacing: AppSizes.Space.group * unit) {
            HStack {
                Text(title)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                        .foregroundStyle(Color(light: 0x111111, dark: 0x111111))
                        .padding(.horizontal, 5 * unit)
                        .frame(height: 11 * unit)
                        .background(AppColors.yellow, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            wheel
        }
        .padding(5 * unit)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppColors.background)
    }

    @ViewBuilder
    private var wheel: some View {
        switch kind {
        case .reps:
            Picker("Reps", selection: Binding(
                get: { viewModel.activeSet.reps },
                set: { viewModel.setReps($0) }
            )) {
                ForEach(viewModel.repsOptions, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)

        case .weight:
            Picker("Weight", selection: Binding(
                get: { viewModel.activeWeightOnWheel },
                set: { viewModel.setWeight($0) }
            )) {
                ForEach(viewModel.weightOptions, id: \.self) { value in
                    Text("\(WorkoutFormat.weight(value)) kg").tag(value)
                }
            }
            .pickerStyle(.wheel)
        }
    }
}

#Preview("Light") {
    ValuePickerSheet(viewModel: WorkoutPreviewData.viewModel(onStep: 1), kind: .weight, unit: 3.9, onDone: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ValuePickerSheet(viewModel: WorkoutPreviewData.viewModel(onStep: 1), kind: .reps, unit: 3.9, onDone: {})
        .preferredColorScheme(.dark)
}
