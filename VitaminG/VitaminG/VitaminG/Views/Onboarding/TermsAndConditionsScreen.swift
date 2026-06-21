import SwiftUI
import QuickLook

// MARK: - TermsAndConditionsScreen
// Onboarding Screen 1: T&C acknowledgment (step 0 of 7).
// Opens the bundled PDF via QuickLook; "I Agree — Continue" persists acceptance and advances to .name.

struct TermsAndConditionsScreen: View {

    @Binding var path: [OnboardingStep]
    let onSkip: () -> Void

    @AppStorage("vg_hasAgreedToTerms") private var hasAgreedToTerms: Bool = false
    @State private var showTerms = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VGTheme.sandLight
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Nav row — mirrors NameScreen lines 22-31
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

                // Step bar — T&C is step 0 in the 7-step flow
                StepBarView(current: 0, total: 7)
                    .padding(.bottom, 28)

                // Headline
                Text("Before we begin")
                    .font(Font.custom("Georgia", size: 42))
                    .foregroundStyle(VGTheme.clay)
                    .lineSpacing(4)
                    .padding(.bottom, 12)
                    .accessibilityAddTraits(.isHeader)

                // Subtitle
                Text("Please read and agree to our Terms & Conditions to continue using Vitamin G.")
                    .font(.callout.weight(.light))
                    .foregroundStyle(VGTheme.muted)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)

                // "Read Terms" outlined capsule button
                Button(action: { showTerms = true }) {
                    Text("Read Terms")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(VGTheme.clay)
                        .frame(minHeight: 44)
                        .padding(.horizontal, 20)
                        .overlay(
                            Capsule()
                                .strokeBorder(VGTheme.sandMid, lineWidth: 1)
                        )
                }
                .clipShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Bottom CTA — pinned to bottom, mirrors NameScreen lines 88-101
            VStack(spacing: 8) {
                Button(action: agree) {
                    Text("I Agree — Continue")
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
        .onAppear { }
        .sheet(isPresented: $showTerms) {
            // T-17-02-02: if-let guard — never force-unwrap termsURL
            if let url = termsURL {
                PDFPreviewView(url: url)
                    .ignoresSafeArea()
                    .presentationDetents([.large])
            }
        }
    }

    // MARK: - Private

    private var termsURL: URL? {
        Bundle.main.url(forResource: "Vitamin_G_Terms_and_Conditions_v2", withExtension: "pdf")
    }

    private func agree() {
        hasAgreedToTerms = true
        path.append(.name)
    }
}

// MARK: - PDFPreviewView
// Wraps QLPreviewController in UIViewControllerRepresentable to display a PDF via QuickLook.

struct PDFPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController,
                               previewItemAt index: Int) -> any QLPreviewItem {
            url as NSURL
        }
    }
}
