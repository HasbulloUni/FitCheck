//
//  PhotoAddSheet.swift
//  FitCheck
//
//  Created by AFP FED 11 on 04/11/2026.
//

import SwiftUI

// "Ready to save": the picked photo with its date and angle, then Save.
// The date is today by default; the angle is the active filter, or Front.
struct PhotoAddSheet: View {
    @Bindable var viewModel: PhotosViewModel

    // "Pick a date" is open (only for photos from the library)
    @State private var isPickingDate = false

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 100   // 1% of the screen width

            if let draft = viewModel.draft {
                VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                    Text("Ready to save")
                        .font(.system(size: AppSizes.Text.title * unit, weight: .heavy))
                        .foregroundStyle(AppColors.textPrimary)

                    HStack(alignment: .top, spacing: AppSizes.Space.section * unit) {
                        PhotoImageView(data: draft.small)
                            .aspectRatio(3 / 4, contentMode: .fit)
                            .frame(width: 28 * unit)
                            .clipShape(RoundedRectangle(cornerRadius: AppSizes.Radius.card * unit))

                        VStack(alignment: .leading, spacing: AppSizes.Space.section * unit) {
                            // A photo taken now with the camera is of today: the date is not asked
                            if !draft.isFromCamera {
                                dateField(draft: draft, unit: unit)
                            }
                            angleField(draft: draft, unit: unit)
                        }
                    }

                    Button(action: { viewModel.saveDraft() }) {
                        Text("Save photo")
                            .font(.system(size: AppSizes.Text.body * unit, weight: .heavy))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3.8 * unit)
                            .background(AppColors.yellow, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 0)
                }
                .padding(6 * unit)
            }
        }
        .background(AppColors.background)
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Date

    private func dateField(draft: PhotoDraft, unit: CGFloat) -> some View {
        let isToday = ProgressPeriodBuilder.startOfDay(draft.date) == ProgressPeriodBuilder.today()

        return VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            fieldTitle("Date", unit: unit)

            HStack(spacing: AppSizes.Space.related * unit) {
                chip(title: "Today", isSelected: isToday && !isPickingDate, unit: unit) {
                    isPickingDate = false
                    viewModel.draft?.date = ProgressPeriodBuilder.today()
                }
                chip(title: "Pick a date", isSelected: isPickingDate, unit: unit) {
                    isPickingDate = true
                }
            }

            // Any day up to today, with the date picker of the system
            if isPickingDate {
                DatePicker(
                    "Date",
                    selection: Binding(
                        get: { viewModel.draft?.date ?? ProgressPeriodBuilder.today() },
                        set: { viewModel.draft?.date = ProgressPeriodBuilder.startOfDay($0) }
                    ),
                    in: ...ProgressPeriodBuilder.today(),
                    displayedComponents: .date
                )
                .labelsHidden()
                .tint(AppColors.textPrimary)
            }
        }
    }

    // MARK: - Angle

    private func angleField(draft: PhotoDraft, unit: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSizes.Space.related * unit) {
            fieldTitle("Angle", unit: unit)

            HStack(spacing: AppSizes.Space.related * unit) {
                ForEach(PhotoAngle.allCases) { angle in
                    chip(title: angle.title, isSelected: draft.angle == angle, unit: unit) {
                        viewModel.draft?.angle = angle
                    }
                }
            }
        }
    }

    // MARK: - Small pieces

    private func fieldTitle(_ text: String, unit: CGFloat) -> some View {
        Text(text.uppercased())
            .font(.system(size: AppSizes.Text.caption * unit, weight: .heavy))
            .tracking(0.3 * unit)
            .foregroundStyle(AppColors.textSecondary)
    }

    private func chip(title: String, isSelected: Bool, unit: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppSizes.Text.small * unit, weight: .bold))
                .foregroundStyle(isSelected ? AppColors.background : AppColors.textPrimary)
                .padding(.horizontal, 3 * unit)
                .padding(.vertical, 1.8 * unit)
                .background(isSelected ? AppColors.textPrimary : AppColors.card, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews
private func addSheetViewModel() -> PhotosViewModel {
    let viewModel = ProgressPreviewData.photosViewModel(withData: true)
    let data = ProgressPreviewData.thumbnailData()
    viewModel.draft = PhotoDraft(big: data, small: data, date: ProgressPeriodBuilder.today(), angle: .front, isFromCamera: false)
    return viewModel
}

#Preview("Light") {
    PhotoAddSheet(viewModel: addSheetViewModel())
}

#Preview("Dark") {
    // A photo taken with the camera: no date to choose
    let viewModel = addSheetViewModel()
    if let draft = viewModel.draft {
        viewModel.draft = PhotoDraft(big: draft.big, small: draft.small, date: draft.date, angle: .front, isFromCamera: true)
    }
    return PhotoAddSheet(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("No data") {
    // No picture picked: the sheet has nothing to show
    PhotoAddSheet(viewModel: ProgressPreviewData.photosViewModel(withData: false))
}
