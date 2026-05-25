# Security: Audit Logging + Biometric Unlock — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 500-entry UserDefaults audit log for security-relevant events and an opt-in biometric app lock (Face ID / Touch ID).

**Architecture:** `SecurityAuditLog` is a singleton that writes `AuditEvent` structs to a UserDefaults JSON ring-buffer on a private serial queue. `BiometricLockService` is an `@Observable` singleton that wraps `LAContext`, tracks `isLocked` in memory, and resets to locked when the app backgrounds. `LockScreen` is a full-screen SwiftUI cover presented by `VitaminGApp` when `isLocked == true`.

**Tech Stack:** Swift, SwiftUI, Foundation (UserDefaults, Codable), LocalAuthentication (LAContext), XCTest.

**Spec:** `docs/superpowers/specs/2026-05-25-security-audit-logging-biometric-unlock-design.md`

**Note on DiscoverViewModel:** `DiscoverViewModel` does not exist yet (Phase 22). The `searchRateLimitHit` audit log call will be added to that file when Phase 22 creates it. All other call sites are implemented here.

---

## File Map

| Action | Path |
|--------|------|
| Create | `VitaminG/VitaminG/VitaminG/Services/SecurityAuditLog.swift` |
| Create | `VitaminGTests/SecurityAuditLogTests.swift` |
| Modify | `VitaminG/VitaminG/VitaminG/Services/BlockListService.swift` |
| Modify | `VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift` |
| Modify | `VitaminG/VitaminG/VitaminG/VitaminGApp.swift` |
| Create | `VitaminG/VitaminG/VitaminG/Services/BiometricLockService.swift` |
| Create | `VitaminGTests/BiometricLockServiceTests.swift` |
| Create | `VitaminG/VitaminG/VitaminG/Views/LockScreen.swift` |
| Modify | `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift` |
| Modify | `.planning/SECSOP.md` |

All paths are relative to `VitaminG/VitaminG/` (the Xcode project root).

---

## Task 1: SecurityAuditLog — Service + Tests

**Files:**
- Create: `VitaminG/VitaminG/VitaminG/Services/SecurityAuditLog.swift`
- Create: `VitaminGTests/SecurityAuditLogTests.swift`

- [ ] **Step 1.1: Write the failing tests first**

Create `VitaminGTests/SecurityAuditLogTests.swift`:

```swift
// VitaminGTests/SecurityAuditLogTests.swift
import XCTest
@testable import VitaminG

final class SecurityAuditLogTests: XCTestCase {

    private let key = "vg_audit_log"
    private let log = SecurityAuditLog.shared

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    func testLog_storesEvent() {
        let event = AuditEvent(eventType: .appLaunch)
        log.log(event)
        let events = log.recentEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].eventType, .appLaunch)
    }

    func testLog_ringBuffer_capsAt500() {
        for _ in 0..<510 {
            log.log(AuditEvent(eventType: .appLaunch))
        }
        let events = log.recentEvents(limit: 600)
        XCTAssertLessThanOrEqual(events.count, 500)
    }

    func testLog_preservesNewestEntries_whenCapped() {
        // Log 505 events; the last one has a distinct metadata key
        for i in 0..<504 {
            log.log(AuditEvent(eventType: .appLaunch, metadata: ["i": "\(i)"]))
        }
        log.log(AuditEvent(eventType: .userBlocked, targetUserID: "newest"))
        let events = log.recentEvents(limit: 600)
        XCTAssertEqual(events.last?.eventType, .userBlocked)
        XCTAssertEqual(events.last?.targetUserID, "newest")
    }

    func testLog_jsonRoundTrip() {
        let event = AuditEvent(eventType: .userBlocked, targetUserID: "uid-abc", metadata: ["reason": "spam"])
        log.log(event)
        let events = log.recentEvents()
        XCTAssertEqual(events.first?.targetUserID, "uid-abc")
        XCTAssertEqual(events.first?.metadata["reason"], "spam")
        XCTAssertEqual(events.first?.eventType, .userBlocked)
    }

    func testExport_returnsValidJSON() {
        log.log(AuditEvent(eventType: .appLaunch))
        let json = log.export()
        let data = json.data(using: .utf8)!
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }

    func testRecentEvents_limit() {
        for _ in 0..<10 {
            log.log(AuditEvent(eventType: .appLaunch))
        }
        let events = log.recentEvents(limit: 3)
        XCTAssertEqual(events.count, 3)
    }

    func testLog_corruptedDefaults_startsClean() {
        UserDefaults.standard.set("not-json".data(using: .utf8), forKey: key)
        log.log(AuditEvent(eventType: .appLaunch))
        let events = log.recentEvents()
        XCTAssertEqual(events.count, 1)
    }
}
```

- [ ] **Step 1.2: Run tests — expect build failure (types not defined yet)**

In Xcode: `Cmd+U` (or via terminal if xcodebuild is configured).
Expected: compile errors — `SecurityAuditLog`, `AuditEvent`, `AuditEventType` not found.

- [ ] **Step 1.3: Create SecurityAuditLog.swift**

Create `VitaminG/VitaminG/VitaminG/Services/SecurityAuditLog.swift`:

```swift
import Foundation

enum AuditEventType: String, Codable {
    case appLaunch
    case biometricUnlock
    case biometricFailed
    case profileEdited
    case userBlocked
    case userUnblocked
    case followWritten
    case followRateLimitHit
    case searchRateLimitHit
}

struct AuditEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let eventType: AuditEventType
    let actorUserID: String
    let targetUserID: String?
    let metadata: [String: String]

    init(
        eventType: AuditEventType,
        targetUserID: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.eventType = eventType
        self.actorUserID = UserDefaults.standard.string(forKey: "vg_appleUserID") ?? "unknown"
        self.targetUserID = targetUserID
        self.metadata = metadata
    }
}

final class SecurityAuditLog {
    static let shared = SecurityAuditLog()

    private let maxEntries = 500
    private let defaultsKey = "vg_audit_log"
    private let queue = DispatchQueue(label: "com.vg.audit", qos: .utility)

    private init() {}

    func log(_ event: AuditEvent) {
        queue.async { [self] in
            var events = loadEvents()
            events.append(event)
            if events.count > maxEntries {
                events = Array(events.suffix(maxEntries))
            }
            saveEvents(events)
        }
    }

    func recentEvents(limit: Int = 50) -> [AuditEvent] {
        queue.sync {
            Array(loadEvents().suffix(limit))
        }
    }

    func export() -> String {
        queue.sync {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? encoder.encode(loadEvents()),
                  let json = String(data: data, encoding: .utf8) else { return "[]" }
            return json
        }
    }

    private func loadEvents() -> [AuditEvent] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([AuditEvent].self, from: data)) ?? []
    }

    private func saveEvents(_ events: [AuditEvent]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(events) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }
}
```

- [ ] **Step 1.4: Run tests — expect all pass**

`Cmd+U`. All `SecurityAuditLogTests` cases should be green.

- [ ] **Step 1.5: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Services/SecurityAuditLog.swift \
        VitaminG/VitaminG/VitaminGTests/SecurityAuditLogTests.swift
git commit -m "feat: add SecurityAuditLog — UserDefaults ring-buffer with 9 event types"
```

---

## Task 2: Integrate Audit Log into BlockListService

**Files:**
- Modify: `VitaminG/VitaminG/VitaminG/Services/BlockListService.swift`

- [ ] **Step 2.1: Add audit log calls to blockUser and unblockUser**

In `BlockListService.swift`, modify `blockUser` and `unblockUser`:

```swift
/// Adds the given Apple User ID to the block list and persists it.
static func blockUser(appleUserID: String) {
    var ids = blockedUserIDs()
    ids.insert(appleUserID)
    if let data = try? JSONEncoder().encode(Array(ids)) {
        UserDefaults.standard.set(data, forKey: key)
    }
    SecurityAuditLog.shared.log(AuditEvent(eventType: .userBlocked, targetUserID: appleUserID))
}

/// Removes the given Apple User ID from the block list and persists the result.
static func unblockUser(appleUserID: String) {
    var ids = blockedUserIDs()
    ids.remove(appleUserID)
    if let data = try? JSONEncoder().encode(Array(ids)) {
        UserDefaults.standard.set(data, forKey: key)
    }
    SecurityAuditLog.shared.log(AuditEvent(eventType: .userUnblocked, targetUserID: appleUserID))
}
```

- [ ] **Step 2.2: Verify BlockListServiceTests still pass**

`Cmd+U`. The existing `BlockListServiceTests` suite must remain green. The audit log calls fire-and-forget; they do not affect block list behavior.

- [ ] **Step 2.3: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Services/BlockListService.swift
git commit -m "feat: log userBlocked/userUnblocked events to SecurityAuditLog"
```

---

## Task 3: Integrate Audit Log into ProfileSharingService + VitaminGApp Launch

**Files:**
- Modify: `VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift`
- Modify: `VitaminG/VitaminG/VitaminG/VitaminGApp.swift`

- [ ] **Step 3.1: Add profileEdited audit log to ProfileSharingService.publishProfile**

In `ProfileSharingService.swift`, after `let savedRecord = try await publicDB.save(record)`:

```swift
let savedRecord = try await publicDB.save(record)
SecurityAuditLog.shared.log(AuditEvent(eventType: .profileEdited))
return savedRecord.recordID.recordName
```

- [ ] **Step 3.2: Add appLaunch audit log to VitaminGApp**

In `VitaminGApp.swift`, inside the `.task {}` modifier (which already runs on first scene appear), add the audit log call as the first line:

```swift
.task {
    SecurityAuditLog.shared.log(AuditEvent(eventType: .appLaunch))
    // Schedule win reminder on launch (Phase 11, D-12)
    let isGranted = await NotificationScheduler.shared.isAuthorized()
    if isGranted {
        await NotificationScheduler.shared.rescheduleWinReminder()
        await NotificationScheduler.shared.reschedule(activeGoals: [])
    }
}
```

- [ ] **Step 3.3: Build — verify no compile errors**

`Cmd+B`. Confirm clean build. No new test failures expected (ProfileSharingService makes real CloudKit calls, untestable without network).

- [ ] **Step 3.4: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Services/ProfileSharingService.swift \
        VitaminG/VitaminG/VitaminG/VitaminGApp.swift
git commit -m "feat: log profileEdited and appLaunch events to SecurityAuditLog"
```

---

## Task 4: BiometricLockService + Tests

**Files:**
- Create: `VitaminG/VitaminG/VitaminG/Services/BiometricLockService.swift`
- Create: `VitaminGTests/BiometricLockServiceTests.swift`

- [ ] **Step 4.1: Write failing tests**

Create `VitaminGTests/BiometricLockServiceTests.swift`:

```swift
// VitaminGTests/BiometricLockServiceTests.swift
import XCTest
@testable import VitaminG

final class BiometricLockServiceTests: XCTestCase {

    private let enabledKey = "vg_biometric_lock_enabled"
    private let service = BiometricLockService.shared

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: enabledKey)
        service.isEnabled = false
        service.isLocked = false
    }

    override func tearDown() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        service.isLocked = false
        super.tearDown()
    }

    func testIsEnabled_defaultsFalse() {
        XCTAssertFalse(service.isEnabled)
    }

    func testIsEnabled_persistsToUserDefaults() {
        service.isEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: enabledKey))
        service.isEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: enabledKey))
    }

    func testLockIfEnabled_locksWhenEnabled() {
        service.isEnabled = true
        service.lockIfEnabled()
        XCTAssertTrue(service.isLocked)
    }

    func testLockIfEnabled_doesNotLockWhenDisabled() {
        service.isEnabled = false
        service.lockIfEnabled()
        XCTAssertFalse(service.isLocked)
    }

    func testIsLocked_defaultsFalse() {
        XCTAssertFalse(service.isLocked)
    }
}
```

- [ ] **Step 4.2: Run tests — expect build failure**

Expected: `BiometricLockService` not found.

- [ ] **Step 4.3: Create BiometricLockService.swift**

Create `VitaminG/VitaminG/VitaminG/Services/BiometricLockService.swift`:

```swift
import Foundation
import LocalAuthentication
import Observation

@Observable
final class BiometricLockService {
    static let shared = BiometricLockService()

    private let enabledKey = "vg_biometric_lock_enabled"

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }

    var isLocked: Bool = false

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
    }

    func lockIfEnabled() {
        if isEnabled {
            isLocked = true
        }
    }

    func authenticate() async {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            isLocked = false
            return
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Vitamin G"
            )
            if success {
                isLocked = false
                SecurityAuditLog.shared.log(AuditEvent(eventType: .biometricUnlock))
            }
        } catch {
            SecurityAuditLog.shared.log(
                AuditEvent(eventType: .biometricFailed,
                           metadata: ["error": error.localizedDescription])
            )
        }
    }
}
```

- [ ] **Step 4.4: Run tests — expect all pass**

`Cmd+U`. All `BiometricLockServiceTests` cases green.

- [ ] **Step 4.5: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Services/BiometricLockService.swift \
        VitaminG/VitaminG/VitaminGTests/BiometricLockServiceTests.swift
git commit -m "feat: add BiometricLockService — opt-in LAContext app lock with audit events"
```

---

## Task 5: LockScreen View + Wire into VitaminGApp

**Files:**
- Create: `VitaminG/VitaminG/VitaminG/Views/LockScreen.swift`
- Modify: `VitaminG/VitaminG/VitaminG/VitaminGApp.swift`

- [ ] **Step 5.1: Create LockScreen.swift**

Create `VitaminG/VitaminG/VitaminG/Views/LockScreen.swift`:

```swift
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
```

- [ ] **Step 5.2: Wire BiometricLockService into VitaminGApp**

In `VitaminGApp.swift`, add a stored property for the biometric service and `scenePhase` environment, then add `.fullScreenCover` and `.onChange(of: scenePhase)` to the `WindowGroup` body.

Add at the top of `VitaminGApp` struct (with the other stored properties):

```swift
private let biometricService = BiometricLockService.shared
```

Add `@Environment(\.scenePhase) private var scenePhase` as an `@Environment` property in the struct body:

```swift
@Environment(\.scenePhase) private var scenePhase
```

Modify the `WindowGroup` body to add `.fullScreenCover` and `.onChange` modifiers after the existing modifiers (after `.onOpenURL`):

```swift
.fullScreenCover(isPresented: Binding(
    get: { biometricService.isLocked },
    set: { _ in }
)) {
    LockScreen()
}
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .background || newPhase == .inactive {
        biometricService.lockIfEnabled()
    }
}
```

The final `VitaminGApp.swift` `body` property should look like:

```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
@AppStorage("vg_colorScheme") private var colorSchemePref: ColorSchemePreference = .system
@Environment(\.scenePhase) private var scenePhase

var body: some Scene {
    WindowGroup {
        Group {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        .modelContainer(container)
        .environment(router)
        .preferredColorScheme(colorSchemePref.colorScheme)
        .task {
            SecurityAuditLog.shared.log(AuditEvent(eventType: .appLaunch))
            let isGranted = await NotificationScheduler.shared.isAuthorized()
            if isGranted {
                await NotificationScheduler.shared.rescheduleWinReminder()
                await NotificationScheduler.shared.reschedule(activeGoals: [])
            }
        }
        .onOpenURL { url in
            if let recordID = DeepLinkParser.recordID(from: url) {
                router.pendingPublicProfileRecordID = recordID
            } else if let challengeID = DeepLinkParser.challengeCheckInID(from: url) {
                router.pendingChallengeCheckInID = challengeID
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { biometricService.isLocked },
            set: { _ in }
        )) {
            LockScreen()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                biometricService.lockIfEnabled()
            }
        }
    }
}
```

- [ ] **Step 5.3: Build — verify clean**

`Cmd+B`. Fix any compile errors before proceeding.

- [ ] **Step 5.4: Manual smoke test**

Run on simulator (iPhone 15, iOS 17):
1. Build and launch app
2. Go to Settings → Privacy section — biometric toggle not yet visible (added in Task 6)
3. Programmatically enable lock: in Xcode console, verify `BiometricLockService.shared.isEnabled` is false
4. Background the app and foreground it — no lock screen should appear (disabled by default)

- [ ] **Step 5.5: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Views/LockScreen.swift \
        VitaminG/VitaminG/VitaminG/VitaminGApp.swift
git commit -m "feat: add LockScreen and wire BiometricLockService into VitaminGApp scene lifecycle"
```

---

## Task 6: Biometric Toggle in SettingsView

**Files:**
- Modify: `VitaminG/VitaminG/VitaminG/Views/SettingsView.swift`

- [ ] **Step 6.1: Add biometric toggle to Privacy section**

In `SettingsView.swift`, the Privacy section currently reads:

```swift
Section("Privacy") {
    if let profile = profileVM.profile {
        Toggle("Public Profile", isOn: Binding(
            get: { profile.isPublic },
            set: { _ in
                profileVM.toggleProfilePublic(context: modelContext)
            }
        ))
    } else {
        Toggle("Public Profile", isOn: .constant(false))
            .disabled(true)
    }
}
```

Replace it with:

```swift
Section("Privacy") {
    if let profile = profileVM.profile {
        Toggle("Public Profile", isOn: Binding(
            get: { profile.isPublic },
            set: { _ in
                profileVM.toggleProfilePublic(context: modelContext)
            }
        ))
    } else {
        Toggle("Public Profile", isOn: .constant(false))
            .disabled(true)
    }

    let bioService = BiometricLockService.shared
    @Bindable var bindableBioService = bioService
    Toggle("Require Face ID / Touch ID", isOn: $bindableBioService.isEnabled)
}
```

- [ ] **Step 6.2: Build — verify clean**

`Cmd+B`. Confirm no compile errors.

- [ ] **Step 6.3: Run SettingsViewTests**

`Cmd+U`. Existing `SettingsViewTests` must remain green.

- [ ] **Step 6.4: Manual test of toggle**

Run on simulator:
1. Open Settings → Privacy
2. Toggle "Require Face ID / Touch ID" ON
3. Background the app (press Home)
4. Foreground the app
5. Simulator will show authentication dialog (or auto-pass in simulator)
6. Toggle OFF — repeat background/foreground — no lock screen appears

- [ ] **Step 6.5: Commit**

```bash
git add VitaminG/VitaminG/VitaminG/Views/SettingsView.swift
git commit -m "feat: add biometric lock toggle to Settings Privacy section"
```

---

## Task 7: Update SECSOP.md

**Files:**
- Modify: `.planning/SECSOP.md`

- [ ] **Step 7.1: Append Sections 10 and 11 to SECSOP.md**

Append the following to `.planning/SECSOP.md` (before the final `*Maintained by...` line):

```markdown
---

## 10. Audit Event Logging

`SecurityAuditLog.shared.log(_:)` is called at all security-relevant call sites. Events are
written to a UserDefaults JSON ring-buffer (key: `vg_audit_log`, max 500 entries) on a private
serial queue. Events survive app restart within the 500-entry window. Not synced to iCloud.

| Event | Call Site |
|-------|-----------|
| `.appLaunch` | `VitaminGApp` `.task` |
| `.userBlocked` | `BlockListService.blockUser(appleUserID:)` |
| `.userUnblocked` | `BlockListService.unblockUser(appleUserID:)` |
| `.profileEdited` | `ProfileSharingService.publishProfile()` on success |
| `.followWritten` | `ProfileSharingService.writeFollow()` on success (Phase 22) |
| `.followRateLimitHit` | `ProfileSharingService.writeFollow()` on 429 throw (Phase 22) |
| `.searchRateLimitHit` | `DiscoverViewModel.onSearchTextChanged` on cap hit (Phase 22) |
| `.biometricUnlock` | `BiometricLockService.authenticate()` on success |
| `.biometricFailed` | `BiometricLockService.authenticate()` on LAError |

**Control:** `SecurityAuditLog` (Services/SecurityAuditLog.swift)
**Verify:** `grep -c "SecurityAuditLog.shared.log" VitaminG/VitaminG/VitaminG/Services/BlockListService.swift` ≥ 2

---

## 11. Biometric App Lock

`BiometricLockService` (Services/BiometricLockService.swift) provides an opt-in Face ID / Touch ID
lock gate. When enabled (UserDefaults key: `vg_biometric_lock_enabled`), `VitaminGApp` calls
`lockIfEnabled()` on `scenePhase` becoming `.background` or `.inactive`. `LockScreen` is
presented via `.fullScreenCover` while `isLocked == true`. Uses
`LAPolicy.deviceOwnerAuthentication` — falls back to device passcode if biometrics unavailable.
Defaults to OFF.

**Control:** `BiometricLockService` singleton + `VitaminGApp` scene phase observer.
**Verify:** Settings → Privacy → "Require Face ID / Touch ID" toggle visible. Enable → background → foreground → auth prompt appears.
```

Update the threat model table in Section 8 to add these two rows:

```markdown
| No incident reconstruction | SecurityAuditLog 500-event ring buffer | Phase 22+ |
| Device sharing / shoulder surfing | BiometricLockService opt-in gate | Phase 22+ |
```

- [ ] **Step 7.2: Commit**

```bash
git add .planning/SECSOP.md
git commit -m "docs(secsop): add sections 10 and 11 — audit logging and biometric lock"
```

---

## Task 8: Full Test Suite Pass

- [ ] **Step 8.1: Run all tests**

`Cmd+U`. All test suites must pass:
- `SecurityAuditLogTests` — 7 tests
- `BiometricLockServiceTests` — 5 tests
- `BlockListServiceTests` — 5 tests (existing, unchanged)
- All other existing suites — unchanged

- [ ] **Step 8.2: If any failures, fix before marking done**

Common pitfalls:
- Singleton state leaking between tests: confirm `setUp`/`tearDown` clear `vg_audit_log` and `vg_biometric_lock_enabled` keys
- `@Bindable` compile error in SettingsView: ensure `@Bindable var bindableBioService = bioService` is inside the `body` computed property, not as a `@State` property
- `scenePhase` not found: confirm `import SwiftUI` in VitaminGApp and that `@Environment(\.scenePhase)` is declared at struct scope (not inside `body`)

---

## Phase 22 Integration Note

When Phase 22 creates `DiscoverViewModel`, add this call where the search rate limit is enforced:

```swift
// Inside onSearchTextChanged, after the rate-limit guard fires:
SecurityAuditLog.shared.log(AuditEvent(eventType: .searchRateLimitHit))
```

And in `ProfileSharingService.writeFollow` where the 429 is thrown:

```swift
SecurityAuditLog.shared.log(AuditEvent(eventType: .followRateLimitHit))
```

And on successful follow write:

```swift
SecurityAuditLog.shared.log(AuditEvent(eventType: .followWritten, targetUserID: followeeUsername))
```
