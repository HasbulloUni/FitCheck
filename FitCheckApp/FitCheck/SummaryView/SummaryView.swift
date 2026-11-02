//
//  ContentView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct SummaryView: View {
    // Week data: starts empty, it only knows the current day
    @State private var weekData = WeekData()

    // The name of the user: empty until the user sets it
    @State private var userName = ""

    // Today's workout: nil means the user has not added one yet
    @State private var todayPlan: TodayPlan? = nil

    // Goals chosen by the user: empty at the start
    @State private var goals: [GoalItem] = []

    // Plans created by the user: empty at the start
    @State private var plans: [PlanItem] = []

    var body: some View {
        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ScrollView {
                VStack(spacing: 4 * unit) {
                    HomeHeaderView(
                        name: userName,
                        doneThisWeek: weekData.days().filter { $0.state == .done }.count,
                        plannedThisWeek: weekData.plannedWeekdays.count,
                        unit: unit
                    )

                    WeekCardView(days: weekData.days(), unit: unit, onEdit: {})

                    // Today: show the workout if there is one, otherwise invite the user to add it
                    if let plan = todayPlan {
                        TodayCardView(plan: plan, unit: unit, onStart: {})
                    } else {
                        TodayEmptyCardView(unit: unit, onAddPlan: {})
                    }

                    // Goals: with no goals this shows only the "Add goal" card
                    GoalsSectionView(goals: goals, unit: unit, onSeeAll: {}, onAddGoal: {})

                    // My plans: with no plans this shows only the "Create your first plan" card
                    MyPlansSectionView(
                        plans: plans,
                        unit: unit,
                        onNewPlan: {},
                        onOpenPlan: { _ in },
                        onEditPlan: { _ in }
                    )
                }
                .padding(5 * unit)
            }
        }
        .background(AppColors.background)
    }
}

#Preview {
    SummaryView()
}
