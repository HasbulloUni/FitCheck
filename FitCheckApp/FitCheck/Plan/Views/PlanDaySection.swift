//
//  PlanDaySection.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// One day of the plan, as a section of the list:
// warm-up (tap to open), the exercises, "Add exercises", cool-down (tap to open).
struct PlanDaySection: View {
    let viewModel: PlanEditorViewModel
    let dayIndex: Int

    var body: some View {
        let day = viewModel.days[dayIndex]

        Section {
            // MARK: Warm-up
            DisclosureGroup {
                Text("\(day.warmup.generalName) · \(day.warmup.generalMinutes) min")
                ForEach(day.warmup.mobility, id: \.self) { move in
                    Text(move)
                }
                ForEach(day.warmup.approachSets.indices, id: \.self) { index in
                    let approach = day.warmup.approachSets[index]
                    Text("\(approach.exerciseName) · \(Int(approach.loadShare * 100))% load x \(approach.reps)")
                }
            } label: {
                HStack {
                    Label("Warm-up", systemImage: "figure.walk")
                    Spacer()
                    Text("\(Int(day.warmup.minutes)) min")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: Exercises
            ForEach(day.exercises) { exercise in
                VStack(alignment: .leading) {
                    Text(exercise.name)
                    Text(viewModel.detailText(exercise))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { offsets in
                viewModel.removeExercises(at: offsets, inDay: dayIndex)
            }

            Button {
                viewModel.pickerRequest = PickerRequest(dayIndex: dayIndex)
            } label: {
                Label("Add exercises", systemImage: "plus")
            }

            // MARK: Cool-down
            DisclosureGroup {
                Text("Slow walk · \(day.cooldown.walkMinutes) min")
                ForEach(day.cooldown.stretches.indices, id: \.self) { index in
                    let stretch = day.cooldown.stretches[index]
                    Text("\(stretch.name) · \(stretch.holdSeconds) s")
                }
            } label: {
                HStack {
                    Label("Cool-down", systemImage: "wind")
                    Spacer()
                    Text("\(Int(day.cooldown.minutes)) min")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("\(day.label) · \(day.estimatedMinutes) min")
        }
    }
}
