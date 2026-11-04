//
//  WorkoutViewModel.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI
import SwiftData

// The ViewModel of the workout screen: it owns the steps, the sets, the timers and the
// saving. The Views only draw what is here and call the functions below.
@MainActor
@Observable
final class WorkoutViewModel {

    enum Phase {
        case working
        case summary
    }

    // Which number the user is changing with the wheel
    enum PickerKind: Identifiable {
        case reps
        case weight

        var id: Int { self == .reps ? 0 : 1 }
    }

    let plan: PlanItem

    // MARK: Data of the workout
    private(set) var steps: [WorkoutStep] = []
    private(set) var sets: [[WorkoutSet]] = []     // sets[stepIndex][setIndex]; empty for timed steps
    private(set) var stepIndex = 0

    // The set the user is changing. nil = the first set not done yet.
    private(set) var editingSetIndex: Int? = nil

    // MARK: Timers (all count seconds)
    private(set) var elapsedSeconds = 0            // the time of the whole workout
    private(set) var restRemaining = 0             // 0 = no rest running
    private(set) var restTotal = 0                 // to draw the ring of the rest
    private(set) var timedRemaining = 0            // warm-up and cool-down steps

    // MARK: What the screen shows
    private(set) var phase: Phase = .working
    private(set) var summary: WorkoutSummary? = nil
    private(set) var shouldClose = false           // true: the screen can be closed
    var picker: PickerKind? = nil                  // the wheel for reps or weight (nil = closed)
    var isInfoOpen = false                         // "How to do it" sheet
    var isLeaveConfirmOpen = false                 // "Finish the workout?" question

    private var context: ModelContext?
    private var previousWeights: [String: Double] = [:]
    private var ticker: Task<Void, Never>? = nil
    private var hasStarted = false
    private var startDate = Date()

    init(plan: PlanItem) {
        self.plan = plan
    }

    // MARK: Start

    // Called when the screen appears: loads the exercises, the last weights and starts the clock.
    func begin(context: ModelContext) {
        guard !hasStarted else { return }
        hasStarted = true
        self.context = context

        let ids = plan.warmupMoves + plan.exerciseIds
        let descriptor = FetchDescriptor<Exercise>(predicate: #Predicate { ids.contains($0.id) })
        let exercises = (try? context.fetch(descriptor)) ?? []

        previousWeights = LastWeightsFinder.lastWeights(in: context)
        load(steps: WorkoutBuilder.makeSteps(plan: plan, exercises: exercises))
        startClock()
    }

    // Used by the previews: steps made by hand, no database
    func loadPreview(steps: [WorkoutStep], previousWeights: [String: Double] = [:]) {
        hasStarted = true
        self.previousWeights = previousWeights
        load(steps: steps)
    }

    private func load(steps newSteps: [WorkoutStep]) {
        steps = newSteps
        sets = newSteps.map { step in
            let weight = previousWeights[step.exerciseId] ?? 0
            return Array(repeating: WorkoutSet(reps: WorkoutRules.defaultReps, weight: weight),
                         count: step.setCount)
        }
        stepIndex = 0
        prepareStep()
    }

    // MARK: What is on the screen now

    var currentStep: WorkoutStep? {
        stepIndex < steps.count ? steps[stepIndex] : nil
    }

    var currentSets: [WorkoutSet] {
        stepIndex < sets.count ? sets[stepIndex] : []
    }

    var isResting: Bool { restRemaining > 0 }

    // The first set not done yet (nil when all are done)
    private var firstUndoneIndex: Int? {
        currentSets.firstIndex(where: { !$0.isDone })
    }

    var allSetsDone: Bool { !currentSets.isEmpty && firstUndoneIndex == nil }

    // The set shown in the Reps / Weight card
    var activeSetIndex: Int {
        editingSetIndex ?? firstUndoneIndex ?? max(0, currentSets.count - 1)
    }

    var activeSet: WorkoutSet {
        currentSets.isEmpty ? WorkoutSet(reps: WorkoutRules.defaultReps, weight: 0) : currentSets[activeSetIndex]
    }

    var isEditingDoneSet: Bool { editingSetIndex != nil }

    // The small text above the title, e.g. "EXERCISE 1 OF 11"
    var headerText: String {
        guard let step = currentStep else { return "" }
        let sameKind = steps.filter { $0.kind == step.kind }
        let position = (sameKind.firstIndex(where: { $0.id == step.id }) ?? 0) + 1
        switch step.kind {
        case .warmup: return "WARM-UP \(position) OF \(sameKind.count)"
        case .exercise: return "EXERCISE \(position) OF \(sameKind.count)"
        case .cooldown: return "COOL-DOWN"
        }
    }

    // The title of the big bottom button, e.g. "Next: Leg press"
    var nextTitle: String {
        let next = stepIndex + 1
        if next < steps.count { return "Next: \(steps[next].name)" }
        return "Finish workout"
    }

    // The heaviest weight of the sets done in this exercise (for the "all done" card)
    var heaviestDone: Double {
        currentSets.filter { $0.isDone }.map { $0.weight }.max() ?? 0
    }

    // The question shown when the user leaves
    var leaveMessage: String {
        let done = SessionSaver.setsDone(in: sets)
        if done == 0 { return "No set was done yet, so nothing will be saved." }
        let exercises = steps.filter { $0.kind == .exercise }
        let finished = exercises.filter { step in
            let stepSets = sets[step.id]
            return !stepSets.isEmpty && stepSets.allSatisfy { $0.isDone }
        }.count
        if finished == exercises.count { return "All the exercises are done. Your workout will be saved." }
        return "You did \(finished) of \(exercises.count) exercises. Your sets are saved, but the plan will not count as done."
    }

    // MARK: Changing reps and weight of the active set

    func changeReps(by delta: Int) {
        guard stepIndex < sets.count, !currentSets.isEmpty else { return }
        let index = activeSetIndex
        let value = sets[stepIndex][index].reps + delta
        sets[stepIndex][index].reps = min(WorkoutRules.maxReps, max(WorkoutRules.minReps, value))
    }

    func changeWeight(by delta: Double) {
        guard stepIndex < sets.count, !currentSets.isEmpty else { return }
        let index = activeSetIndex
        let value = sets[stepIndex][index].weight + delta
        sets[stepIndex][index].weight = min(WorkoutRules.maxWeight, max(0, value))
    }

    // MARK: The wheel (tap on the number of reps or weight)

    // All the values of the wheels: from the smallest to the biggest
    var repsOptions: [Int] {
        Array(WorkoutRules.minReps...WorkoutRules.maxReps)
    }

    var weightOptions: [Double] {
        Array(stride(from: 0.0, through: WorkoutRules.maxWeight, by: WorkoutRules.weightStep))
    }

    // The weight of the active set, moved to the nearest value of the wheel
    var activeWeightOnWheel: Double {
        let step = WorkoutRules.weightStep
        return (activeSet.weight / step).rounded() * step
    }

    func setReps(_ value: Int) {
        guard stepIndex < sets.count, !currentSets.isEmpty else { return }
        sets[stepIndex][activeSetIndex].reps = min(WorkoutRules.maxReps, max(WorkoutRules.minReps, value))
    }

    func setWeight(_ value: Double) {
        guard stepIndex < sets.count, !currentSets.isEmpty else { return }
        sets[stepIndex][activeSetIndex].weight = min(WorkoutRules.maxWeight, max(0, value))
    }

    // MARK: Sets

    // The chips: a done set can be edited, the next one goes back to the normal view.
    func selectSet(_ index: Int) {
        guard index < currentSets.count else { return }
        if currentSets[index].isDone {
            editingSetIndex = index
        } else if index == firstUndoneIndex {
            editingSetIndex = nil
        }
    }

    // "Complete set": saves the set, starts the rest and prepares the next set with the same numbers
    func completeSet() {
        guard stepIndex < sets.count, let index = firstUndoneIndex else { return }
        sets[stepIndex][index].isDone = true

        if let next = firstUndoneIndex {
            sets[stepIndex][next].reps = sets[stepIndex][index].reps
            sets[stepIndex][next].weight = sets[stepIndex][index].weight
            restTotal = WorkoutRules.restSeconds
            restRemaining = restTotal
        }
    }

    // "Save changes" of a set that was already done
    func saveEdit() {
        editingSetIndex = nil
    }

    // MARK: Rest

    func skipRest() {
        restRemaining = 0
    }

    func addRest() {
        restRemaining += WorkoutRules.restExtraSeconds
        restTotal = max(restTotal, restRemaining)
    }

    // MARK: Moving between steps

    // "Next": goes to the next step, or ends the workout after the last one
    func nextStep() {
        if stepIndex + 1 < steps.count {
            stepIndex += 1
            prepareStep()
        } else {
            finish()
        }
    }

    private func prepareStep() {
        editingSetIndex = nil
        restRemaining = 0
        restTotal = 0
        timedRemaining = currentStep?.durationSeconds ?? 0
    }

    // MARK: Leaving and finishing

    // Back and Finish both ask first
    func requestLeave() {
        isLeaveConfirmOpen = true
    }

    // Stops the clock, saves what was done and shows the summary.
    // With no set done nothing is saved and the screen just closes.
    func finish() {
        ticker?.cancel()
        ticker = nil
        restRemaining = 0

        if SessionSaver.setsDone(in: sets) == 0 {
            shouldClose = true
            return
        }
        summary = SessionSaver.save(
            plan: plan,
            steps: steps,
            sets: sets,
            minutes: max(1, elapsedSeconds / 60),
            previousWeights: previousWeights,
            context: context
        )
        phase = .summary
    }

    // MARK: Clock

    private func startClock() {
        startDate = Date()
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    private func tick() {
        elapsedSeconds = Int(Date().timeIntervalSince(startDate))
        if restRemaining > 0 { restRemaining -= 1 }
        if timedRemaining > 0, currentStep?.isTimed == true { timedRemaining -= 1 }
    }
}
