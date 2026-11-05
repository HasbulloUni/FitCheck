//
//  FireworksView.swift
//  FitCheck
//
//  Fireworks over the Home when all the workouts of the week are done.
//  Only SwiftUI (TimelineView + Canvas): a few bursts that open, fall and fade.
//  It does not take touches. The Home hides it after a few seconds.
//

import SwiftUI

struct FireworksView: View {
    // How long the show lasts, in seconds
    static let duration: Double = 3.5

    // One burst: where and when it starts, and its color
    private struct Burst {
        let x: Double          // 0...1 of the width
        let y: Double          // 0...1 of the height
        let start: Double      // seconds
        let color: Color
    }

    private let bursts: [Burst] = {
        let colors = PlanPalette.colors   // the 6 colors of the plans
        let places: [(Double, Double, Double)] = [
            (0.25, 0.30, 0.0), (0.72, 0.22, 0.35), (0.50, 0.42, 0.7),
            (0.18, 0.55, 1.1), (0.82, 0.50, 1.4), (0.40, 0.25, 1.8), (0.65, 0.35, 2.1)
        ]
        return places.enumerated().map { index, place in
            Burst(x: place.0, y: place.1, start: place.2, color: colors[index % colors.count])
        }
    }()

    private let particleCount = 28
    private let burstLife = 1.4     // seconds a burst stays visible

    @State private var startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(startDate)

            Canvas { context, size in
                for burst in bursts {
                    let age = time - burst.start
                    guard age > 0, age < burstLife else { continue }
                    let progress = age / burstLife
                    let radius = size.width * 0.28 * (1 - pow(1 - progress, 3))   // fast, then slow
                    let gravity = size.height * 0.08 * progress * progress
                    let opacity = 1 - progress

                    for particle in 0..<particleCount {
                        let angle = Double(particle) / Double(particleCount) * 2 * .pi
                        let x = size.width * burst.x + cos(angle) * radius
                        let y = size.height * burst.y + sin(angle) * radius + gravity
                        let dot = size.width * 0.012 * (1 - progress * 0.5)
                        context.fill(
                            Path(ellipseIn: CGRect(x: x - dot, y: y - dot, width: dot * 2, height: dot * 2)),
                            with: .color(burst.color.opacity(opacity))
                        )
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { startDate = Date() }
    }
}

#Preview("Light") {
    FireworksView()
        .background(AppColors.background)
}

#Preview("Dark") {
    FireworksView()
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
