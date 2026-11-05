//
//  PhotoNavigationBar.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import SwiftUI

// One entry of the "Jump to" menu: a title, an icon and what happens when it is tapped
struct PhotoJumpItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let action: () -> Void
}

// The bar used by Photos and by Compare, so the two screens look exactly the same:
// the native "Jump to" menu on the left, then the angle chips All, Front, Side, Back.
// If the chips do not fit, they scroll sideways while "Jump to" stays in place. Every size is a multiple of "unit".
struct PhotoNavigationBar: View {
    let jumpItems: [PhotoJumpItem]
    @Binding var angle: PhotoAngle?
    let unit: CGFloat   // 1% of the screen width

    // Lets the white highlight slide from one chip to the next
    @Namespace private var highlightNamespace

    var body: some View {
        // The "Jump to" menu stays OUTSIDE the horizontal scroll view: inside it, the touches
        // were shared with the scrolling and a tap could land on the component above or below.
        HStack(spacing: AppSizes.Space.related * unit) {
            jumpMenu

            ScrollView(.horizontal) {
                HStack(spacing: AppSizes.Space.related * unit) {
                    angleChip(title: "All", value: nil)
                    ForEach(PhotoAngle.allCases) { value in
                        angleChip(title: value.title, value: value)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        // The bar is above its neighbours, so nothing drawn next to it can take its taps
        .zIndex(1)
    }

    // MARK: Jump to (native menu)

    private var jumpMenu: some View {
        Menu {
            ForEach(jumpItems) { item in
                Button(item.title, systemImage: item.systemImage, action: item.action)
            }
        } label: {
            HStack(spacing: AppSizes.Space.related * unit) {
                Image(systemName: "calendar")
                Text("Jump to")
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: AppSizes.Text.caption * unit, weight: .bold))
            }
            .font(.system(size: AppSizes.Text.small * unit, weight: .heavy))
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 3.2 * unit)
            .padding(.vertical, 2.4 * unit)
            .background(AppColors.card, in: Capsule())
            // The tappable area is exactly the visible capsule
            .contentShape(Capsule())
        }
        .fixedSize()
        .disabled(jumpItems.isEmpty)
        .opacity(jumpItems.isEmpty ? 0.4 : 1)
    }

    // MARK: Angle chips

    private func angleChip(title: String, value: PhotoAngle?) -> some View {
        let isSelected = angle == value
        return Button {
            withAnimation(.smooth(duration: 0.38)) { angle = value }
        } label: {
            Text(title)
                .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
                .padding(.horizontal, 2.5 * unit)
                .padding(.vertical, 2.4 * unit)
                .contentShape(Capsule())
                .background {
                    // The grey capsule is always there; the white one slides under the chosen chip
                    ZStack {
                        Capsule().fill(AppColors.card)
                        if isSelected {
                            Capsule()
                                .fill(AppColors.textPrimary)
                                .matchedGeometryEffect(id: "highlight", in: highlightNamespace)
                        }
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
