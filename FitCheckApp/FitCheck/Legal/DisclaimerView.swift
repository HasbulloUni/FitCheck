//
//  DisclaimerView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import SwiftUI

// MARK: - The health and safety notice
// A native iPhone sheet: a NavigationStack with a List, system fonts and SF Symbols.
// It opens once, the first time the app is launched, and the user must tap "I understand".
struct DisclaimerView: View {
    let onAccept: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(icon: "cross.case", title: "Not medical advice",
                        text: "FitCheck is not a medical device and does not give medical advice. Talk to a doctor before you start any training program.")

                    row(icon: "figure.strengthtraining.traditional", title: "Training has risks",
                        text: "Exercises with weights can cause injuries. Use a load you can control, stop if you feel pain, and ask a coach if you are unsure about a movement.")

                    row(icon: "list.clipboard", title: "Suggestions only",
                        text: "Sets, reps and progression are general suggestions. They are not a personal prescription and results are never guaranteed.")
                } footer: {
                    Text("By continuing you confirm that you train at your own responsibility.")
                }
            }
            .navigationTitle("Before you start")
            .navigationBarTitleDisplayMode(.large)
            // The big button stays at the bottom, above the home indicator
            .safeAreaInset(edge: .bottom) {
                Button(action: onAccept) {
                    Text("I understand")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    // One row: a symbol, a bold title and a short text
    private func row(icon: String, title: String, text: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Show it only on the first launch
// "hasAcceptedDisclaimer" is saved by the system (UserDefaults, through @AppStorage).
// The user cannot drag the sheet away: the only way out is the button.
private struct DisclaimerOnFirstLaunch: ViewModifier {
    @AppStorage("hasAcceptedDisclaimer") private var hasAccepted = false

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: Binding(get: { !hasAccepted }, set: { _ in })) {
                DisclaimerView(onAccept: { hasAccepted = true })
                    .interactiveDismissDisabled()
            }
    }
}

extension View {
    // Use it once on the root view: .disclaimerOnFirstLaunch()
    func disclaimerOnFirstLaunch() -> some View {
        modifier(DisclaimerOnFirstLaunch())
    }
}

#Preview("Light") {
    DisclaimerView(onAccept: {})
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    DisclaimerView(onAccept: {})
        .preferredColorScheme(.dark)
}
