# Security: Audit Logging + Biometric Unlock — Design Spec

**Date:** 2026-05-25
**Status:** Approved
**Scope:** Two new security features for Vitamin G iOS app

---

## Background

A security audit of the Vitamin G codebase identified two gaps not covered by existing controls
(InputSanitizer, rate limiting, Apple Sign-In, SECSOP.md):

1. No audit trail for sensitive user actions (block/unblock, profile edits, rate limit hits)
2. No biometric app lock for users who want an extra privacy layer

Rate limiting and security documentation were already addressed in Phase 22 plans and SECSOP.md v1.0.

---

## Feature 1 — Security Audit Log

### Goal

Persist a local ring-buffer of security-relevant events so that incidents can be reconstructed
after the fact. Scoped to on-device only; does not sync to CloudKit.

### Data Model

```swift
struct AuditEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let eventType: AuditEventType
    let actorUserID: String       // Apple User ID — not display name
    let targetUserID: String?     // set for block/unblock/follow events
    let metadata: [String: String]
}

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
```

### Service Interface

```swift
// Services/SecurityAuditLog.swift
final class SecurityAuditLog {
    static let shared = SecurityAuditLog()
    private let maxEntries = 500
    private let defaultsKey = "vg_audit_log"

    func log(_ event: AuditEvent)
    func recentEvents(limit: Int = 50) -> [AuditEvent]
    func export() -> String  // JSON string for support/debug
}
```

**Storage:** UserDefaults JSON array. On each `log()` call:
1. Decode existing array (or start empty)
2. Append new event
3. Trim to last 500 entries
4. Encode and write back

**Thread safety:** All reads/writes dispatched on a private serial `DispatchQueue`.

**`actorUserID` resolution:** `SecurityAuditLog` reads `UserDefaults.standard.string(forKey: "vg_appleUserID")` internally on each `log()` call — callers do not need to supply it. Falls back to `"unknown"` if not yet set (pre-login).

### Call Sites

| Event | Location |
|-------|----------|
| `.userBlocked` | `BlockListService.blockUser(appleUserID:)` |
| `.userUnblocked` | `BlockListService.unblockUser(appleUserID:)` |
| `.profileEdited` | `ProfileSharingService.publishProfile()` |
| `.followWritten` | `ProfileSharingService.writeFollow()` on success |
| `.followRateLimitHit` | `ProfileSharingService.writeFollow()` on rate limit throw |
| `.searchRateLimitHit` | `DiscoverViewModel.onSearchTextChanged` on cap hit |
| `.appLaunch` | `VitaminGApp` scene `onAppear` |
| `.biometricUnlock` | `BiometricLockService.authenticate()` on success |
| `.biometricFailed` | `BiometricLockService.authenticate()` on failure |

### Error Handling

- If UserDefaults read fails (corrupted JSON): start fresh, do not crash
- If write fails: silently skip — audit logging must never break the happy path
- No throws — `log()` is fire-and-forget

### Privacy

- Stored only in UserDefaults (on-device, not synced to iCloud/CloudKit)
- `actorUserID` is Apple's opaque user ID — not a display name or email
- No PII beyond what's already in UserDefaults (block list, follow times)
- `PrivacyInfo.xcprivacy` update: add `NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1`
  (already present; no new entry needed)

---

## Feature 2 — Biometric App Lock

### Goal

Opt-in Face ID / Touch ID lock that re-prompts on each foreground. Defaults to OFF.
Provides personal privacy when sharing device.

### Service Interface

```swift
// Services/BiometricLockService.swift
@Observable
final class BiometricLockService {
    static let shared = BiometricLockService()

    var isEnabled: Bool  // UserDefaults key: "vg_biometric_lock_enabled"
    var isLocked: Bool   // in-memory; reset to true on sceneWillResignActive

    func authenticate() async throws  // LAContext.evaluatePolicy
    func lockIfEnabled()              // call on scene resign active
}
```

**Auth policy:** `.deviceOwnerAuthentication` (biometrics + passcode fallback). Reason string:
`"Unlock Vitamin G"`.

**Lock trigger:** `VitaminGApp` `.onChange(of: scenePhase)` — when phase becomes `.background` or
`.inactive` and `isEnabled == true`, call `lockIfEnabled()`.

**Unlock flow:** Full-screen `LockScreen` view presented via `.fullScreenCover(isPresented: ...)`.
Shows app icon, "Vitamin G" title, and "Unlock" button. On button tap, calls
`BiometricLockService.shared.authenticate()`. On success, `isLocked = false` (cover dismisses).
On failure (user cancelled or biometrics unavailable), shows error message and retry button.

### Settings Integration

Add one toggle row to the existing Settings screen:

```
Face ID / Touch ID
Require authentication when opening Vitamin G    [toggle]
```

Toggle writes directly to `BiometricLockService.shared.isEnabled`.

### Edge Cases

| Scenario | Behavior |
|----------|----------|
| Biometrics not enrolled | Falls back to device passcode (`.deviceOwnerAuthentication`) |
| User cancels Face ID | Error shown, retry available — app stays locked |
| First launch (before Apple Sign-In) | Biometric lock not shown — `isEnabled` defaults false |
| Widget interaction | Widgets bypass lock — they open a specific deep link, not the app root |

---

## Files to Create

| File | Purpose |
|------|---------|
| `Services/SecurityAuditLog.swift` | Audit log service |
| `Services/BiometricLockService.swift` | Biometric lock service |
| `Views/LockScreen.swift` | Full-screen lock overlay UI |

## Files to Modify

| File | Change |
|------|--------|
| `Services/BlockListService.swift` | Add audit log calls to block/unblock |
| `Services/ProfileSharingService.swift` | Add audit log calls to publishProfile, writeFollow |
| `ViewModels/DiscoverViewModel.swift` | Add audit log call on search rate limit hit |
| `VitaminGApp.swift` | Wire BiometricLockService + scene phase observer + .appLaunch log |
| `Views/Settings/SettingsView.swift` | Add biometric toggle |
| `.planning/SECSOP.md` | Add Sections 10 and 11 |

---

## Testing

- `SecurityAuditLogTests`: log 600 events → assert only 500 retained; assert JSON round-trip
- `BiometricLockServiceTests`: mock `LAContext`; assert `isLocked` state transitions
- Manual: enable biometric lock in Settings → background app → foreground → Face ID prompt appears
- Manual: disable toggle → background → foreground → no prompt

---

## Threat Model Updates

| Threat | Mitigation | Status |
|--------|-----------|--------|
| No incident reconstruction | SecurityAuditLog 500-event ring buffer | This spec |
| Device sharing / shoulder surfing | BiometricLockService opt-in gate | This spec |
