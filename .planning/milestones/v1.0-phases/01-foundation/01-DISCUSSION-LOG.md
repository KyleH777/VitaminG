# Phase 1: Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents. See 01-CONTEXT.md for decisions.

**Date:** 2026-04-03

---

## Gray Areas Discussed

### App Group & Bundle ID
- **Q:** What bundle ID should the app use?
- **A:** "VitaminG" → interpreted as `com.kyleharrington.VitaminG`
- **Decision:** Bundle ID `com.kyleharrington.VitaminG`, App Group `group.com.kyleharrington.VitaminG`

### Widget Target Scope
- **Q:** Should we scaffold a widget target shell in Phase 1 so the App Group covers both targets from day one?
- **A:** Yes — stub it in Phase 1 (Recommended)
- **Decision:** Widget target created in Phase 1 with App Group entitlement, zero widget code

### MVVM Scaffold Depth
- **Q:** How deep should the MVVM scaffold go in Phase 1?
- **A:** ViewModels + NavigationStack routing layer
- **Decision:** `@Observable` ViewModels + `AppRoute` enum + `AppRouter` class

### Xcode Project Structure
- **Q:** Where should the Xcode project live?
- **A:** Inside the Vitamin G repo folder (Recommended)
- **Decision:** `Desktop/AI/Vitamin G/VitaminG.xcodeproj`

---

## User Notes

During discussion, user asked: "Should I just paste all my prompts in and you can try to implement the phases into how they would fit your work?" — noted as a workflow option for subsequent phases. User can paste pre-written phase prompts as PRDs to drive planning without a full discuss-phase session.
