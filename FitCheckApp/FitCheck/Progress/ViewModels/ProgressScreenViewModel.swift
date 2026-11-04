//
//  ProgressScreenViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// The ViewModel of the Progress screen: it owns the data and the logic, the View only draws.
// It loads the saved sessions (SessionRecord), keeps the period chosen by the user
// and asks ProgressStatsBuilder for the numbers of that period.
@Observable
final class ProgressScreenViewModel {
    // The completed workouts saved with SwiftData (empty until the workout screen saves them)
    private(set) var sessions: [SessionRecord] = []

    // The period chosen: the unit, and how far back for week, month, 3 months and year
    // (offset 0 = the current one, -1 = the one before, and so on).
    // The screen opens on last month: a finished month gives complete numbers.
    var unit: ProgressUnit = .month
    var offset = -1

    // The days chosen with the calendar (only used when the unit is custom)
    var customStart: Date = ProgressPeriodBuilder.today()
    var customEnd: Date? = nil

    // The sheet "Choose a period" and the screens opened from the Photos card
    var isPeriodSheetOpen = false
    var isGalleryOpen = false

    // The photos have their own ViewModel
    let photosViewModel = PhotosViewModel()

    private var context: ModelContext?

    // Called when the screen appears: loads the sessions and the photos
    func configure(context: ModelContext) {
        self.context = context
        photosViewModel.configure(context: context)
        reload()
    }

    func reload() {
        let descriptor = FetchDescriptor<SessionRecord>(sortBy: [SortDescriptor(\.date)])
        sessions = (try? context?.fetch(descriptor)) ?? []
    }

    // MARK: - The period

    var period: ProgressPeriod {
        if unit == .custom {
            return ProgressPeriodBuilder.custom(from: customStart, to: customEnd ?? customStart)
        }
        return ProgressPeriodBuilder.period(unit: unit, offset: offset)
    }

    // The text of the capsule, e.g. "Nov 2026"
    var capsuleTitle: String {
        ProgressPeriodBuilder.title(of: period)
    }

    // All the numbers of the screen for the chosen period
    var summary: ProgressSummary {
        ProgressStatsBuilder.summary(sessions: sessions, period: period)
    }

    // MARK: - The arrows of the capsule

    var canGoPrevious: Bool {
        if unit == .custom { return true }
        return -offset < ProgressPeriodBuilder.wheelCount(for: unit) - 1
    }

    var canGoNext: Bool {
        if unit == .custom { return period.end < ProgressPeriodBuilder.today() }
        return offset < 0
    }

    // One period back: the week before, the month before... (custom: the same number of days before)
    func goPrevious() {
        guard canGoPrevious else { return }
        if unit == .custom {
            shiftCustom(by: -1)
        } else {
            offset -= 1
        }
    }

    // One period forward (it stops at the current one)
    func goNext() {
        guard canGoNext else { return }
        if unit == .custom {
            shiftCustom(by: 1)
        } else {
            offset += 1
        }
    }

    private func shiftCustom(by direction: Int) {
        let length = period.dayCount
        let today = ProgressPeriodBuilder.today()
        var newEnd = ProgressPeriodBuilder.addDays(period.end, direction * length)
        if newEnd > today { newEnd = today }
        customEnd = newEnd
        customStart = ProgressPeriodBuilder.addDays(newEnd, -(length - 1))
    }

    // MARK: - The sheet "Choose a period"

    // The bars of the wheel (empty for custom)
    var wheelItems: [PeriodWheelItem] {
        guard unit != .custom else { return [] }
        return ProgressPeriodBuilder.periods(unit: unit).enumerated().map { index, period in
            PeriodWheelItem(
                id: index,
                label: ProgressPeriodBuilder.wheelLabel(of: period),
                minutes: ProgressStatsBuilder.minutes(in: period, from: sessions)
            )
        }
    }

    // The position of the chosen bar in the wheel
    var selectedWheelIndex: Int {
        ProgressPeriodBuilder.wheelCount(for: unit) - 1 + offset
    }

    // The user changed the unit (Week, Month, 3 months, Year, Custom)
    func selectUnit(_ newUnit: ProgressUnit) {
        if newUnit == .custom {
            // The calendar starts from the period that was on screen
            let current = period
            customStart = current.start
            customEnd = current.end
        }
        offset = 0
        unit = newUnit
    }

    // The user stopped the wheel on a bar
    func selectWheelIndex(_ index: Int) {
        let count = ProgressPeriodBuilder.wheelCount(for: unit)
        guard count > 0 else { return }
        let safeIndex = min(max(index, 0), count - 1)
        offset = safeIndex - (count - 1)
    }

    // The user tapped a day of the calendar: first tap = first day, second tap = last day
    func pickCustomDate(_ date: Date) {
        if customEnd != nil {
            customStart = date
            customEnd = nil
        } else if date < customStart {
            customStart = date
        } else {
            customEnd = date
        }
    }

    // The texts under the wheel: "Showing Nov 2026 · 13 sessions · 630 min"
    var sessionsText: String {
        let count = summary.sessionCount
        return count == 1 ? "1 session" : "\(count) sessions"
    }

    var minutesText: String {
        "\(summary.minutes) min"
    }
}
