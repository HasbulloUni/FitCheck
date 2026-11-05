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
    @Environment(\.scenePhase) private var scenePhase
    @State private var isInfoOpen = false

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
                        unit: unit,
                        onInfo: { isInfoOpen = true }
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
                        TodayCardView(plan: plan, unit: unit, onStart: { viewModel.startToday() },
                                      onBack: { viewModel.cancelGo() })
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
                        onOpenPlan: { viewModel.openPlan($0) },
                        onEditPlan: { viewModel.openEditPlan($0) },
                        onDeletePlan: { viewModel.deletePlan($0) },
                        onStartPlan: { viewModel.goTapped($0) }
                    )
                }
                .padding(AppSizes.Space.screen * unit)
            }
            // A tap on a plan: its exercises rise from the bottom (pull up for more, drag down to close)
            .sheet(item: $viewModel.planShown) { plan in
                PlanExercisesSheetView(plan: plan, lines: viewModel.exerciseLines(for: plan), unit: unit)
                    .presentationDetents([.fraction(0.5), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(8 * unit)
                    .presentationBackground(AppColors.background)
            }
        }
        .background(AppColors.background)
        .onAppear { viewModel.configure(context: modelContext) }
        // Back to the front (maybe on a new day) or midnight passed: "today" is updated
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshForNewDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            viewModel.refreshForNewDay()
        }
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
        // Info: the notice, where the data is, and "Delete all my data"
        .sheet(isPresented: $isInfoOpen) {
            InfoView()
        }
        // Go after a workout already done today: asks if the user wants to train more
        .alert(
            "You already trained today",
            isPresented: Binding(
                get: { viewModel.extraWorkoutPlan != nil },
                set: { if !$0 { viewModel.cancelExtraWorkout() } }
            ),
            presenting: viewModel.extraWorkoutPlan
        ) { plan in
            Button("Not now", role: .cancel) { viewModel.cancelExtraWorkout() }
            Button("Yes, start") { viewModel.confirmExtraWorkout(plan) }
        } message: { plan in
            Text("Do you want to keep training with \(plan.name)?")
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
        // All the workouts of the week are done: fireworks for a few seconds
        .overlay {
            if viewModel.isFireworksShown {
                FireworksView()
                    .task {
                        try? await Task.sleep(for: .seconds(FireworksView.duration))
                        viewModel.hideFireworks()
                    }
            }
        }
        }
    }
}

#Preview {
    SummaryView()
        .modelContainer(planPreviewContainer(withData: true))
}
