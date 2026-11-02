//
//  ContentView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI

struct SummaryView: View {
    // The ViewModel owns the data: this View only draws it
    @State private var viewModel = SummaryViewModel()

    var body: some View {
        // The only GeometryReader of the screen: it measures the width of the device
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            ScrollView {
                VStack(spacing: 4 * unit) {
                    HomeHeaderView(
                        name: viewModel.userName,
                        doneThisWeek: viewModel.doneThisWeek,
                        plannedThisWeek: viewModel.plannedThisWeek,
                        unit: unit
                    )

                    WeekCardView(
                        days: viewModel.weekDays,
                        title: viewModel.weekTitle,
                        weekOffset: viewModel.weekOffset,
                        unit: unit,
                        onEdit: { viewModel.openEditWeek() },
                        onPreviousWeek: { viewModel.showPreviousWeek() },
                        onNextWeek: { viewModel.showNextWeek() }
                    )

                    // Today: show the workout if there is one, otherwise invite the user to add it
                    if let plan = viewModel.todayPlan {
                        TodayCardView(plan: plan, unit: unit, onStart: {})
                    } else {
                        TodayEmptyCardView(unit: unit, onAddPlan: {})
                    }

                    // Goals: with no goals this shows only the "Add goal" card
                    GoalsSectionView(goals: viewModel.goals, unit: unit, onSeeAll: {}, onAddGoal: {})

                    // My plans: with no plans this shows only the "Create your first plan" card
                    MyPlansSectionView(
                        plans: viewModel.plans,
                        unit: unit,
                        onNewPlan: {},
                        onOpenPlan: { _ in },
                        onEditPlan: { _ in }
                    )
                }
                .padding(6 * unit)
            }
        }
        .background(AppColors.background)
        // The pencil opens "Edit your week" over the Home: Back returns here
        .fullScreenCover(isPresented: $viewModel.isEditWeekOpen) {
            EditWeekView(
                week: viewModel.weekData,
                savedPlan: viewModel.savedWeekPlan,
                onBack: { viewModel.closeEditWeek() },
                onSave: { viewModel.saveWeek($0) }
            )
        }
    }
}

#Preview {
    SummaryView()
}
