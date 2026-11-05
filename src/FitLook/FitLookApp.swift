//
//  FitCheckApp.swift
//  FitCheck
//
//  Created by AFP FED 11 on 30/10/2026.
//

import SwiftUI
import SwiftData

@main
struct FoundationApp: App {
    // The database of the app (for now it only holds the exercises)
    let container: ModelContainer

    // True when the saved data could not be opened
    let hasStartupProblem: Bool
    @State private var showStartupAlert = false

    init() {
        let models: [any PersistentModel.Type] = [Exercise.self, AppProfile.self, PlanRecord.self, SessionRecord.self, PhotoRecord.self]
        do {
            container = try ModelContainer(for: Schema(models))
            hasStartupProblem = false
        } catch {
            // The saved data is left untouched on the disk. The app opens with a temporary,
            // empty database in memory (nothing is saved) and tells the user.
            let temporary = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                container = try ModelContainer(for: Schema(models), configurations: temporary)
            } catch {
                fatalError("Cannot create the database: \(error)")
            }
            hasStartupProblem = true
        }
    }

    // False while the first-launch import runs: the splash screen is shown meanwhile
    @State private var isReady = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isReady {
                    OnboardingGateView()
                        .disclaimerOnFirstLaunch()
                        .transition(.opacity)
                } else {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .alert("Your data could not be opened", isPresented: $showStartupAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("FitLook opened in temporary mode: nothing you do now will be kept. Close the app and open it again. If this stays, update the app.")
            }
            .task {
                guard !isReady else { return }
                showStartupAlert = hasStartupProblem
                // The first frame (splash) is already drawn when this runs.
                // First launch: fill the database from exercises.json.
                // It stays on the main context (safe with SwiftData), so it must finish
                // before the screens that need the exercises are created.
                ExerciseImporter.importIfNeeded(into: container.mainContext)
                withAnimation(.easeInOut(duration: 0.25)) {
                    isReady = true
                }
            }
        }
        .modelContainer(container)
    }
}
