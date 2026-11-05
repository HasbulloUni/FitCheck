//
//  WorkoutPreviewData.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// Sample data used ONLY by the previews of the workout screens (never by the app).
enum WorkoutPreviewData {

    static let plan = PlanItem(
        id: UUID(), name: "Legs day", icon: "figure.run", color: PlanPalette.colors[0],
        exerciseCount: 2, minutes: 60, colorIndex: 0
    )

    static let steps: [WorkoutStep] = [
        WorkoutStep(id: 0, kind: .warmup, exerciseId: "Walking_Treadmill", name: "Walking treadmill",
                    muscles: "Legs · Quadriceps", muscleGroup: "legs", imagePaths: [],
                    instructions: ["Walk at an easy pace."], setCount: 0,
                    durationSeconds: WorkoutRules.treadmillSeconds),
        WorkoutStep(id: 1, kind: .exercise, exerciseId: "Barbell_Squat", name: "Back squat",
                    muscles: "Legs · Quadriceps", muscleGroup: "legs", imagePaths: [],
                    instructions: ["Set the bar on your upper back, feet shoulder width apart.",
                                   "Bend knees and hips until your thighs are parallel to the floor.",
                                   "Push through your heels to stand up."],
                    setCount: 3, durationSeconds: 0),
        WorkoutStep(id: 2, kind: .exercise, exerciseId: "Leg_Press", name: "Leg press",
                    muscles: "Legs · Quadriceps", muscleGroup: "legs", imagePaths: [],
                    instructions: ["Sit with your back flat on the pad.",
                                   "Push the platform away without locking your knees."],
                    setCount: 3, durationSeconds: 0),
        WorkoutStep(id: 3, kind: .cooldown, exerciseId: "", name: "Cool-down stretching",
                    muscles: "Whole body", muscleGroup: "", imagePaths: [],
                    instructions: ["Stretch slowly and never force."],
                    setCount: 0, durationSeconds: WorkoutRules.cooldownSeconds)
    ]

    static let summary = WorkoutSummary(
        minutes: 58, setsDone: 6, exercisesDone: 2, exercisesTotal: 2, isCompleted: true,
        loads: [
            WorkoutSummary.LoadLine(id: "Barbell_Squat", name: "Back squat", weight: 62.5, previous: 60),
            WorkoutSummary.LoadLine(id: "Leg_Press", name: "Leg press", weight: 120, previous: 120)
        ]
    )

    // A ViewModel with the steps above, standing on the exercise (step 1)
    @MainActor
    static func viewModel(onStep step: Int = 1) -> WorkoutViewModel {
        let viewModel = WorkoutViewModel(plan: plan)
        viewModel.loadPreview(steps: steps, previousWeights: ["Barbell_Squat": 60])
        for _ in 0..<step { viewModel.nextStep() }
        return viewModel
    }
}
