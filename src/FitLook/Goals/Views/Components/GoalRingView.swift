//
//  GoalRingView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 03/11/2026.
//

import SwiftUI

// A progress ring: grey circle, colored arc on top, text in the middle.
// The size and the text size are passed in, so the same ring is used by the main goal card
// (big) and by the list of other goals (small).
struct GoalRingView: View {
    let progress: Double     // from 0 to 1
    let color: Color         // color of the arc
    let centerText: String   // e.g. "85" or "1/3"
    let size: CGFloat        // width and height of the ring
    let lineWidth: CGFloat   // thickness of the ring
    let fontSize: CGFloat    // size of the text in the middle
    let caption: String?     // small text under the number, e.g. "of 180" (nil = none)

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.divider, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)   // draws only a part of the circle
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))   // the arc starts from the top

            VStack(spacing: 0) {
                Text(centerText)
                    .font(.system(size: fontSize, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if let caption {
                    Text(caption)
                        .font(.system(size: fontSize * 0.4, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            // Keeps the text inside the ring
            .padding(lineWidth * 1.5)
        }
        .frame(width: size, height: size)
    }
}

#Preview("Light") {
    GoalRingView(progress: 0.47, color: AppColors.goalColor(progress: 0.47), centerText: "85",
                 size: 80, lineWidth: 9, fontSize: 28, caption: "of 180")
        .padding(20)
        .background(AppColors.background)
}

#Preview("Dark") {
    GoalRingView(progress: 0.47, color: AppColors.goalColor(progress: 0.47), centerText: "85",
                 size: 80, lineWidth: 9, fontSize: 28, caption: "of 180")
        .padding(20)
        .background(AppColors.background)
        .preferredColorScheme(.dark)
}
