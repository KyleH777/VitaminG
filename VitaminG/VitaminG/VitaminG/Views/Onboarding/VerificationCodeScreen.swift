import SwiftUI

// MARK: - VerificationCodeScreen
// Onboarding: OTP 6-digit code entry after phone/email submission.
// Simulated verification (any 6-digit code passes) — wire to real SMS/email
// provider (Firebase Auth, Twilio, etc.) before production.

struct VerificationCodeScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_signupPhone")    private var storedPhone:    String = ""
    @AppStorage("vg_signupEmail")    private var storedEmail:    String = ""
    @AppStorage("vg_signupDialCode") private var storedDialCode: String = "+1"
    @AppStorage("vg_useEmailSignup") private var useEmail:       Bool   = false

    @State private var otpInput:       String = ""
    @State private var isVerifying:    Bool   = false
    @State private var showError:      Bool   = false
    @State private var resendSeconds:  Int    = 30
    @State private var canResend:      Bool   = false

    @FocusState private var inputActive: Bool

    private var digits: [String] {
        let padded = otpInput.padding(toLength: 6, withPad: " ", startingAt: 0)
        return padded.map { $0 == " " ? "" : String($0) }
    }

    private var isComplete: Bool { otpInput.count == 6 }

    private var maskedTarget: String {
        if useEmail {
            let parts = storedEmail.components(separatedBy: "@")
            guard parts.count == 2 else { return storedEmail }
            let local = parts[0]
            let domain = parts[1]
            let masked = String(local.prefix(2)) + String(repeating: "•", count: max(0, local.count - 2))
            return "\(masked)@\(domain)"
        } else {
            let nums = storedPhone.filter(\.isNumber)
            guard nums.count >= 4 else { return "\(storedDialCode) \(storedPhone)" }
            return "\(storedDialCode) ••••\(nums.suffix(4))"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: { path.removeLast() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(VGTheme.clay)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)

                StepBarView(current: 0, total: 4)
                    .padding(.bottom, 28)

                Text("Enter the code.")
                    .font(Font.custom("Georgia", size: 40))
                    .foregroundStyle(VGTheme.clay)
                    .padding(.bottom, 10)

                (Text("We sent a 6-digit code to ")
                    .foregroundStyle(VGTheme.muted)
                + Text(maskedTarget)
                    .foregroundStyle(VGTheme.clay)
                    .fontWeight(.semibold))
                .font(.system(size: 14, weight: .light))
                .lineSpacing(3)
                .padding(.bottom, 36)

                // Digit boxes — tapping any box activates the hidden field
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        OTPDigitBox(
                            digit: digits[i],
                            isActive: inputActive && (otpInput.count == i || (i == 5 && otpInput.count == 6)),
                            hasError: showError
                        )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { inputActive = true }
                .padding(.bottom, 6)

                // Hidden capture field
                TextField("", text: $otpInput)
                    .focused($inputActive)
                    .keyboardType(.numberPad)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .onChange(of: otpInput) { _, new in
                        let filtered = String(new.filter(\.isNumber).prefix(6))
                        if filtered != new { otpInput = filtered }
                        showError = false
                        if filtered.count == 6 { verify() }
                    }

                if showError {
                    Text("That code didn't match. Please try again.")
                        .font(.system(size: 13))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.top, 10)
                }

                // Resend row
                HStack {
                    if canResend {
                        Button("Resend code") { resend() }
                            .font(.system(size: 14))
                            .foregroundStyle(VGTheme.terra)
                    } else {
                        Text("Resend in \(resendSeconds)s")
                            .font(.system(size: 14))
                            .foregroundStyle(VGTheme.muted)
                    }
                }
                .padding(.top, 18)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Verify button
            Button(action: verify) {
                HStack(spacing: 10) {
                    if isVerifying {
                        ProgressView()
                            .tint(VGTheme.warmWhite)
                            .scaleEffect(0.9)
                    }
                    Text(isVerifying ? "Verifying…" : "Verify")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isComplete ? VGTheme.terra : VGTheme.sandMid)
                .foregroundStyle(isComplete ? VGTheme.warmWhite : VGTheme.sandDeep)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isComplete || isVerifying)
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { inputActive = true }
            startCountdown()
        }
    }

    // MARK: - Actions

    private func verify() {
        guard isComplete, !isVerifying else { return }
        isVerifying = true
        showError   = false

        // Simulated verification: accepts any 6-digit code.
        // Wire mockVerify → real SMS/email OTP check in production.
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            await MainActor.run {
                isVerifying = false
                path.append(.motivationCategories)
            }
        }
    }

    private func resend() {
        canResend    = false
        resendSeconds = 30
        otpInput     = ""
        showError    = false
        inputActive  = true
        startCountdown()
        // Call real SMS/email resend API here in production.
    }

    private func startCountdown() {
        Task {
            while resendSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                await MainActor.run { resendSeconds -= 1 }
            }
            await MainActor.run { canResend = true }
        }
    }
}

// MARK: - OTPDigitBox
private struct OTPDigitBox: View {
    let digit:    String
    let isActive: Bool
    let hasError: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(digit.isEmpty ? VGTheme.sandLight : VGTheme.warmWhite)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            hasError    ? Color.red.opacity(0.7) :
                            isActive    ? VGTheme.terra :
                                         VGTheme.sandMid,
                            lineWidth: isActive ? 2 : 1.5
                        )
                )

            if digit.isEmpty && isActive {
                Capsule()
                    .fill(VGTheme.terra)
                    .frame(width: 2, height: 22)
            } else if !digit.isEmpty {
                Text(digit)
                    .font(Font.custom("Georgia", size: 26))
                    .foregroundStyle(VGTheme.clay)
            }
        }
        .frame(width: 46, height: 58)
        .animation(.easeInOut(duration: 0.12), value: isActive)
    }
}
