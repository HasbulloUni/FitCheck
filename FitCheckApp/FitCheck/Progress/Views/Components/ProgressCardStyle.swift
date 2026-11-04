//
//  ProgressCardStyle.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The look shared by all the cards of the Progress screen: inner space, white background,
// round corners (the same as the goal cards of the Home).
// "height" is optional: nil lets the card be as tall as its content.
extension View {
    func progressCard(unit: CGFloat, height: CGFloat? = nil) -> some View {
        self
            .padding(4 * unit)
            .frame(height: height)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))
    }
}

// The title of a card, e.g. "Sessions"
struct ProgressCardTitle: View {
    let text: String
    let unit: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
            .foregroundStyle(AppColors.textPrimary)
    }
}
