import SwiftUI

// MARK: - CountryCode
private struct CountryCode: Identifiable, Hashable {
    let id: String
    let flag: String
    let dialCode: String
    let name: String
}

// MARK: - PhoneSignupScreen
// Onboarding: Phone/email entry — "Hello." screen matching Vitamin G design spec.
// Step 1 of 4.

struct PhoneSignupScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_signupPhone")    private var storedPhone:    String = ""
    @AppStorage("vg_signupEmail")    private var storedEmail:    String = ""
    @AppStorage("vg_signupDialCode") private var storedDialCode: String = "+1"
    @AppStorage("vg_useEmailSignup") private var useEmail:       Bool   = false

    @State private var phone:           String = ""
    @State private var email:           String = ""
    @State private var selectedDialCode: String = "+1"
    @State private var showCountryPicker = false

    @FocusState private var fieldFocused: Bool

    private let countryCodes: [CountryCode] = [
        CountryCode(id: "US", flag: "🇺🇸", dialCode: "+1",   name: "United States"),
        CountryCode(id: "CA", flag: "🇨🇦", dialCode: "+1",   name: "Canada"),
        CountryCode(id: "GB", flag: "🇬🇧", dialCode: "+44",  name: "United Kingdom"),
        CountryCode(id: "AU", flag: "🇦🇺", dialCode: "+61",  name: "Australia"),
        CountryCode(id: "IN", flag: "🇮🇳", dialCode: "+91",  name: "India"),
        CountryCode(id: "DE", flag: "🇩🇪", dialCode: "+49",  name: "Germany"),
        CountryCode(id: "FR", flag: "🇫🇷", dialCode: "+33",  name: "France"),
        CountryCode(id: "NG", flag: "🇳🇬", dialCode: "+234", name: "Nigeria"),
        CountryCode(id: "JP", flag: "🇯🇵", dialCode: "+81",  name: "Japan"),
        CountryCode(id: "BR", flag: "🇧🇷", dialCode: "+55",  name: "Brazil"),
        CountryCode(id: "MX", flag: "🇲🇽", dialCode: "+52",  name: "Mexico"),
        CountryCode(id: "ZA", flag: "🇿🇦", dialCode: "+27",  name: "South Africa"),
    ]

    private var selectedCountry: CountryCode {
        countryCodes.first { $0.id == "US" && selectedDialCode == "+1" } ??
        countryCodes.first { $0.dialCode == selectedDialCode } ??
        countryCodes[0]
    }

    private var canContinue: Bool {
        if useEmail {
            let t = email.trimmingCharacters(in: .whitespaces)
            return t.contains("@") && t.contains(".") && t.count >= 5
        } else {
            return phone.filter(\.isNumber).count >= 7
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight.ignoresSafeArea()

            ScrollView {
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

                    Text(useEmail ? "What's your\nemail?" : "What's your\nnumber?")
                        .font(Font.custom("Georgia", size: 42))
                        .foregroundStyle(VGTheme.clay)
                        .lineSpacing(2)
                        .animation(.easeInOut(duration: 0.15), value: useEmail)
                        .padding(.bottom, 8)

                    Text(useEmail ? "We'll email you a code to verify it's you." : "We'll text you a code to verify it's really you.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(VGTheme.muted)
                        .lineSpacing(3)
                        .animation(.easeInOut(duration: 0.15), value: useEmail)
                        .padding(.bottom, 32)

                    if useEmail {
                        emailField
                    } else {
                        phoneField
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { useEmail.toggle() }
                        fieldFocused = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { fieldFocused = true }
                    } label: {
                        Text(useEmail ? "Use phone number instead" : "Use email instead")
                            .font(.system(size: 14))
                            .foregroundStyle(VGTheme.terra)
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 140)
            }

            // Bottom CTA
            VStack(spacing: 10) {
                Button(action: advance) {
                    Text("Send verification code")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(canContinue ? VGTheme.terra : VGTheme.sandMid)
                        .foregroundStyle(canContinue ? VGTheme.warmWhite : VGTheme.sandDeep)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canContinue)

                Text("By continuing you agree to our Terms & Privacy Policy.")
                    .font(.system(size: 11))
                    .foregroundStyle(VGTheme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 36)
            .background(
                VGTheme.sandLight
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(codes: countryCodes, selected: $selectedDialCode)
        }
        .navigationBarHidden(true)
        .onAppear {
            phone = storedPhone
            email = storedEmail
            selectedDialCode = storedDialCode
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { fieldFocused = true }
        }
    }

    // MARK: - Phone field
    @ViewBuilder
    private var phoneField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MOBILE NUMBER")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(VGTheme.muted)
                .kerning(1.5)
                .padding(.bottom, 8)

            HStack(alignment: .bottom, spacing: 12) {
                Button { showCountryPicker = true } label: {
                    HStack(spacing: 5) {
                        Text(selectedCountry.flag)
                            .font(.system(size: 20))
                        Text(selectedCountry.dialCode)
                            .font(Font.custom("Georgia", size: 22))
                            .foregroundStyle(VGTheme.muted)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(VGTheme.muted)
                    }
                }
                .padding(.bottom, 12)

                HStack(alignment: .bottom, spacing: 0) {
                    TextField("", text: $phone)
                        .font(Font.custom("Georgia", size: 32))
                        .foregroundStyle(VGTheme.clay)
                        .focused($fieldFocused)
                        .keyboardType(.phonePad)
                        .onChange(of: phone) { _, new in
                            let digits = new.filter(\.isNumber)
                            if digits.count > 15 {
                                phone = String(new.dropLast(digits.count - 15))
                            }
                        }

                    if phone.isEmpty {
                        Capsule()
                            .fill(VGTheme.terra)
                            .frame(width: 2, height: 26)
                            .opacity(fieldFocused ? 1 : 0)
                    }
                }
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
            }

            Rectangle().fill(VGTheme.terra).frame(height: 2)

            // Trust badge
            HStack(alignment: .top, spacing: 10) {
                Text("🛡️")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Why phone?")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(VGTheme.clay)
                    Text("It keeps spam & bot accounts out of the community.")
                        .font(.system(size: 11))
                        .foregroundStyle(VGTheme.clay)
                        .lineSpacing(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(VGTheme.terraLight)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(VGTheme.terraSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.top, 10)
        }
    }

    // MARK: - Email field
    @ViewBuilder
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EMAIL ADDRESS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(VGTheme.muted)
                .kerning(1.5)
                .padding(.bottom, 8)

            HStack(alignment: .bottom, spacing: 0) {
                TextField("", text: $email)
                    .font(Font.custom("Georgia", size: 30))
                    .foregroundStyle(VGTheme.clay)
                    .focused($fieldFocused)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { advance() }
                    .onChange(of: email) { _, new in
                        if new.count > 254 { email = String(new.prefix(254)) }
                    }

                if email.isEmpty {
                    Capsule()
                        .fill(VGTheme.terra)
                        .frame(width: 2, height: 26)
                        .opacity(fieldFocused ? 1 : 0)
                }
            }
            .padding(.bottom, 12)

            Rectangle().fill(VGTheme.terra).frame(height: 2)
        }
    }

    // MARK: - Advance
    private func advance() {
        guard canContinue else { return }
        if useEmail {
            storedEmail    = String(email.trimmingCharacters(in: .whitespaces).prefix(254))
        } else {
            storedPhone    = phone
            storedDialCode = selectedDialCode
        }
        path.append(.verificationCode)
    }
}

// MARK: - CountryPickerSheet
private struct CountryPickerSheet: View {
    let codes: [CountryCode]
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(codes) { code in
                Button {
                    selected = code.dialCode
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Text(code.flag).font(.system(size: 24))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(code.name)
                                .font(.system(size: 15))
                                .foregroundStyle(VGTheme.clay)
                            Text(code.dialCode)
                                .font(.system(size: 12))
                                .foregroundStyle(VGTheme.muted)
                        }
                        Spacer()
                        if selected == code.dialCode {
                            Image(systemName: "checkmark")
                                .foregroundStyle(VGTheme.terra)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .listRowBackground(VGTheme.sandLight)
            }
            .scrollContentBackground(.hidden)
            .background(VGTheme.sandLight)
            .navigationTitle("Country Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(VGTheme.terra)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
