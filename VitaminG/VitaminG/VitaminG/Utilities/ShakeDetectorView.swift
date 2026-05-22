import SwiftUI
import UIKit

/// A zero-size UIViewControllerRepresentable that listens for device shake gestures.
/// Place as a .background or overlay in ExploreView so it always holds first-responder
/// focus. becomeFirstResponder() is called in viewDidAppear (NOT viewDidLoad) to
/// re-acquire focus after NavigationLink push/pop cycles.
struct ShakeDetectorView: UIViewControllerRepresentable {
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeVC {
        let vc = ShakeVC()
        vc.onShake = onShake
        return vc
    }

    func updateUIViewController(_ uiViewController: ShakeVC, context: Context) {}
}

final class ShakeVC: UIViewController {
    var onShake: (() -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            onShake?()
        }
    }
}
