//
//  CustomRangeCalendarView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The calendar of "Custom": tap the first day, then the last day. The days in between are shaded.
// Days after today cannot be chosen. Only drawing: it tells which day was tapped.
struct CustomRangeCalendarView: View {
    let start: Date
    let end: Date?              // nil while only the first day is chosen
    let unit: CGFloat
    let onPick: (Date) -> Void

    // The month on screen (the first day of the month)
    @State private var month: Date

    init(start: Date, end: Date?, unit: CGFloat, onPick: @escaping (Date) -> Void) {
        self.start = start
        self.end = end
        self.unit = unit
        self.onPick = onPick
        _month = State(initialValue: ProgressPeriodBuilder.monthStart(of: end ?? start))
    }

    private var today: Date { ProgressPeriodBuilder.today() }
    private var canShowNextMonth: Bool {
        ProgressPeriodBuilder.addMonths(month, 1) <= today
    }

    var body: some View {
        VStack(spacing: AppSizes.Space.related * unit) {
            header
            weekdayNames
            days
        }
        .padding(AppSizes.Space.group * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }

    // MARK: - Month and arrows

    private var header: some View {
        HStack {
            monthButton(systemName: "chevron.left", isEnabled: true, label: "Previous month") {
                month = ProgressPeriodBuilder.addMonths(month, -1)
            }

            Spacer()

            Text(ProgressFormat.monthNameYear(month))
                .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            monthButton(systemName: "chevron.right", isEnabled: canShowNextMonth, label: "Next month") {
                month = ProgressPeriodBuilder.addMonths(month, 1)
            }
        }
    }

    private func monthButton(systemName: String, isEnabled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 8 * unit, height: 8 * unit)
                .background(AppColors.cardAlt, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.3)
        .accessibilityLabel(label)
    }

    // MARK: - M T W T F S S

    private var weekdayNames: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                Text(String(ProgressFormat.weekdayShort(index).prefix(1)))
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - The days

    private var days: some View {
        let cells = ProgressPeriodBuilder.calendarCells(for: month)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: AppSizes.Space.tight * unit) {
            ForEach(cells.indices, id: \.self) { index in
                if let date = cells[index] {
                    dayCell(date)
                } else {
                    Color.clear.frame(height: 9 * unit)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let isStart = ProgressPeriodBuilder.isSameDay(date, start)
        let isEnd = end.map { ProgressPeriodBuilder.isSameDay(date, $0) } ?? false
        let isBetween = end.map { date > start && date < $0 } ?? false
        let isFuture = date > today
        let isEdge = isStart || isEnd

        // The shaded band behind the days of the range: it starts at the first day and stops at the last
        let bandLeft = isBetween || (isEnd && !isStart)
        let bandRight = isBetween || (isStart && end != nil && !isEnd)

        return Button(action: { onPick(date) }) {
            ZStack {
                HStack(spacing: 0) {
                    Rectangle().fill(bandLeft ? AppColors.cardAlt : Color.clear)
                    Rectangle().fill(bandRight ? AppColors.cardAlt : Color.clear)
                }

                Text("\(ProgressPeriodBuilder.calendar.component(.day, from: date))")
                    .font(.system(size: AppSizes.Text.body * unit, weight: isEdge ? .heavy : .semibold))
                    .foregroundStyle(isEdge ? AppColors.background : AppColors.textPrimary)
                    .frame(width: 8 * unit, height: 8 * unit)
                    .background(isEdge ? AppColors.textPrimary : Color.clear, in: Circle())
            }
            .frame(height: 9 * unit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
        .opacity(isFuture ? 0.3 : 1)
    }
}

#Preview("Light") {
    let today = ProgressPeriodBuilder.today()
    CustomRangeCalendarView(
        start: ProgressPeriodBuilder.addDays(today, -9),
        end: today,
        unit: 3.9,
        onPick: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
}

#Preview("Dark") {
    let today = ProgressPeriodBuilder.today()
    CustomRangeCalendarView(
        start: ProgressPeriodBuilder.addDays(today, -9),
        end: today,
        unit: 3.9,
        onPick: { _ in }
    )
    .padding(20)
    .background(AppColors.background)
    .preferredColorScheme(.dark)
}

#Preview("No data") {
    // Only the first day is chosen
    CustomRangeCalendarView(start: ProgressPeriodBuilder.today(), end: nil, unit: 3.9, onPick: { _ in })
        .padding(20)
        .background(AppColors.background)
}
