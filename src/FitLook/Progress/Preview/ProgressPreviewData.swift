//
//  ProgressPreviewData.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// MARK: - Sample data used ONLY by the previews
// The real screens start empty: nothing here is ever shown to the user.
enum ProgressPreviewData {

    // About 10 weeks of workouts: Monday, Wednesday, Friday and some Saturdays.
    // The weights go up with time, so there are load gains to show.
    static func sessions() -> [SessionRecord] {
        let today = ProgressPeriodBuilder.today()
        let planNames = ["Full body A", "Full body B", "Full body C"]
        var result: [SessionRecord] = []
        var planNumber = 0

        // From the oldest day to today
        for daysBack in stride(from: 70, through: 0, by: -1) {
            let date = ProgressPeriodBuilder.addDays(today, -daysBack)
            let weekday = ProgressFormat.weekdayIndex(date)   // Monday = 0
            let isTrainingDay = weekday == 0 || weekday == 2 || weekday == 4 || (weekday == 5 && daysBack % 2 == 0)
            guard isTrainingDay else { continue }

            let plan = planNumber % planNames.count
            planNumber += 1

            // The weights grow by 2.5 kg every two weeks
            let growth = Double((70 - daysBack) / 14) * 2.5

            result.append(
                SessionRecord(
                    date: date,
                    planId: "preview-plan-\(plan)",
                    planName: planNames[plan],
                    colorIndex: plan,
                    minutes: 45 + (daysBack * 7) % 25,
                    muscleNames: MuscleGroup.allCases.map { $0.rawValue },
                    muscleSets: [4 + plan, 4, 6 - plan, 3, 2 + plan, 2],
                    loadExerciseIds: ["hip-thrust", "back-squat", "bench-press"],
                    loadExerciseNames: ["Hip thrust", "Back squat", "Bench press"],
                    loadWeights: [60 + growth * 2, 50 + growth * 1.5, 40 + growth]
                )
            )
        }
        return result
    }

    // The period used by the previews: the last 30 days
    private static var previewPeriod: ProgressPeriod {
        let today = ProgressPeriodBuilder.today()
        return ProgressPeriodBuilder.custom(from: ProgressPeriodBuilder.addDays(today, -29), to: today)
    }

    // The numbers of the sample sessions
    static func summary() -> ProgressSummary {
        ProgressStatsBuilder.summary(sessions: sessions(), period: previewPeriod)
    }

    // The numbers when there are no sessions
    static func emptySummary() -> ProgressSummary {
        ProgressStatsBuilder.summary(sessions: [], period: previewPeriod)
    }

    // The bars of the month wheel, with and without sessions
    static func wheelItems() -> [PeriodWheelItem] {
        let all = sessions()
        return ProgressPeriodBuilder.periods(unit: .month).enumerated().map { index, period in
            PeriodWheelItem(
                id: index,
                label: ProgressPeriodBuilder.wheelLabel(of: period),
                minutes: ProgressStatsBuilder.minutes(in: period, from: all)
            )
        }
    }

    static func emptyWheelItems() -> [PeriodWheelItem] {
        wheelItems().map { PeriodWheelItem(id: $0.id, label: $0.label, minutes: 0) }
    }

    // A plain grey picture, used instead of a real photo
    static func thumbnailData(grey: CGFloat = 0.7) -> Data {
        let size = CGSize(width: 90, height: 120)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(white: grey, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(white: grey - 0.25, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 30, y: 24, width: 30, height: 30))
            context.cgContext.fillEllipse(in: CGRect(x: 15, y: 62, width: 60, height: 80))
        }
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    // 6 sample photos, one a week
    static func photos() -> [PhotoRecord] {
        let today = ProgressPeriodBuilder.today()
        return (0..<6).map { number in
            let data = thumbnailData(grey: 0.45 + CGFloat(number) * 0.08)
            return PhotoRecord(
                date: ProgressPeriodBuilder.addDays(today, -7 * (5 - number)),
                imageData: data,
                thumbnailData: data
            )
        }
    }

    static func photosViewModel(withData: Bool) -> PhotosViewModel {
        PhotosViewModel(previewPhotos: withData ? photos() : [])
    }
}

// An in-memory database for the previews of the Progress screen (it is not saved on the phone)
func progressPreviewContainer(withData: Bool) -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Exercise.self, AppProfile.self, PlanRecord.self, SessionRecord.self, PhotoRecord.self,
        configurations: configuration
    )
    if withData {
        for session in ProgressPreviewData.sessions() {
            container.mainContext.insert(session)
        }
        for photo in ProgressPreviewData.photos() {
            container.mainContext.insert(photo)
        }
    }
    return container
}
