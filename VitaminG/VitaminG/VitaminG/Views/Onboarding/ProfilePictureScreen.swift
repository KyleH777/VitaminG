import SwiftUI
import PhotosUI
import AVFoundation

// MARK: - ProfilePictureScreen
// Onboarding Screen 5: Optional profile photo upload.
// Provides PHPicker (library) and UIImagePickerController (camera) options, plus skip.
// Photo is resized to ≤512px and compressed to JPEG 0.75 via CommunityService.resizeAndCompress.
// T-17-04-01 mitigation: no full-resolution storage in Phase 17.
// T-17-04-03 mitigation: AVCaptureDevice callback dispatched to main thread before @State mutation.

struct ProfilePictureScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void
    var viewModel: OnboardingViewModel

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showLibraryPicker: Bool = false
    @State private var showCameraPicker: Bool = false
    @State private var cameraPermissionDenied: Bool = false
    @State private var previewImage: UIImage? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Nav row
                HStack {
                    Button(action: { path.removeLast() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(VGTheme.clay)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Go back")
                    Spacer()
                }
                .padding(.bottom, 20)

                // Step bar
                StepBarView(current: 3, total: 7)
                    .padding(.bottom, 28)

                // Headline
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add a photo")
                        .font(Font.custom("Georgia", size: 42))
                        .foregroundStyle(VGTheme.clay)

                    Text("Help your community recognize you. You can always change this later.")
                        .font(.subheadline.weight(.light))
                        .foregroundStyle(VGTheme.muted)
                        .lineSpacing(4)
                }
                .padding(.bottom, 32)

                // Avatar preview
                Group {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                            .frame(width: 96, height: 96)
                    } else {
                        Circle()
                            .fill(VGTheme.sand)
                            .frame(width: 96, height: 96)
                            .overlay(
                                Text("G")
                                    .font(VGTheme.serifItalic(40))
                                    .foregroundStyle(VGTheme.clay)
                            )
                    }
                }
                .accessibilityLabel(previewImage != nil ? "Profile photo selected" : "Default avatar")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 24)

                // Picker buttons (side by side)
                HStack(spacing: 8) {
                    Button(action: { showLibraryPicker = true }) {
                        Text("Choose from Library")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VGTheme.clay)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(VGTheme.sandMid, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: { requestCameraAccess() }) {
                        Text("Take Photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(VGTheme.clay)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(VGTheme.sandMid, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                // Skip for now link
                Button(action: { path.append(.notifications) }) {
                    Text("Skip for now")
                        .font(.callout.weight(.light))
                        .foregroundStyle(VGTheme.muted)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain)
                .padding(.top, 16)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Bottom CTA
            VStack(spacing: 8) {
                Button(action: { path.append(.notifications) }) {
                    Text("Continue")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(VGTheme.terra)
                        .foregroundStyle(VGTheme.warmWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .navigationBarHidden(true)
        .photosPicker(isPresented: $showLibraryPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, item in
            Task { await handlePhotoSelection(item) }
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView(onCapture: { image in
                Task { await handleCapturedImage(image) }
            })
        }
        .alert("Camera Access Denied", isPresented: $cameraPermissionDenied) {
            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow camera access in Settings to take a profile photo.")
        }
    }

    // MARK: - Camera access

    private func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCameraPicker = true
        case .notDetermined:
            // T-17-04-03: dispatch to main thread before @State mutation
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted { showCameraPicker = true }
                    else { cameraPermissionDenied = true }
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }

    // MARK: - Photo handling

    private func handlePhotoSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let image = UIImage(data: data) else { return }
        let compressed = CommunityService.resizeAndCompress(image, maxDimension: 512, quality: 0.75) ?? data
        await MainActor.run {
            viewModel.profilePhotoData = compressed
            previewImage = UIImage(data: compressed)
        }
    }

    private func handleCapturedImage(_ image: UIImage) async {
        let compressed = CommunityService.resizeAndCompress(image, maxDimension: 512, quality: 0.75)
            ?? image.jpegData(compressionQuality: 0.75)
            ?? Data()
        await MainActor.run {
            viewModel.profilePhotoData = compressed
            previewImage = image
        }
    }
}

// MARK: - CameraPickerView
// UIViewControllerRepresentable bridge for UIImagePickerController (camera source).
// Uses the three-part pattern from ContactPickerRepresentable.swift.

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void

        init(onCapture: @escaping (UIImage) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
