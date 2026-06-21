import SwiftUI

struct LockScreen: View {
    @State private var errorMessage: String?
    private let service = BiometricLockService.shared

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(VGTheme.accentTerra)
                .accessibilityHidden(true)

            Text("Vitamin G")
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)

            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .accessibilityLiveRegion(.polite)
            }

            Button("Unlock with Face ID or Touch ID") {
                errorMessage = nil
                Task {
                    await service.authenticate()
                    if service.isLocked {
                        errorMessage = "Authentication failed. Try again."
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(VGTheme.accentTerra)
            .accessibilityHint("Authenticates using biometrics to open the app")

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
