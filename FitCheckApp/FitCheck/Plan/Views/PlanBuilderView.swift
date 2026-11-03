//
//  PlanBuilderView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI
import SwiftData

// "New plan": the user picks a few things and the app creates a safe plan.
// Only native iPhone components: Form, Picker and a prominent button.
struct PlanBuilderView: View {
    @Query private var exercises: [Exercise]
    @State private var viewModel = PlanBuilderViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Group {
                if viewModel.isCatalogReady {
                    Form {
                        Section {
                            Picker("Category", selection: $viewModel.category) {
                                ForEach(PlanCategory.allCases) { category in
                                    Text(category.title).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Section {
                            Picker("Goal", selection: $viewModel.goal) {
                                ForEach(PlanGoal.allCases) { goal in
                                    Text(goal.title).tag(goal)
                                }
                            }
                            Picker("Level", selection: $viewModel.level) {
                                ForEach(PlanLevel.allCases) { level in
                                    Text(level.title).tag(level)
                                }
                            }
                            Picker("Days a week", selection: $viewModel.daysPerWeek) {
                                ForEach(viewModel.daysOptions, id: \.self) { days in
                                    Text("\(days)").tag(days)
                                }
                            }
                            Picker("Length", selection: $viewModel.minutes) {
                                ForEach(viewModel.minutesOptions, id: \.self) { minutes in
                                    Text("\(minutes) min").tag(minutes)
                                }
                            }
                            Picker("Split", selection: $viewModel.style) {
                                ForEach(viewModel.availableStyles) { style in
                                    Text(style.title).tag(style)
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)
                } else {
                    // The exercises are not in the database
                    ContentUnavailableView(
                        "No exercises",
                        systemImage: "dumbbell",
                        description: Text("The exercise list is empty.")
                    )
                }
            }
            .navigationTitle("New plan")
            .safeAreaInset(edge: .bottom) {
                if viewModel.isCatalogReady {
                    Button {
                        viewModel.createPlan()
                    } label: {
                        Text("Create plan")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding()
                }
            }
            .navigationDestination(isPresented: $viewModel.isEditorShown) {
                if let editor = viewModel.editor {
                    PlanEditorView(viewModel: editor)
                }
            }
            .onAppear { viewModel.loadCatalog(from: exercises) }
            .onChange(of: exercises.count) { viewModel.loadCatalog(from: exercises) }
            .onChange(of: viewModel.daysPerWeek) { viewModel.keepStyleValid() }
        }
    }
}

// MARK: - Previews
// The preview database lives in memory: "With data" fills it from exercises.json.
@MainActor
func planPreviewContainer(withData: Bool) -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: configuration)
    if withData {
        ExerciseImporter.importIfNeeded(into: container.mainContext)
    }
    return container
}

#Preview("Light") {
    PlanBuilderView()
        .modelContainer(planPreviewContainer(withData: true))
}

#Preview("Dark") {
    PlanBuilderView()
        .modelContainer(planPreviewContainer(withData: true))
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    PlanBuilderView()
        .modelContainer(planPreviewContainer(withData: false))
}
