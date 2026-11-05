//
//  RootPreviewData.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// MARK: - Sample data used ONLY by the previews of RootTabView
// The real app starts empty: nothing here is ever shown to the user.
// It fills an in-memory database with everything the two tabs read:
//  - Summary: the profile (name, week, rotation, goals), 4 plans with different colors,
//    and the exercises of exercises.json
//  - Progress: about 10 weeks of workouts and 6 photos (reused from ProgressPreviewData,
//    but linked to the sample plans below, so names and colors match)
enum RootPreviewData {

    // MARK: Plans
    // 4 plans, one color each (colorIndex = position in PlanPalette.colors).
    // The ids are fixed, so the rotation, Today and the sessions can point to them.
    static let plans: [PlanItem] = [
        makePlan(
            number: 1, name: "Chest and Back", icon: "figure.strengthtraining.traditional",
            colorIndex: 0, minutes: 60,
            exerciseIds: ["Butterfly", "Alternating_Floor_Press", "Bent_Over_Two-Dumbbell_Row", "Chin-Up"],
            sets: [3, 3, 3, 3], warmup: ["Arm_Circles", "Walking_Treadmill"]
        ),
        makePlan(
            number: 2, name: "Legs", icon: "figure.run",
            colorIndex: 1, minutes: 60,
            exerciseIds: ["Bodyweight_Squat", "Barbell_Step_Ups", "Butt_Lift_Bridge", "Calf_Press"],
            sets: [4, 3, 3, 3], warmup: ["Walking_Treadmill"]
        ),
        makePlan(
            number: 3, name: "Shoulders and Arms", icon: "dumbbell.fill",
            colorIndex: 4, minutes: 90,
            exerciseIds: ["Alternating_Deltoid_Raise", "Barbell_Curl", "Close-Grip_Dumbbell_Press", "Dumbbell_Shrug"],
            sets: [3, 3, 3, 2], warmup: ["Arm_Circles", "Walking_Treadmill"]
        ),
        makePlan(
            number: 4, name: "Core", icon: "figure.core.training",
            colorIndex: 5, minutes: 60,
            exerciseIds: ["Ab_Crunch_Machine", "Air_Bike", "Barbell_Ab_Rollout_-_On_Knees", "Alternate_Heel_Touchers"],
            sets: [3, 3, 3, 3], warmup: ["Walking_Treadmill"]
        )
    ]

    private static func makePlan(
        number: Int, name: String, icon: String, colorIndex: Int, minutes: Int,
        exerciseIds: [String], sets: [Int], warmup: [String]
    ) -> PlanItem {
        PlanItem(
            id: UUID(uuidString: "00000000-0000-0000-0000-00000000000\(number)") ?? UUID(),
            name: name,
            icon: icon,
            color: PlanPalette.colors[colorIndex],
            exerciseCount: exerciseIds.count,
            minutes: minutes,
            exerciseIds: exerciseIds,
            colorIndex: colorIndex,
            exerciseSets: sets,
            warmupMoves: warmup,
            hasCooldown: true,
            hasWarmup: true
        )
    }

    // MARK: Week
    // Monday, Wednesday and Friday, plus the weekday of today, so the Today card always shows a workout.
    // (1 = Sunday ... 7 = Saturday)
    static func trainingWeekdays() -> [Int] {
        var days = [2, 4, 6]
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        if !days.contains(todayWeekday) {
            days.append(todayWeekday)
        }
        return days.sorted()
    }

    // One plan for each training day, in order: the rotation shown in Edit week
    static func rotation() -> [RotationSlot] {
        trainingWeekdays().enumerated().map { position, weekday in
            RotationSlot(weekday: weekday, planId: plans[position % 3].id)
        }
    }

    // MARK: Profile
    static func profile() -> AppProfile {
        let profile = AppProfile()
        profile.userName = "Peppino"

        let weekdays = trainingWeekdays()
        profile.plannedWeekdays = weekdays
        profile.restWeekdays = [2, 3, 4, 5, 6, 7, 1].filter { !weekdays.contains($0) }

        // The days with a completed workout (at midnight) come from the sample sessions
        let calendar = Calendar.current
        var days: [Date] = []
        for session in sessions() {
            let day = calendar.startOfDay(for: session.date)
            if !days.contains(day) {
                days.append(day)
            }
        }
        profile.completedDays = days

        // The saved "Edit your week": days, duration, one reminder and the rotation
        profile.hasSavedWeekPlan = true
        profile.draftWorkoutWeekdays = weekdays
        profile.draftDurationMinutes = 60
        profile.draftRemindMe = true
        profile.draftReminderWeekdays = weekdays
        profile.draftReminderMinutes = weekdays.map { _ in 18 * 60 }   // 18:00
        profile.draftRotationWeekdays = rotation().map { $0.weekday }
        profile.draftRotationPlanIds = rotation().map { $0.planId?.uuidString ?? "" }

        // Goals progress (weekly and monthly)
        profile.sessionsDone = 2
        profile.minutesDone = 105
        profile.strengthDaysDone = 2
        profile.weeksActive = 4
        profile.planWorkoutsDone = 9
        profile.planWorkoutsPlanned = 12
        profile.musclesCovered = 5

        return profile
    }

    // MARK: Sessions and photos (for Progress)
    // The sessions of ProgressPreviewData, with the name, the id and the color of the sample plans
    static func sessions() -> [SessionRecord] {
        let sourcePlans = Array(plans.prefix(3))
        return ProgressPreviewData.sessions().map { session in
            let plan = sourcePlans[session.colorIndex % sourcePlans.count]
            session.planId = plan.id.uuidString
            session.planName = plan.name
            session.colorIndex = plan.colorIndex ?? 0
            return session
        }
    }
}

// MARK: - The in-memory database of the RootTabView previews (it is not saved on the phone)
// withData: true  -> exercises, profile, plans, sessions and photos
// withData: false -> empty, like the very first launch of the app
@MainActor
func rootPreviewContainer(withData: Bool) -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Exercise.self, AppProfile.self, PlanRecord.self, SessionRecord.self, PhotoRecord.self,
        configurations: configuration
    )
    guard withData else { return container }

    let context = container.mainContext
    ExerciseImporter.importIfNeeded(into: context)
    context.insert(RootPreviewData.profile())
    for plan in RootPreviewData.plans {
        context.insert(PlanRecord(from: plan))
    }
    for session in RootPreviewData.sessions() {
        context.insert(session)
    }
    for photo in ProgressPreviewData.photos() {
        context.insert(photo)
    }
    return container
}
