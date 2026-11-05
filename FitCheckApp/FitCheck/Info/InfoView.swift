//
//  InfoView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import SwiftUI
import SwiftData

// MARK: - Info: the notice, where the data is, and "Delete all my data"
// A native iPhone sheet: a NavigationStack with a List and system components.
struct InfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isDeleteConfirmOpen = false
    @State private var deleteFailed = false
    @State private var isNoticeOpen = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isNoticeOpen = true
                    } label: {
                        Label("Health and safety notice", systemImage: "cross.case")
                    }
                }

                Section {
                    Label {
                        Text("Your plans, workouts and photos are saved only on this iPhone. FitLook has no account and sends nothing to a server. Device backups (iCloud or Mac) can include them.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "lock")
                            .foregroundStyle(.tint)
                    }
                } header: {
                    Text("Your data")
                }

                Section {
                    Button(role: .destructive) {
                        isDeleteConfirmOpen = true
                    } label: {
                        Label("Delete all my data", systemImage: "trash")
                    }
                } footer: {
                    Text("Deletes your plans, workouts, photos and reminders, and starts the app from the beginning.")
                }
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Delete all your data?",
                                isPresented: $isDeleteConfirmOpen,
                                titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
            // The notice has its own navigation bar, so it opens as a sheet (not pushed inside this one)
            .sheet(isPresented: $isNoticeOpen) {
                DisclaimerView(onAccept: nil)
            }
            .alert("Couldn't delete your data", isPresented: $deleteFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please try again.")
            }
        }
    }

    // Removes everything the user made. The exercises stay: they are part of the app.
    private func deleteAll() {
        do {
            try modelContext.delete(model: SessionRecord.self)
            try modelContext.delete(model: PhotoRecord.self)
            try modelContext.delete(model: PlanRecord.self)
            try modelContext.delete(model: AppProfile.self)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            deleteFailed = true
            return
        }

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "celebratedWeekStart")
        WorkoutDraftStore.clear()
        Task { await ReminderScheduler.updateReminders(for: EditWeekDraft()) }
        // The app goes back to the onboarding by itself (OnboardingGateView)
    }
}

#Preview {
    InfoView()
        .modelContainer(for: [SessionRecord.self, PhotoRecord.self, PlanRecord.self, AppProfile.self], inMemory: true)
}
