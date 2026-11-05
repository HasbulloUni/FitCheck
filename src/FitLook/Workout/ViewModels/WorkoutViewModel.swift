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
    private(set) var isTimedRunning = false        // false until the user taps Start

    // MARK: What the screen shows
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
    private var restEndDate: Date? = nil      // when the rest ends (the clock, not a counter)
    private var timedEndDate: Date? = nil     // when the warm-up / cool-down countdown ends
    var isResumeAsked = false                 // true: "Continue your workout?" is shown
    private var pendingDraft: WorkoutDraft? = nil
    var saveFailed = false                    // true: the workout could not be saved, the screen asks to try again

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

        // A workout of this plan was stopped by the closing of the app: ask if it continues
        if let draft = WorkoutDraftStore.load(planId: plan.id.uuidString, steps: steps) {
            pendingDraft = draft
            isResumeAsked = true
        } else {
            startClock()
        }
    }

    // "Continue": the sets done and the step come back, the clock goes on from the saved time
    func resumeDraft() {
        isResumeAsked = false
        guard let draft = pendingDraft else { startClock(); return }
        pendingDraft = nil
        sets = draft.sets
        stepIndex = draft.stepIndex
        prepareStep()
        startClock()
        startDate = Date().addingTimeInterval(-Double(draft.elapsedSeconds))
        elapsedSeconds = draft.elapsedSeconds
    }

    // "Start over": the old draft is thrown away
    func discardDraft() {
        isResumeAsked = false
        pendingDraft = nil
        WorkoutDraftStore.clear()
        startClock()
    }

    // Keeps the workout so far (called after each set and each step)
    private func saveDraft() {
        guard !shouldClose, SessionSaver.setsDone(in: sets) > 0 else { return }
        WorkoutDraftStore.save(WorkoutDraft(
            planId: plan.id.uuidString,
            savedAt: Date(),
            stepIndex: stepIndex,
            elapsedSeconds: Int(Date().timeIntervalSince(startDate)),
            sets: sets
        ))
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

    // The title of the big bottom button, "Next exercise", or "Finish workout" on the last step
    var nextTitle: String {
        let next = stepIndex + 1
        if next < steps.count { return "Next exercise" }
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
        let counts = SessionSaver.mainSetCounts(steps: steps, sets: sets)
        let text = "\(counts.done) of \(counts.total) sets done"
        if SessionSaver.isCompleted(steps: steps, sets: sets) {
            return "\(text): it will count as done."
        }
        return "\(text): your sets are saved, but it will not count as done yet."
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
            restEndDate = Date().addingTimeInterval(Double(restTotal))
        }
        saveDraft()
    }

    // "Save changes" of a set that was already done
    func saveEdit() {
        editingSetIndex = nil
        saveDraft()
    }

    // MARK: Rest

    func skipRest() {
        restRemaining = 0
        restEndDate = nil
    }

    func addRest() {
        restRemaining += WorkoutRules.restExtraSeconds
        restTotal = max(restTotal, restRemaining)
        restEndDate = Date().addingTimeInterval(Double(restRemaining))
    }

    // MARK: Moving between steps

    // "Next": goes to the next step, or ends the workout after the last one
    func nextStep() {
        if stepIndex + 1 < steps.count {
            stepIndex += 1
            prepareStep()
            saveDraft()
        } else {
            finish()
        }
    }

    private func prepareStep() {
        editingSetIndex = nil
        restRemaining = 0
        restTotal = 0
        restEndDate = nil
        timedEndDate = nil
        timedRemaining = currentStep?.durationSeconds ?? 0
        isTimedRunning = false
    }

    // The "Start" button of a warm-up or cool-down step: the countdown begins now
    func startTimed() {
        guard currentStep?.isTimed == true, timedRemaining > 0 else { return }
        isTimedRunning = true
        timedEndDate = Date().addingTimeInterval(Double(timedRemaining))
    }

    // MARK: Leaving and finishing

    // Back and Finish both ask first
    func requestLeave() {
        isLeaveConfirmOpen = true
    }

    // Stops the clock, saves what was done and closes the screen.
    // With no set done nothing is saved and the screen just closes.
    func finish() {
        // A second tap on Finish must not save the workout twice
        guard !shouldClose else { return }

        if SessionSaver.setsDone(in: sets) == 0 {
            WorkoutDraftStore.clear()
            stopClock()
            shouldClose = true
            return
        }
        let minutes = max(1, Int(Date().timeIntervalSince(startDate)) / 60)
        guard let saved = SessionSaver.save(
            plan: plan,
            steps: steps,
            sets: sets,
            minutes: minutes,
            previousWeights: previousWeights,
            context: context
        ) else {
            saveFailed = true   // the sets are still here: the user can try again
            return
        }
        summary = saved
        WorkoutDraftStore.clear()
        stopClock()
        shouldClose = true   // no end screen: the numbers appear in the Today card of the Home
    }

    // Stops the clock and lets the screen lock again
    private func stopClock() {
        ticker?.cancel()
        ticker = nil
        restRemaining = 0
        restEndDate = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: Clock

    private func startClock() {
        startDate = Date()
        UIApplication.shared.isIdleTimerDisabled = true   // the screen stays on during the workout
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
        // The rest and the countdown come from the clock, so they stay right after the phone was locked
        if let end = restEndDate {
            restRemaining = max(0, Int(end.timeIntervalSinceNow.rounded(.up)))
            if restRemaining == 0 { restEndDate = nil }
        }
        if isTimedRunning, let end = timedEndDate, currentStep?.isTimed == true {
            timedRemaining = max(0, Int(end.timeIntervalSinceNow.rounded(.up)))
        }
    }
}
