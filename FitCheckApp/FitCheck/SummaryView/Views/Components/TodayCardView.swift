//
//  TodayCardView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 31/10/2026.
//

import SwiftUI

// BLOCK 3 - The yellow "Today" card: the workout of the day with a Start button.
// Every measure is a multiple of "unit" (1% of the screen width).

// MARK: - The card
struct TodayCardView: View {
    let plan: TodayPlan
    let unit: CGFloat   // 1% of the screen width
    let onStart: () -> Void   // what happens when the user taps Start

    // e.g. "67 min · 11 exercises"
    private var detailsText: String { "\(plan.minutes) min · \(plan.exerciseCount) exercises" }

    var body: some View {
        if let result = plan.result {
            // The workout is done: the card shows the results
            TodayDoneCardView(name: plan.name, result: result, unit: unit)
        } else {
            startCard
        }
    }

    // The yellow card with the Start button
    private var startCard: some View {
        HStack(spacing: AppSizes.Space.group * unit) {

            // Left side: label, plan name, details
            VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                // A plan sent with Go replaced the routine of today
                Text(plan.fromGo ? "TODAY · CHANGED" : "TODAY")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(.black.opacity(0.7))

                Text(plan.name)
                    .font(.system(size: AppSizes.Text.title * unit, weight: .bold))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(detailsText)
                    .font(.system(size: AppSizes.Text.body * unit, weight: .medium))
                    .foregroundStyle(.black.opacity(0.8))
                    .minimumScaleFactor(0.8)   // shrinks a little instead of wrapping
                    .lineLimit(1)
            }

            Spacer()

            // Right side: the Start button
            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppSizes.Space.screen * unit)
                    .padding(.vertical, 3.5 * unit)
                    .background(.black, in: Capsule())
            }
        }
        .padding(5 * unit)
        // The card stays yellow with black text in light and dark mode, so fixed black and white on purpose
        .background(AppColors.yellow, in: RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
    }
}

// MARK: - The card when the workout is done
// A green card with the results in three boxes: minutes, sets and the heaviest weight.
// It is always green: green means "done". Like the yellow Start card, it keeps black text
// in light and dark mode, so fixed black on purpose.
struct TodayDoneCardView: View {
    let name: String
    let result: TodayResult
    let unit: CGFloat   // 1% of the screen width

    // e.g. "TODAY · DONE · 09:47"
    private var labelText: String {
        guard let date = result.date else { return "TODAY · DONE" }
        return "TODAY · DONE · " + date.formatted(date: .omitted, time: .shortened)
    }

    // e.g. "80", "62.5" (no decimals when the weight is whole)
    private var topWeightText: String {
        guard let top = result.topWeight, top > 0 else { return "–" }
        return top.formatted(.number.precision(.fractionLength(0...1)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.group * unit) {

            // Label and plan name on the left, the check on the right
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSizes.Space.tight * unit) {
                    Text(labelText)
                        .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                        .foregroundStyle(.black.opacity(0.7))

                    Text(name)
                        .font(.system(size: AppSizes.Text.title * unit, weight: .bold))
                        .foregroundStyle(.black)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "checkmark")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                    .foregroundStyle(AppColors.green)
                    .frame(width: 8.5 * unit, height: 8.5 * unit)
                    .background(.black, in: Circle())
                    .accessibilityLabel("Workout done")
            }

            // The three boxes
            HStack(spacing: AppSizes.Space.related * unit) {
                box(value: "\(result.minutes)", label: "min")
                box(value: "\(result.sets)", label: "sets")
                box(value: topWeightText, label: "kg max")
            }
        }
        .padding(4.5 * unit)
        .frame(maxWidth: .infinity)
        .background(AppColors.green, in: RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
        .accessibilityElement(children: .combine)
    }

    // One box: a number with its label under it
    private func box(value: String, label: String) -> some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: 7 * unit, weight: .heavy))
                .foregroundStyle(.black)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.system(size: AppSizes.Text.caption * unit, weight: .semibold))
                .foregroundStyle(.black.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2.4 * unit)
        .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

// MARK: - The card when there is no workout yet
// Shown instead of TodayCardView when the user has not chosen a workout for today.
struct TodayEmptyCardView: View {
    let unit: CGFloat
    let onAddPlan: () -> Void   // what happens when the user taps "Add plan"

    var body: some View {
        HStack(spacing: AppSizes.Space.group * unit) {

            // Left side: label, message and hint, one under the other
            VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                Text("TODAY")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)

                Text("No workout yet")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("Add a plan to see it here")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }

            Spacer()

            // Right side: the button that invites the user to add a plan
            Button(action: onAddPlan) {
                Text("Add plan")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                    .foregroundStyle(AppColors.background)
                    .padding(.horizontal, AppSizes.Space.screen * unit)
                    .padding(.vertical, 3.5 * unit)
                    .background(AppColors.textPrimary, in: Capsule())
            }
        }
        .padding(5 * unit)
        // Dashed border: it says "something is missing here"
        .overlay(
            RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit)
                .strokeBorder(
                    AppColors.textSecondary,
                    style: StrokeStyle(lineWidth: 0.4 * unit, dash: [1 * unit, 0.8 * unit])
                )
        )
    }
}

// MARK: - Previews
// Sample data used only by the previews
// MARK: - Rest day
// Today is a rest day of the routine. The hint says how to train anyway (the Go swipe).
struct TodayRestCardView: View {
    let unit: CGFloat

    var body: some View {
        HStack(spacing: AppSizes.Space.group * unit) {
            VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
                Text("TODAY")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)

                Text("Rest day")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("Swipe a plan right to train anyway")
                    .font(.system(size: AppSizes.Text.body * unit, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "moon.zzz.fill")
                .font(.system(size: AppSizes.Text.display * unit))
                .foregroundStyle(AppColors.musclePurple)
        }
        .padding(5 * unit)
        .frame(maxWidth: .infinity)
        .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.large * unit))
    }
}

private let samplePlan = TodayPlan(name: "Full body A", minutes: 67, exerciseCount: 11)

// unit 3.9 = an iPhone that is 390 pt wide
#Preview("Light") {
    TodayCardView(plan: samplePlan, unit: 3.9, onStart: {})
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    TodayCardView(plan: samplePlan, unit: 3.9, onStart: {})
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("Rest day") {
    TodayRestCardView(unit: 3.9)
        .padding(20)
        .background(AppColors.background)
}

#Preview("No data") {
    TodayEmptyCardView(unit: 3.9, onAddPlan: {})
        .padding(20)
        .background(AppColors.background)
}

private let doneResult = TodayResult(minutes: 58, sets: 12, topWeight: 80, date: .now)

#Preview("Done dark") {
    TodayDoneCardView(name: "Full body A", result: doneResult, unit: 3.9)
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}

#Preview("Done") {
    TodayCardView(plan: TodayPlan(name: "Full body A", minutes: 67, exerciseCount: 11, result: doneResult),
                  unit: 3.9, onStart: {})
        .padding(20)
        .background(AppColors.background)
}
