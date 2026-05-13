import SwiftUI
#if canImport(ContactsUI)
import ContactsUI
#endif

// MARK: - ContactPickerRepresentable
//
// UIViewControllerRepresentable bridge for CNContactPickerViewController.
// Wraps picker in UINavigationController per RESEARCH.md Pitfall 8 (blank-sheet bug prevention).
// No NSContactsUsageDescription required — system picker provides read-only access to selected
// contact only, without a permission prompt (RESEARCH.md Anti-Patterns A3).
// Only displayName (givenName + familyName) is passed to caller — no phone, email, or other PII.
// T-14-29 mitigation: displayName is sanitized via InputSanitizer.sanitize before invoking callback.
// T-14-30 mitigation: CNContact.phoneNumbers, emailAddresses, etc. are never accessed.

struct ContactPickerRepresentable: UIViewControllerRepresentable {
    var onContactSelected: (String) -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        // Wrap in UINavigationController per RESEARCH.md Pitfall 8 (blank-sheet bug)
        return UINavigationController(rootViewController: picker)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onContactSelected: onContactSelected)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onContactSelected: (String) -> Void

        init(onContactSelected: @escaping (String) -> Void) {
            self.onContactSelected = onContactSelected
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // Extract only givenName + familyName — no phone, email, or other PII (T-14-30)
            let raw = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            // T-14-29: sanitize via InputSanitizer to strip control characters and trim
            let sanitized = InputSanitizer.sanitize(raw)
            let final = sanitized.isEmpty ? "Buddy" : sanitized
            onContactSelected(final)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // No-op — sheet dismisses automatically
        }
    }
}
