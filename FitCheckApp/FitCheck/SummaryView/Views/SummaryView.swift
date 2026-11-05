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
                VStack(spacing: AppSizes.Space.section * unit) {
                    HomeHeaderView(
                        name: viewModel.userName,
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
                        TodayCardView(plan: plan, unit: unit, onStart: { viewModel.startToday() })
                    } else if viewModel.isTodayRest {
                        TodayRestCardView(unit: unit)
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
                        onReadyMade: { viewModel.openReadyMade() },
                        onDeleteAllPlans: { viewModel.deleteAllPlans() },
                        onOpenPlan: { viewModel.openEditPlan($0) },
                        onEditPlan: { viewModel.openEditPlan($0) },
                        onDeletePlan: { viewModel.deletePlan($0) },
                        onStartPlan: { viewModel.sendToToday($0) }
                    )
                }
                .padding(AppSizes.Space.screen * unit)
            }
        }
        .background(AppColors.background)
        .onAppear { viewModel.configure(context: modelContext) }
        // The pencil opens "Edit your week": Back returns here
        .navigationDestination(isPresented: $viewModel.isEditWeekOpen) {
            EditWeekView(
                week: viewModel.weekData,
                savedPlan: viewModel.savedWeekPlan,
                plans: viewModel.plans,
                onBack: { viewModel.closeEditWeek() },
                onSave: { viewModel.saveWeek($0) },
                onReset: { viewModel.resetWeek() }
            )
            .navigationBarBackButtonHidden(true)   // the screens have their own Back
            .toolbar(.hidden, for: .navigationBar)
        }
        // "+ New plan" and "Add plan" open "Add your plan": Back returns here
        .navigationDestination(isPresented: $viewModel.isAddPlanOpen) {
            AddPlanView(
                editing: viewModel.planBeingEdited,
                takenColorIndexes: viewModel.takenColorIndexes,
                otherPlanNames: viewModel.otherPlanNames,
                onBack: { viewModel.closeAddPlan() },
                onSave: { viewModel.savePlan($0) }
            )
            .navigationBarBackButtonHidden(true)   // the screens have their own Back
            .toolbar(.hidden, for: .navigationBar)
        }
        // Start opens the workout on the whole screen: Back returns here
        .fullScreenCover(item: $viewModel.workoutPlan) { plan in
            WorkoutView(plan: plan, onClose: { viewModel.closeWorkout() })
        }
        // "+ New plan" > Ready-made: a short sheet rises from the bottom (drag it down to close)
        .sheet(isPresented: $viewModel.isReadyMadeOpen, onDismiss: { viewModel.readyMadeSheetClosed() }) {
            ReadyMadeSheetView(
                hasWeek: viewModel.hasSavedWeek,
                initialStyle: viewModel.readyMadeStyle,
                onCreate: { viewModel.createReadyMade($0) },
                onSetWeek: { viewModel.setWeekFromReadyMade($0) }
            )
                .presentationDetents([.fraction(0.36)])
                .presentationDragIndicator(.visible)
                .presentationBackground(AppColors.background)
        }
        // The limit of plans: a native alert with one button
        .alert(
            "Plan limit reached",
            isPresented: Binding(
                get: { viewModel.planLimitMessage != nil },
                set: { if !$0 { viewModel.planLimitMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.planLimitMessage ?? "")
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
