import SwiftUI
import SwiftData
import PhotosUI
#if canImport(UIKit)
import UIKit
import os
#endif

struct TransformationPhotosModuleView: View {
    let userChallenge: UserChallenge

    @Environment(\.modelContext) private var modelContext
    @Query private var allPhotos: [TransformationPhoto]
    @State private var selectedItem: PhotosPickerItem?

    private var photos: [TransformationPhoto] {
        allPhotos
            .filter { $0.userChallengeID == userChallenge.id }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    private var todaysPhoto: TransformationPhoto? {
        let cal = Calendar.current
        return photos.first { entry in
            guard let date = entry.date else { return false }
            return cal.isDateInToday(date)
        }
    }

    private static let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if photos.isEmpty {
                    emptyState
                } else {
                    photoGrid
                }
                addPhotoButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(VGTheme.sandLight)
        .navigationTitle("Transformation Photos")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Photo grid

    private var photoGrid: some View {
        LazyVGrid(columns: Self.columns, spacing: 8) {
            ForEach(photos, id: \.id) { photo in
                photoCell(photo)
            }
        }
    }

    @ViewBuilder
    private func photoCell(_ photo: TransformationPhoto) -> some View {
        ZStack(alignment: .bottom) {
            if let data = photo.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
            } else {
                Color(.tertiarySystemGroupedBackground)
                    .frame(width: 80, height: 80)
            }

            if let date = photo.date {
                Text(dateFormatter.string(from: date))
                    .font(.caption)
                    .fontDesign(.rounded)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black.opacity(0.5)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityLabel(photo.date.map { "\(dateFormatter.string(from: $0)) photo" } ?? "Photo")
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 48))
                .foregroundStyle(VGTheme.muted)
                .accessibilityHidden(true)
            Text("No Photos Yet")
                .font(.title2.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)
            Text("Add your first transformation photo to track your journey.")
                .font(.body)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 32)
    }

    // MARK: - Add photo button + PhotosPicker

    @ViewBuilder
    private var addPhotoButton: some View {
        if todaysPhoto != nil {
            Label("Photo Added Today", systemImage: "checkmark.circle.fill")
                .font(.body.weight(.semibold)).fontDesign(.rounded)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(VGTheme.muted)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Photo already added today")
        } else {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Add Today's Photo", systemImage: "plus")
                    .font(.body.weight(.semibold)).fontDesign(.rounded)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(.secondarySystemGroupedBackground))
                    .foregroundStyle(VGTheme.clay)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await handleSelection(newItem) }
            }
        }
    }

    // MARK: - Selection handler

    private func handleSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let jpeg: Data
        if let img = UIImage(data: data), let encoded = img.jpegData(compressionQuality: 0.9) {
            jpeg = encoded
        } else {
            jpeg = data
        }

        let photo = TransformationPhoto()
        photo.id = UUID()
        photo.date = Calendar.current.startOfDay(for: Date())
        photo.userChallengeID = userChallenge.id
        photo.imageData = jpeg
        photo.timestamp = Date()
        modelContext.insert(photo)
        do {
            try modelContext.save()
        } catch {
            VGLog.general.error("modelContext.save() failed: \(error.localizedDescription, privacy: .public)")
        }

        await MainActor.run { selectedItem = nil }
    }
}
