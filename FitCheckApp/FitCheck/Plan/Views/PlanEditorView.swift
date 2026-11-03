//
//  PlanEditorView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// "Your plan": the days of the plan, each with warm-up, exercises and cool-down.
// Swipe an exercise to remove it, "Add exercises" opens the picker.
struct PlanEditorView: View {
    @State var viewModel: PlanEditorViewModel
    @State private var isSafetyInfoShown = false

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            if !viewModel.notices.isEmpty {
                Section {
                    ForEach(viewModel.notices, id: \.self) { notice in
                        Label(notice, systemImage: "info.circle")
                    }
                }
            }

            ForEach(viewModel.days.indices, id: \.self) { index in
                PlanDaySection(viewModel: viewModel, dayIndex: index)
            }
        }
        .navigationTitle("Your plan")
        .toolbar {
            // The safety text: always one tap away
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isSafetyInfoShown = true
                } label: {
                    Label("Safety", systemImage: "heart.text.square")
                }
            }
        }
        .alert("Safety", isPresented: $isSafetyInfoShown) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(SafetyRules.stopText)
        }
        .sheet(item: $viewModel.pickerRequest) { request in
            ExercisePickerView(
                viewModel: ExercisePickerViewModel(
                    pool: viewModel.pool,
                    selectedIds: viewModel.days[request.dayIndex].exercises.map { $0.id },
                    goal: viewModel.goalForPicker,
                    level: viewModel.levelForPicker
                ),
                onDone: { items in
                    viewModel.setExercises(items, inDay: request.dayIndex)
                }
            )
        }
    }
}
