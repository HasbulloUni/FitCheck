//
//  PhotoSourceSheet.swift
//  FitCheck
//
//  Created by AFP FED 11 on 05/11/2026.
//

import SwiftUI
import UIKit

// The small sheet "Add a photo": take a photo or pick one from the library.
// It is a sheet of the whole screen, not a menu stuck to a button: the buttons of the Photos screen
// change (Add first photo becomes Add photo), but the sheet always opens in the same place.
// The user closes it by dragging it down.
struct PhotoSourceSheet: View {
    let onChoose: (PhotoSource) -> Void

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                Text("Add a photo")
                    .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                    .foregroundStyle(AppColors.textPrimary)

                VStack(spacing: 0) {
                    row(title: "Take photo", icon: "camera.fill",
                        isEnabled: UIImagePickerController.isSourceTypeAvailable(.camera), unit: unit) {
                        onChoose(.camera)
                    }

                    Rectangle()
                        .fill(AppColors.divider)
                        .frame(height: 0.2 * unit)
                        .padding(.leading, AppSizes.Space.section * unit)

                    row(title: "Photo library", icon: "photo.on.rectangle", isEnabled: true, unit: unit) {
                        onChoose(.library)
                    }
                }
                .background(AppColors.card, in: RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSizes.Space.screen * unit)
            .padding(.top, 8 * unit)
        }
        .background(AppColors.background)
        .presentationDetents([.fraction(0.3)])
    }

    // One row of the list
    private func row(title: String, icon: String, isEnabled: Bool, unit: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSizes.Space.section * unit) {
                Image(systemName: icon)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                    .frame(width: 8 * unit)
                Text(title)
                    .font(.system(size: AppSizes.Text.bodyLarge * unit, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSizes.Space.section * unit)
            .padding(.vertical, AppSizes.Space.section * unit)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

// Where the new photo comes from
enum PhotoSource {
    case camera
    case library
}

#Preview("Light") {
    Color.gray.opacity(0.2)
        .sheet(isPresented: .constant(true)) {
            PhotoSourceSheet(onChoose: { _ in })
        }
}
