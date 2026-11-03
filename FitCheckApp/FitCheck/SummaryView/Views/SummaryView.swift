//
//  ContentView.swift
//  Butterflyteam
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    // The ViewModel owns the data: this View only draws it
    @State private var viewModel = SummaryViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        // The NavigationStack lets Edit week open INSIDE the tab:
        // the navbar (RootTabView) stays visible and Back returns to the Home
        NavigationStack {
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
                        TodayEmptyCardView(unit: unit, onAddPlan: { viewModel.openAddPlan() })
                    }

                    // Goals: the 3 goals of the week and the 3 of the month (no separate screen)
                    GoalsSectionView(
                        weekGoals: viewModel.goalsViewModel.weekGoals,
                        monthGoals: viewModel.goalsViewModel.monthGoals,
                        unit: unit
                    )

                    // My plans: with no plans this shows only the "Create your first plan" card
                    MyPlansSectionView(
                        plans: viewModel.plans,
                        unit: unit,
                        onNewPlan: { viewModel.openAddPlan() },
                        onOpenPlan: { _ in },
                        onEditPlan: { _ in },
                        onDeletePlan: { viewModel.deletePlan($0) },
                        onStartPlan: { _ in }
                    )
                }
                .padding(6 * unit)
            }
        }
        .background(AppColors.background)
        .onAppear { viewModel.configure(context: modelContext) }
        // The pencil opens "Edit your week": Back returns here
        .navigationDestination(isPresented: $viewModel.isEditWeekOpen) {
            EditWeekView(
                week: viewModel.weekData,
                savedPlan: viewModel.savedWeekPlan,
                onBack: { viewModel.closeEditWeek() },
                onSave: { viewModel.saveWeek($0) }
            )
            .navigationBarBackButtonHidden(true)   // the screens have their own Back
            .toolbar(.hidden, for: .navigationBar)
        }
        // "+ New plan" and "Add plan" open "Add your plan": Back returns here
        .navigationDestination(isPresented: $viewModel.isAddPlanOpen) {
            AddPlanView(
                takenColorIndexes: viewModel.plans.compactMap { $0.colorIndex },
                onBack: { viewModel.closeAddPlan() },
                onSave: { viewModel.addPlan($0) }
            )
            .navigationBarBackButtonHidden(true)   // the screens have their own Back
            .toolbar(.hidden, for: .navigationBar)
        }
        // The Home has its own header: no system title bar
        .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    SummaryView()
        .modelContainer(planPreviewContainer(withData: true))
}
