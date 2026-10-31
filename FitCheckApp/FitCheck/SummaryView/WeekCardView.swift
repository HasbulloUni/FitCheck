//
//  WeekCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// MARK: - Stato di un giorno
// Decides how the circle is drawn.
enum DayState {
    case done       // workout done: green circle
    case rest       // rest day: purple circle
    case today      // today: dashed circle
    case planned    // scheduled workout (future): filled gray circle
    case upcoming   // every other day: outline only
}

// MARK: - A day to display
// Data only, no logic.
struct WeekDay: Identifiable {
    let id = UUID()
    let letter: String   // "M", "T", "W"...
    let date: Date       // the actual date
    let state: DayState  // how it should be drawn

    // The day of the month (e.g. 29), written inside the circle.
    var number: Int {
        Calendar.current.component(.day, from: date)
    }
}

// MARK: - Week data
// Starts empty: the only thing it has is "today".
struct WeekData {
    // Training days chosen by the user (1 = Sunday, 2 = Monday ... 7 = Saturday)
    var plannedWeekdays: [Int] = []
    // Rest days chosen by the user (same numbers)
    var restWeekdays: [Int] = []
    // Completed workouts (dates at midnight)
    var completedDays: [Date] = []
    // Rest days already recorded (dates at midnight)
    var restDays: [Date] = []
    // The current day
    var today: Date = .now

    // Builds the 7 days of the week containing "today", Monday through Sunday.
    func days() -> [WeekDay] {
        var cal = Calendar.current
        cal.firstWeekday = 2   // the week always starts on Monday

        // The Monday of the week that contains today
        guard let start = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }

        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        let todayStart = cal.startOfDay(for: today)

        
        
        var result: [WeekDay] = []
        for (offset, letter) in letters.enumerated() {
            // Monday + offset days = the date of this day
            guard let date = cal.date(byAdding: .day, value: offset, to: start) else { continue }

            // Which day of the week it is (1 = Sunday ... 7 = Saturday)
            let weekday = cal.component(.weekday, from: date)

            let item = WeekDay(
                letter: letter,
                date: date,
                state: state(of: date, weekday: weekday, todayStart: todayStart)
            )
            result.append(item)
        }

        return result
    }

    // The state of a day: the first check that matches wins.
    private func state(of date: Date, weekday: Int, todayStart: Date) -> DayState {
        let day = Calendar.current.startOfDay(for: date)
        
        
        if day == todayStart {
            return .today
        }
        if completedDays.contains(day) {
            return .done
        }
        if day > todayStart && plannedWeekdays.contains(weekday) {
            return .planned
        }
        if restWeekdays.contains(weekday) || restDays.contains(day) {
            return .rest
        }
        return .upcoming
    }
}

// MARK: - The card
struct WeekCardView: View {
    let days: [WeekDay]
    let onEdit: () -> Void   // what happens when the pencil is tapped

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Title row with the pencil on the right
            HStack {
                Text("This week")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(10)
                        .background(AppColors.cardAlt, in: Circle())
                }
            }

            // Row with the 7 days, all the same width
            HStack {
                ForEach(days) { day in
                    DayCircleView(day: day)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - A single day
// Circle with the number inside and the letter below.
struct DayCircleView: View {
    let day: WeekDay

    // Circle diameter: scales with the iPhone's text size.
    @ScaledMetric private var size: CGFloat = 40

    var body: some View {
        VStack(spacing: 6) {

            // The circle: fill + border + number, stacked on top of each other
            ZStack {
                Circle().fill(fillColor)
                Circle().strokeBorder(borderColor, style: borderStyle)
                Text("\(day.number)")
                    .font(.footnote.bold())
                    .foregroundStyle(numberColor)
            }
            .frame(width: size, height: size)

            // The letter below, bold only for today
            Text(day.letter)
                .font(.caption)
                .fontWeight(day.state == .today ? .bold : .regular)
                .foregroundStyle(day.state == .today ? AppColors.textPrimary : AppColors.textSecondary)
        }
    }

    // Fill color of the circle
    private var fillColor: Color {
        switch day.state {
        case .done:     return AppColors.green
        case .rest:     return AppColors.musclePurple
        case .planned:  return AppColors.divider
        case .today:    return .clear
        case .upcoming: return .clear
        }
    }

    // Border color
    private var borderColor: Color {
        switch day.state {
        case .today:    return AppColors.textPrimary
        case .upcoming: return AppColors.divider
        default:        return .clear
        }
    }

    // Border style: dashed only for today
    private var borderStyle: StrokeStyle {
        if day.state == .today {
            return StrokeStyle(lineWidth: 2, dash: [4, 3])
        }
        return StrokeStyle(lineWidth: 1.5)
    }

    // Number color: readable on every background
    private var numberColor: Color {
        switch day.state {
        case .done, .rest:         return .white
        case .today:               return AppColors.textPrimary
        case .planned, .upcoming:  return AppColors.textSecondary
        }
    }
}

// MARK: - Previews
// Sample data: Thursday, October 29, 2026, Monday already done.
private let sampleData: WeekData = {
    let cal = Calendar.current
    var data = WeekData()
    data.today = cal.date(from: DateComponents(year: 2026, month: 10, day: 29))!
    data.plannedWeekdays = [2, 3, 6]      // Mon, Tue, Fri
    data.restWeekdays = [4, 5, 7, 1]      // Wed, Thu, Sat, Sun
    data.completedDays = [cal.date(from: DateComponents(year: 2026, month: 10, day: 26))!]
    return data
}()

#Preview("Chiaro") {
    WeekCardView(days: sampleData.days(), onEdit: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Scuro") {
    WeekCardView(days: sampleData.days(), onEdit: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
