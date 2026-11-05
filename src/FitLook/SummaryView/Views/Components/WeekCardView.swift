//
//  WeekCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// MARK: - The card
struct WeekCardView: View {
    let days: [WeekDay]
    let title: String        // "This week", "Next week"...
    let weekOffset: Int      // 0 = this week: used to animate the change of week
    let unit: CGFloat   // 1% of the screen width
    let onEdit: () -> Void   // what happens when the pencil is tapped
    let onPreviousWeek: () -> Void   // swipe to the right
    let onNextWeek: () -> Void       // swipe to the left

    // Moves the days a little to the left and back, to show that the card can be swiped
    @State private var hintOffset: CGFloat = 0

    // The direction of the last swipe: the new week slides in from this side
    @State private var goesForward = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {

            // Title row with the pencil button on the right
            HStack {
                Text(title)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: AppSizes.Text.small * unit, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(2.5 * unit)
                        .background(AppColors.cardAlt, in: Circle())
                }
            }

            // The 7 days, each one gets the same width
            HStack {
                ForEach(days) { day in
                    DayCircleView(day: day, unit: unit)
                        .frame(maxWidth: .infinity)
                }
            }
            .id(weekOffset)
            .transition(.push(from: goesForward ? .trailing : .leading))
            .offset(x: hintOffset)
            // The whole area of the days can be swiped, also the empty spaces between the circles
            .frame(maxWidth: .infinity)
            .clipped()   // the week that slides out does not leave the card
            .contentShape(Rectangle())
            // Swipe left: next week. Swipe right: the previous week.
            .simultaneousGesture(
                DragGesture(minimumDistance: 15).onEnded { drag in
                    // The weeks slide with a smooth animation, in the direction of the swipe
                    if drag.translation.width < -30 {
                        goesForward = true
                        withAnimation(.smooth(duration: 0.4)) { onNextWeek() }
                    } else if drag.translation.width > 30 {
                        goesForward = false
                        withAnimation(.smooth(duration: 0.4)) { onPreviousWeek() }
                    }
                }
            )
        }
        .task { await showSwipeHint() }
        .padding(4.5 * unit)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
    }
}

// MARK: - The swipe hint
extension WeekCardView {
    // When the card appears, the days slide a little to the left and come back.
    // It is a hint for the user: "swipe to see the next weeks".
    func showSwipeHint() async {
        try? await Task.sleep(for: .seconds(0.8))
        withAnimation(.easeInOut(duration: 0.35)) {
            hintOffset = -4 * unit
        }
        try? await Task.sleep(for: .seconds(0.35))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            hintOffset = 0
        }
    }
}

// MARK: - A single day
// Circle with the number inside and the letter below.
struct DayCircleView: View {
    let day: WeekDay
    let unit: CGFloat   // 1% of the screen width

    var body: some View {
        VStack(spacing: AppSizes.Space.related * unit) {
            // Fill + border + number, one on top of the other
            ZStack {
                Circle().fill(fillColor)
                Circle().strokeBorder(borderColor, style: borderStyle)
                if day.state == .done && Calendar.current.isDateInToday(day.date) {
                    // The workout of today is done: a check mark instead of the number
                    Image(systemName: "checkmark")
                        .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .heavy))
                        .foregroundStyle(numberColor)
                        .accessibilityLabel("Workout done today")
                } else {
                    Text("\(day.number)")
                        .font(.system(size: AppSizes.Text.body * unit, weight: .bold))
                        .foregroundStyle(numberColor)
                        // A soft shadow under the number, so it stands out from the circle
                        .shadow(color: .black.opacity(0.35), radius: 0.6 * unit, x: 0, y: 0.3 * unit)
                }
            }
            .frame(width: 10 * unit, height: 10 * unit)

            // The letter below, bold only for today
            // Today stays bold, also when its circle is already green (workout done)
            let isTodayDate = Calendar.current.isDateInToday(day.date)
            Text(day.letter)
                .font(.system(size: AppSizes.Text.small * unit, weight: isTodayDate ? .bold : .regular))
                .foregroundStyle(isTodayDate ? AppColors.textPrimary : AppColors.textSecondary)
        }
    }

    // Fill color of the circle
    private var fillColor: Color {
        switch day.state {
        case .done:     return doneColor
        case .rest:     return AppColors.restBlue
        case .planned:  return (plannedColor ?? AppColors.divider).opacity(plannedOpacity)
        case .todayWorkout: return (plannedColor ?? AppColors.green).opacity(0.25)
        case .todayRest:    return AppColors.restBlue.opacity(0.25)
        case .today:        return .clear
        case .upcoming:     return .clear
        }
    }

    // A planned future day keeps its plan color but more transparent: it is not done yet
    private let plannedOpacity = 0.4

    // A day done takes the color of its plan (green when the plan is not known)
    private var doneColor: Color {
        guard let index = day.colorIndex, PlanPalette.colors.indices.contains(index) else { return AppColors.green }
        return PlanPalette.colors[index]
    }

    // A day still to do takes the color of the plan the rotation gives it (nil when it is not known)
    private var plannedColor: Color? {
        guard let index = day.plannedColorIndex, PlanPalette.colors.indices.contains(index) else { return nil }
        return PlanPalette.colors[index]
    }

    // Border color
    private var borderColor: Color {
        switch day.state {
        case .todayWorkout: return plannedColor ?? AppColors.green
        case .todayRest:    return AppColors.restBlue
        case .today:        return AppColors.textPrimary
        case .upcoming: return AppColors.divider
        default:        return .clear
        }
    }

    // Dashed border only for today
    private var borderStyle: StrokeStyle {
        if day.state.isToday {
            return StrokeStyle(lineWidth: 0.5 * unit, dash: [1 * unit, 0.8 * unit])
        }
        return StrokeStyle(lineWidth: 0.4 * unit)
    }

    // Number color: readable on every background
    private var numberColor: Color {
        switch day.state {
        case .done:                return day.colorIndex == nil ? .white : .black   // black reads well on every plan color
        case .rest:                return Color.white
        case .today, .todayWorkout, .todayRest: return AppColors.textPrimary
        case .planned:             return plannedColor == nil ? AppColors.textSecondary : AppColors.textPrimary   // soft like the fill, readable in light and dark
        case .upcoming:            return AppColors.textSecondary
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

// unit 3.9 = an iPhone that is 390 pt wide
#Preview("Light") {
    WeekCardView(days: sampleData.days(), title: "This week", weekOffset: 0, unit: 3.9,
                 onEdit: {}, onPreviousWeek: {}, onNextWeek: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    WeekCardView(days: sampleData.days(), title: "This week", weekOffset: 0, unit: 3.9,
                 onEdit: {}, onPreviousWeek: {}, onNextWeek: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
