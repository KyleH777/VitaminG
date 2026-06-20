import SwiftUI
import SwiftData

// MARK: - BuddyAccountabilityModuleView (CHAL-22)
//
// Sheet that lets the user opt in a contact via the system contact picker (no permission prompt),
// persist the buddy's displayName to UserChallenge, and send a local ping notification with
// 24-hour cooldown enforcement.
//
// UI-SPEC: Section 2.3 — Buddy Accountability Module
// Patterns: sheet-on-sheet via .sheet(isPresented:) on NavigationStack (iOS 17 supported)
// Cooldown gate: delegates to UserChallenge.canSendBuddyPing (single source of truth)
// Privacy: displayName only — no phone or email stored (T-14-30)

struct BuddyAccountabilityModuleView: View {
    let userChallenge: UserChallenge

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var showPicker = false
    @State private var pingSent = false

    private var accentColor: Color {
        Color(hex: userChallenge.template?.accentColorHex ?? "#C4673A")
    }

    private var challengeTitle: String {
        userChallenge.template?.title ?? "your challenge"
    }

    private var buddyName: String? {
        let value = userChallenge.buddyDisplayName ?? ""
        return value.isEmpty ? nil : value
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let name = buddyName {
                        configuredState(name: name)
                    } else {
                        unconfiguredState
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            .background(VGTheme.sandLight)
            .navigationTitle("Accountability Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.body.weight(.semibold))
                        .fontDesign(.rounded)
                }
            }
            .sheet(isPresented: $showPicker) {
                ContactPickerRepresentable { selected in
                    saveBuddy(displayName: selected)
                    showPicker = false
                }
                .ignoresSafeArea()
            }
        }
    }

    // MARK: - Unconfigured state (buddyDisplayName is nil or empty)

    private var unconfiguredState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(VGTheme.muted)
                .accessibilityHidden(true)

            Text("Add an Accountability Buddy")
                .font(.title2.weight(.semibold))
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.clay)

            Text("Choose a contact to receive a ping when you need encouragement.")
                .font(.body)
                .fontDesign(.rounded)
                .foregroundStyle(VGTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Choose Contact") {
                showPicker = true
            }
            .font(.body.weight(.semibold))
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 8)
        }
    }

    // MARK: - Configured state (buddyDisplayName is non-empty)

    private func configuredState(name: String) -> some View {
        VStack(spacing: 16) {
            // Buddy identity row
            HStack(spacing: 12) {
                AvatarView(
                    displayName: name,
                    avatarColorHex: nil,
                    photoData: nil,
                    size: 32
                )
                Text(name)
                    .font(.body.weight(.semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.clay)
                Spacer()
                Button("Change") { showPicker = true }
                    .font(.caption.weight(.regular))
                    .fontDesign(.rounded)
                    .foregroundStyle(VGTheme.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Ping button — T-14-32: disabled when !canSendBuddyPing (24h cooldown)
            Button(pingSent ? "Ping Sent!" : "Ping \(name)") {
                Task { await sendPing(name: name) }
            }
            .font(.body.weight(.semibold))
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(!userChallenge.canSendBuddyPing || pingSent)
            .accessibilityLabel(pingSent
                ? "Ping sent. Available again in 24 hours."
                : "Ping \(name)")

            // Remove Buddy — UI-SPEC: NOT a data delete (just opt-out), muted color, no destructive role
            Button("Remove Buddy") {
                removeBuddy()
            }
            .font(.body)
            .fontDesign(.rounded)
            .foregroundStyle(VGTheme.muted)
        }
    }

    // MARK: - Mutations

    private func saveBuddy(displayName: String) {
        userChallenge.buddyDisplayName = displayName
        try? modelContext.save()
    }

    private func removeBuddy() {
        userChallenge.buddyDisplayName = nil
        userChallenge.buddyPingLastSent = nil
        try? modelContext.save()
    }

    private func sendPing(name: String) async {
        await NotificationScheduler.shared.scheduleBuddyPing(
            challengeID: userChallenge.id,
            buddyDisplayName: name,
            challengeTitle: challengeTitle
        )
        userChallenge.buddyPingLastSent = Date()
        try? modelContext.save()
        pingSent = true
        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run { pingSent = false }
        }
    }
}
