import SwiftUI
import PhotosUI
import UIKit

struct PostComposeSheet: View {
    let category: String
    let accentColor: Color
    let authorDisplayName: String?
    let authorColorHex: String?
    let viewModel: CommunityFeedViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isSubmitting = false
    @State private var localProfanityFlagged = false
    @State private var showAlert = false
    @State private var showPhotoSourceDialog = false
    @State private var showLibraryPicker = false
    @State private var showCamera = false

    private static let maxChars = 500
    private static let placeholder = "How's your challenge going? Share a win or encouragement..."
    private static let profanityMessage = CommunityFeedViewModel.profanityRejectionMessage

    private var trimmedText: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var characterCount: Int { text.count }
    private var isPostEnabled: Bool {
        !trimmedText.isEmpty && !localProfanityFlagged && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 1. TextEditor + placeholder + character count
                    VStack(alignment: .trailing, spacing: 4) {
                        ZStack(alignment: .topLeading) {
                            if text.isEmpty {
                                Text(Self.placeholder)
                                    .font(.body).fontDesign(.rounded)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                            TextEditor(text: $text)
                                .font(.body).fontDesign(.rounded)
                                .frame(minHeight: 120)
                                .scrollContentBackground(.hidden)
                                .onChange(of: text) { _, newValue in
                                    // Hard cap at 500 chars
                                    if newValue.count > Self.maxChars {
                                        text = String(newValue.prefix(Self.maxChars))
                                    }
                                    // Re-evaluate profanity on every keystroke
                                    localProfanityFlagged = ProfanityFilter.containsProfanity(text)
                                }
                        }
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(localProfanityFlagged ? Color.red : Color.clear, lineWidth: 1)
                        )
                        Text("\(characterCount)/\(Self.maxChars)")
                            .font(.caption).fontDesign(.rounded)
                            .foregroundStyle(VGTheme.muted)
                    }

                    // 2. Profanity rejection inline error
                    if localProfanityFlagged {
                        Text(Self.profanityMessage)
                            .font(.caption).fontDesign(.rounded)
                            .foregroundStyle(.red)
                    }

                    // 3. Photo picker row + preview
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showPhotoSourceDialog = true
                        } label: {
                            Label("Add Photo", systemImage: "camera.fill")
                                .font(.body).fontDesign(.rounded)
                                .foregroundStyle(VGTheme.clay)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .confirmationDialog("Add Photo", isPresented: $showPhotoSourceDialog) {
                            Button("Photo Library") { showLibraryPicker = true }
                            Button("Camera") { showCamera = true }
                            Button("Cancel", role: .cancel) {}
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                guard let newItem else { return }
                                if let data = try? await newItem.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                        if let data = selectedImageData, let img = UIImage(data: data) {
                            HStack {
                                Image(uiImage: img)
                                    .resizable().scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .transition(.opacity)
                                Button("Remove") {
                                    selectedImageData = nil
                                    selectedItem = nil
                                }
                                .font(.body).fontDesign(.rounded)
                                .foregroundStyle(VGTheme.muted)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(VGTheme.sandLight)
            .navigationTitle("Share Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard Post") { dismiss() }
                        .font(.body).fontDesign(.rounded)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") { Task { await submit() } }
                        .font(.body.weight(.semibold)).fontDesign(.rounded)
                        .disabled(!isPostEnabled)
                }
            }
            .alert("Couldn't post. Please try again.",
                   isPresented: $showAlert) {
                Button("OK", role: .none) {}
            }
            .photosPicker(isPresented: $showLibraryPicker, selection: $selectedItem, matching: .images)
            .sheet(isPresented: $showCamera) {
                ImagePickerRepresentable(sourceType: .camera) { data in
                    selectedImageData = data
                }
                .ignoresSafeArea()
            }
        }
    }

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }
        // Final-pass profanity guard (defense in depth — ViewModel also checks)
        if ProfanityFilter.containsProfanity(text) {
            localProfanityFlagged = true
            return
        }
        let success = await viewModel.submitPost(
            text: text,
            imageData: selectedImageData,
            category: category,
            authorDisplayName: authorDisplayName,
            authorColorHex: authorColorHex
        )
        if success {
            dismiss()
        } else if viewModel.submitError == CommunityFeedViewModel.profanityRejectionMessage {
            localProfanityFlagged = true  // show inline profanity UI, not the network-error alert
        } else if viewModel.submitError != nil {
            showAlert = true
        }
    }
}

// MARK: - UIImagePickerController representable (camera source)
// Matches ProfileView.swift camera pattern (T-21-04-02 — camera permission gated by AVFoundation).

struct ImagePickerRepresentable: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (Data) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onImagePicked: onImagePicked) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImagePicked: (Data) -> Void
        init(onImagePicked: @escaping (Data) -> Void) { self.onImagePicked = onImagePicked }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                onImagePicked(data)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
