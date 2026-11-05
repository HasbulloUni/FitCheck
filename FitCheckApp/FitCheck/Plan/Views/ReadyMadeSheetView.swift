//
//  ReadyMadeSheetView.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// The sheet that rises from the bottom after "+ New plan" > "Ready-made".
// Title on the left, "Create >" on the right, a list with a check, a small note.
// The user closes it by dragging it down. Every size is a multiple of "unit" (1% of the width).
struct ReadyMadeSheetView: View {
    @State private var viewModel: ReadyMadeViewModel
    let hasWeek: Bool                        // false = the training days are not saved yet
    let onCreate: (ReadyMadeStyle) -> Void   // tap on "Create >" with the chosen style
    let onSetWeek: (ReadyMadeStyle) -> Void  // tap on "Set week >" (no week saved yet)

    init(hasWeek: Bool, initialStyle: ReadyMadeStyle = .fullBody,
         onCreate: @escaping (ReadyMadeStyle) -> Void,
         onSetWeek: @escaping (ReadyMadeStyle) -> Void) {
        _viewModel = State(initialValue: ReadyMadeViewModel(selected: initialStyle))
        self.hasWeek = hasWeek
        self.onCreate = onCreate
        self.onSetWeek = onSetWeek
    }

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the width

            VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {

                // Title on the left, Create on the right
                HStack {
                    Text("Ready-made")
                        .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    // Without a saved week the button leads to Edit week instead of creating
                    Button {
                        if hasWeek { onCreate(viewModel.selected) } else { onSetWeek(viewModel.selected) }
                    } label: {
                        HStack(spacing: AppSizes.Space.tight * unit) {
                            Text(hasWeek ? "Create" : "Set week")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: AppSizes.Text.body * unit, weight: .semibold))
                        .foregroundStyle(AppColors.background)
                        .padding(.horizontal, AppSizes.Space.section * unit)
                        .padding(.vertical, 2.5 * unit)
                        .background(AppColors.textPrimary, in: Capsule())
                    }
                }

                // The list: one row for each style, a check on the chosen one
                VStack(spacing: 0) {
                    ForEach(ReadyMadeStyle.allCases) { style in
                        row(for: style, unit: unit)

                        if style != ReadyMadeStyle.allCases.last {
                            Rectangle()
                                .fill(AppColors.divider)
                                .frame(height: 0.2 * unit)
                                .padding(.leading, AppSizes.Space.section * unit)
                        }
                    }
                }
                .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))

                Text(hasWeek ? "Your plans are added to My plans." : "Set your training days first.")
                    .font(.system(size: AppSizes.Text.small * unit, weight: .regular))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, AppSizes.Space.related * unit)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSizes.Space.screen * unit)
            .padding(.top, 8 * unit)
        }
        .background(AppColors.background)
    }

    // One row of the list
    private func row(for style: ReadyMadeStyle, unit: CGFloat) -> some View {
        Button { viewModel.select(style) } label: {
            HStack {
                Text(style.title)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                // The check is always there, only visible on the chosen row
                Image(systemName: "checkmark")
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .bold))
                    .foregroundStyle(AppColors.greenSoft)
                    .opacity(viewModel.isSelected(style) ? 1 : 0)
            }
            .padding(.horizontal, AppSizes.Space.section * unit)
            .padding(.vertical, AppSizes.Space.section * unit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(viewModel.isSelected(style) ? .isSelected : [])
    }
}

#Preview("Light") {
    Color.gray.opacity(0.2)
        .sheet(isPresented: .constant(true)) {
            ReadyMadeSheetView(hasWeek: true, onCreate: { _ in }, onSetWeek: { _ in })
                .presentationDetents([.fraction(0.36)])
        }
}

#Preview("No week") {
    Color.gray.opacity(0.2)
        .sheet(isPresented: .constant(true)) {
            ReadyMadeSheetView(hasWeek: false, onCreate: { _ in }, onSetWeek: { _ in })
                .presentationDetents([.fraction(0.36)])
        }
}

#Preview("Dark") {
    Color.gray.opacity(0.2)
        .sheet(isPresented: .constant(true)) {
            ReadyMadeSheetView(hasWeek: true, onCreate: { _ in }, onSetWeek: { _ in })
                .presentationDetents([.fraction(0.36)])
        }
        .preferredColorScheme(.dark)
}
