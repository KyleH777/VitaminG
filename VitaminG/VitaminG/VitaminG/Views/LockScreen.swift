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

            Text("Vitamin G")
                .font(.title.bold())

            if let error = errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Unlock") {
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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
