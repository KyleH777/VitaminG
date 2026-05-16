# Phase 1: Foundation - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 delivers the complete data layer and architecture scaffold before any user-facing feature exists:
- Xcode project with main app target + widget stub target
- SwiftData `Goal` and `CompletionEvent` models with `VersionedSchema`
- App Group entitlement on both targets (`group.com.kyleharrington.VitaminG`)
- CloudKit-ready `ModelContainer` (`groupContainer` + `cloudKitDatabase: .automatic`)
- `@Observable` MVVM ViewModels + `AppRoute` NavigationStack routing layer
- Input validation enforced at model/ViewModel layer (not in Views)

Phase 1 does NOT include any user-facing views, goal CRUD UI, notifications, widgets, or onboarding. Those are Phase 2+.

</domain>

<decisions>
## Implementation Decisions

### App Identity
- **D-01:** Bundle ID: `com.kyleharrington.VitaminG`
- **D-02:** App Display Name: "Vitamin G"
- **D-03:** App Group identifier: `group.com.kyleharrington.VitaminG`

### Xcode Project Structure
- **D-04:** `.xcodeproj` lives at `Desktop/AI/Vitamin G/VitaminG.xcodeproj`
- **D-05:** Source files organized under `VitaminG/` (main target) and `VitaminGWidget/` (widget stub target)
- **D-06:** Widget target is scaffolded in Phase 1 with App Group entitlement but zero widget code — this prevents the store path change that would occur if App Group were retrofitted in Phase 4

### MVVM Architecture
- **D-07:** All ViewModels use `@Observable` macro (iOS 17+) — no `ObservableObject` / `@Published`
- **D-08:** Phase 1 includes a `NavigationStack` routing layer: an `AppRoute` enum + `AppRouter` observable class, so Phase 2 views have a navigation contract to build against
- **D-09:** Zero business logic in Views — enforced from the first line of code

### SwiftData Models
- **D-10:** All `Goal` and `CompletionEvent` properties are optional or have defaults (CloudKit requirement)
- **D-11:** `VersionedSchema` declared from day one as `SchemaV1` — no unversioned schema ships
- **D-12:** No `@Attribute(.unique)` on any property — CloudKit does not support atomic uniqueness
- **D-13:** `ModelContainer` uses `groupContainer: .identifier("group.com.kyleharrington.VitaminG")` + `cloudKitDatabase: .automatic`

### Input Validation
- **D-14:** Validation enforced in `GoalViewModel` before any SwiftData insert:
  - `title`: max 100 characters, non-empty
  - `description`: max 500 characters
  - `associatedInspiration`: max 300 characters
- **D-15:** Sanitization strips control characters and normalises whitespace before validation

### Claude's Discretion
- File naming and folder structure within targets (follow Xcode defaults)
- `#if DEBUG` CloudKit schema initialization call verbosity
- Error type design for validation failures
- `AppRoute` enum cases (can be empty stubs in Phase 1 — Phase 2 fills them in)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Requirements
- `.planning/REQUIREMENTS.md` — Full v1 requirements; Phase 1 must satisfy FOUND-01 through FOUND-07
- `.planning/ROADMAP.md` — Phase 1 goal, success criteria, and dependency order

### Project State & Decisions
- `.planning/STATE.md` — Known risks: App Group + CloudKit coexistence is MEDIUM confidence; validate on physical device in Phase 1

### Stack Guidance (in CLAUDE.md)
- `CLAUDE.md` §Technology Stack — Full framework table with confidence ratings and version requirements
- `CLAUDE.md` §What NOT to Use — Explicit list of frameworks to avoid (ObservableObject, NavigationView, etc.)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project. No existing Swift source files.

### Established Patterns
- None yet — Phase 1 establishes all patterns that subsequent phases inherit.

### Integration Points
- `VitaminGApp.swift` (entry point) — will inject `ModelContainer` and `AppRouter` into the environment
- App Group store path — shared between `VitaminG` and `VitaminGWidget` targets via `ModelConfiguration(groupContainer:)`

</code_context>

<specifics>
## Specific Ideas

- App Group ID is `group.com.kyleharrington.VitaminG` — must match exactly in both target entitlement files and in `ModelConfiguration` initializer
- Widget target in Phase 1 is a shell only: target created, entitlement set, no widget code. Phase 4 fills it in.
- STATE.md flags that `cloudKitDatabase: .automatic` + `groupContainer: .identifier(...)` coexistence is MEDIUM confidence — the plan should include a physical-device smoke test step

</specifics>

<deferred>
## Deferred Ideas

- Widget UI and `AppIntentConfiguration` — Phase 4
- Navigation routes for all screens — Phase 1 creates the `AppRoute` enum stub; Phase 2 adds cases as views are built
- Onboarding flow — Phase 5
- CloudKit schema promotion to Production — Phase 6

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-04-03*
