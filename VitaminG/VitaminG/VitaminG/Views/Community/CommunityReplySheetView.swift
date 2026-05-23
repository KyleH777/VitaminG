import SwiftUI

// MARK: - CommunityReplySheetView
//
// CloudKit-backed reply sheet for global community feed posts (D-08 / COMM-06).
// Uses a closure injection pattern for testability — no direct CloudKit call in the view.
// In production: onWriteReply wraps CommunityService.writeReply.
// In tests: a mock closure is injected that checks profanity and captures text.
//
// Security (T-21-04-01): ProfanityFilter gate fires in submit() before any write.
// InputSanitizer.sanitizeForPublic applied in submit() before onWriteReply call.
// Security (T-21-04-04): Hard 300-char cap enforced via .onChange and String.prefix(300).

struct CommunityReplySheetView: View {
    let parentPostID: String
    let authorDisplayName: String?
    let authorColorHex: String?

    /// Closure injected by the caller — wraps CommunityService.writeReply in production.
    /// Receives the sanitized, profanity-checked text and returns true on success.
    let onWriteReply: (String) async -> Bool

    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var isSubmitting = false
    @State private var localProfanityFlagged = false
    @State private var showAlert = false

    static let maxChars = 300
    private static let placeholder = "Write a reply..."

    private var isPostEnabled: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !localProfanityFlagged
            && !isSubmitting
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Text editor with placeholder
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
                                .frame(minHeight: 100)
                                .scrollContentBackground(.hidden)
                        }
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(localProfanityFlagged ? Color.red : Color.clear, lineWidth: 1)
                        )

                        // Character counter — shown when approaching limit (D-10 pattern)
                        if text.count > 250 {
                            Text("\(text.count)/\(Self.maxChars)")
                                .font(.system(size: 14)).fontDesign(.rounded)
                                .foregroundStyle(VGTheme.textMuted)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }

                    // Profanity rejection inline error
                    if localProfanityFlagged {
                        Text("Profanity detected. Please revise.")
                            .font(.caption).fontDesign(.rounded)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(VGTheme.sandLight)
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.body).fontDesign(.rounded)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post Reply") {
                        Task { await submit() }
                    }
                    .font(.body.weight(.semibold)).fontDesign(.rounded)
                    .foregroundStyle(isPostEnabled ? VGTheme.accentTerra : VGTheme.textMuted)
                    .disabled(!isPostEnabled)
                }
            }
            .onChange(of: text) { _, newValue in
                // Hard cap at 300 chars (T-21-04-04 mitigation)
                if newValue.count > Self.maxChars {
                    text = String(newValue.prefix(Self.maxChars))
                }
                // Re-evaluate profanity on every keystroke
                localProfanityFlagged = ProfanityFilter.containsProfanity(newValue)
            }
            .alert("Reply Failed", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Reply failed. Check your connection and try again.")
            }
        }
    }

    // MARK: - Submit

    private func submit() async {
        isSubmitting = true
        defer { isSubmitting = false }

        // Profanity gate — T-21-04-01 mitigation (defense in depth before any write)
        guard !ProfanityFilter.containsProfanity(text) else {
            localProfanityFlagged = true
            return
        }

        // Sanitize text for public CloudKit write (T-21-04-01 mitigation)
        let sanitized = InputSanitizer.sanitizeForPublic(text)

        let success = await onWriteReply(sanitized)
        if success {
            dismiss()
        } else {
            showAlert = true
        }
    }
}
