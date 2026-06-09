---
phase: 28-ai-claude-integration
plan: "01"
subsystem: ai-proxy
status: complete
tags:
  - cloudflare-worker
  - anthropic
  - tdd-red
  - ai-proxy
dependency_graph:
  requires:
    - "27 (Apple Watch App — Phase 27 complete)"
  provides:
    - "worker/src/index.js — deployed Cloudflare Worker at https://vg-ai-proxy.kileharrington.workers.dev/ai"
    - "Wave 0 RED test surface for Plan 02"
  affects:
    - "Plans 28-02, 28-03, 28-04 (all depend on deployed Worker URL)"
tech_stack:
  added:
    - "Cloudflare Workers (JavaScript, ES module export default)"
    - "wrangler CLI (npx wrangler — no global install needed)"
    - "Anthropic Messages API v1 (anthropic-version: 2023-06-01)"
  patterns:
    - "Shared-secret token gate (SHARED_TOKEN constant, body.token comparison)"
    - "Server-side prompt construction per D-10"
    - "Thin JSON envelope response per D-09"
    - "Markdown fence stripping before JSON.parse (Pitfall 5 / T-28-07)"
    - "CORS preflight OPTIONS → 204 (T-28-03)"
    - "XCTest RED stubs referencing future types for protocol seam testing"
key_files:
  created:
    - worker/src/index.js
    - worker/wrangler.toml
    - worker/test-worker.sh
    - worker/.gitignore
    - VitaminG/VitaminG/VitaminGTests/AIProxyServiceTests.swift
    - VitaminG/VitaminG/VitaminGTests/AIViewModelTests.swift
  modified: []
decisions:
  - "SHARED_TOKEN UUID 020A3129-9FDB-4817-8C8F-EA1A27F59A38 generated via uuidgen; same value in worker/src/index.js and recorded for Plan 02's AIProxyService.workerToken (Pitfall 2 prevention)"
  - "worker/ created at project root alongside VitaminG/ — not inside Xcode project"
  - "Suggestions cached as JSON Data (JSONEncoder) not [String] directly (Pitfall 1 mitigation, T-28-05)"
  - "test-worker.sh accepts SHARED_TOKEN as $2 — secret not committed to git"
  - "Both RED test files reference AIProxyService/AIViewModel types — VitaminGTests build fails until Plan 02 (expected Wave 0 state)"
  - "MockAIProxyService defined inline in AIProxyServiceTests.swift — protocol seam (AIProxyServiceProtocol) enables mock injection without network"
  - "macOS head -n-1 replaced with sed '$d' in test-worker.sh — GNU head not available on macOS"
metrics:
  duration: "~45 minutes (including human deployment checkpoint)"
  completed_tasks: 3
  total_tasks: 3
  completed_date: "2026-06-08"
---

# Phase 28 Plan 01: Cloudflare Worker Proxy and Wave 0 RED Test Scaffolds

**One-liner:** Cloudflare Worker proxy with token gate, server-side Claude prompt construction, markdown-stripped suggestions parsing, and CORS headers deployed at https://vg-ai-proxy.kileharrington.workers.dev/ai; Wave 0 RED XCTest stubs for AIProxyService and AIViewModel referencing future protocol types.

**Status:** COMPLETE — all 3 tasks done, Worker deployed, smoke tests 4/4 PASSED.

---

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create Cloudflare Worker source, config, and smoke-test script | `7288dab` | worker/src/index.js, worker/wrangler.toml, worker/test-worker.sh, worker/.gitignore |
| 2 | Create RED test scaffolds AIProxyServiceTests.swift and AIViewModelTests.swift | `6afb75b` | VitaminGTests/AIProxyServiceTests.swift, VitaminGTests/AIViewModelTests.swift |
| 3 | Human deployment checkpoint — Worker deployed and smoke-tested | `a62563e` | worker/src/index.js (SHARED_TOKEN), worker/test-worker.sh (macOS fix) |

---

## Deployment Details (Task 3 Outcome)

**Deployed Worker URL:** https://vg-ai-proxy.kileharrington.workers.dev/ai

**SHARED_TOKEN:** `020A3129-9FDB-4817-8C8F-EA1A27F59A38`
(Plan 02 must embed this as `AIProxyService.workerToken` static let)

**ANTHROPIC_API_KEY:** Set as Cloudflare Worker secret via `wrangler secret put` — never stored in any file in this repo. `grep -r "sk-ant-" worker/` returns 0 results (T-28-01 verified).

### Smoke Test Results (4/4 PASSED)

| Test | Description | Expected | Actual |
|------|-------------|----------|--------|
| motivation | POST valid token + type=motivation | HTTP 200 + `{"text":"..."}` | PASSED |
| suggestions | POST valid token + type=suggestions | HTTP 200 + `{"suggestions":[...]}` | PASSED (3 items) |
| suggestions count | `.suggestions \| length == 3` | 3 items | PASSED |
| bad token | POST wrong-token | HTTP 401 | PASSED |

---

## Task 1: Cloudflare Worker Details

### worker/src/index.js

Handler sequence (per acceptance criteria):
1. OPTIONS preflight → HTTP 204 + `Access-Control-Allow-Origin: *`, `Access-Control-Allow-Methods: POST, OPTIONS`, `Access-Control-Allow-Headers: Content-Type`, `Access-Control-Max-Age: 86400`
2. Non-POST → HTTP 405
3. JSON parse failure → HTTP 400
4. `body.token !== SHARED_TOKEN` → HTTP 401 (T-28-02)
5. `body.type` not in ["motivation", "suggestions"] → HTTP 400 (T-28-06)
6. Server-side prompt construction branched on type (D-10)
7. `POST https://api.anthropic.com/v1/messages` with `anthropic-version: 2023-06-01`, `X-Api-Key: env.ANTHROPIC_API_KEY`, model `claude-haiku-4-5-20251001`
8. Non-OK Anthropic response → HTTP 502 + CORS header
9. Extract `claude.content?.[0]?.text`, strip markdown fences for suggestions (`text.replace(/```json?/g, '').replace(/```/g, '').trim()`), fallback to 3 static suggestions if JSON.parse fails (T-28-07, D-07)
10. Wrap in thin envelope: `{ "text": "..." }` for motivation, `{ "suggestions": [...] }` for suggestions (D-09)
11. All responses include `Access-Control-Allow-Origin: *`

Security verification:
- `env.ANTHROPIC_API_KEY` is the ONLY reference to the Anthropic key — no string literal
- `grep -r "sk-ant-" worker/` returns 0 results (T-28-01)
- `SHARED_TOKEN` is the deployed UUID; not the Anthropic key (D-11)

### worker/wrangler.toml

```
name = "vg-ai-proxy"
main = "src/index.js"
compatibility_date = "2026-06-06"
```

### worker/test-worker.sh

Three curl smoke tests:
- Test 1: POST with valid token + `type=motivation` → expect HTTP 200 + parseable `.text`
- Test 2: POST with valid token + `type=suggestions` → expect HTTP 200 + `.suggestions | length == 3`
- Test 3: POST with `token: "wrong-token"` → expect HTTP 401

Usage: `./test-worker.sh "https://vg-ai-proxy.kileharrington.workers.dev/ai" "020A3129-9FDB-4817-8C8F-EA1A27F59A38"`

---

## Task 2: RED Test Scaffolds

### AIProxyServiceTests.swift (6 test methods)

| Method | Coverage |
|--------|----------|
| `test_fetchMotivation_cacheHit_returnsWithoutNetwork` | AI-02 cache hit: seeds `vg_motivation_<date>` key, asserts `.claude` result |
| `test_fetchMotivation_networkError_returnsFallback` | AI-02 fallback: MockAIProxyService returns `.fallback`, asserts `!isClaude` |
| `test_fetchSuggestions_cacheHit_returnsCachedArray` | AI-01 cache hit: JSON-encodes ["A","B","C"] to Data (Pitfall 1), asserts round-trip |
| `test_fetchSuggestions_networkError_returnsStaticFallback` | AI-01 fallback: asserts `== AIProxyService.staticSuggestions` |
| `test_motivationKey_matchesYYYYMMDDFormat` | Key format: `^vg_motivation_\\d{4}-\\d{2}-\\d{2}$` regex |
| `test_suggestionsKey_matchesYYYYMMDDFormat` | Key format: `^vg_suggestions_\\d{4}-\\d{2}-\\d{2}$` regex |

### AIViewModelTests.swift (6 test methods)

| Method | Coverage |
|--------|----------|
| `test_motivationLabel_claudeResult_returnsYourDose` | AI-02: `.claude("hi")` → `"YOUR DOSE"` |
| `test_motivationLabel_fallbackResult_returnsTodaysDose` | AI-02: `.fallback("hi")` → `"TODAY'S DOSE"` |
| `test_addedSuggestionIndices_initiallyEmpty` | AI-01: empty Set on init |
| `test_addedSuggestionIndices_insertReflected` | AI-01: insert(0) → contains(0) && !contains(1) |
| `test_initialSuggestions_areStaticFallback` | AI-01: suggestions == AIProxyService.staticSuggestions |
| `test_initialMotivation_isFallback` | AI-02: motivationResult.isClaude == false |

**Wave 0 RED state:** Both test files reference `AIProxyService`, `AIViewModel`, `MotivationResult`, `GoalPayload`, `AIProxyServiceProtocol` — none of which exist until Plan 02. The VitaminGTests target will fail to compile until Plan 02 introduces these types. This is the expected and correct Wave 0 state.

**Note for Plan 02:** Both test files are on disk but not yet added to the Xcode test target `.pbxproj`. Plan 02's first task must add both files to the VitaminGTests target in Xcode before running tests.

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] macOS head -n-1 compatibility fix in test-worker.sh**
- **Found during:** Task 3 (human smoke test)
- **Issue:** `head -n-1` is a GNU coreutils extension not available on macOS BSD head. The script failed to parse the HTTP status code from curl output on macOS.
- **Fix:** Replaced all three `head -n-1` invocations with `sed '$d'` which achieves the same "remove last line" behavior on both macOS and Linux.
- **Files modified:** worker/test-worker.sh
- **Commit:** `a62563e`

---

## Known Stubs

None — no UI wiring or placeholder values. The deployed Worker is production-ready. VitaminGTests RED state is intentional (Wave 0 design).

---

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| T-28-01 mitigated | worker/src/index.js | Anthropic API key referenced ONLY as `env.ANTHROPIC_API_KEY`; no literal key; `grep -r "sk-ant-" worker/` returns 0 |
| T-28-02 mitigated | worker/src/index.js | `body.token !== SHARED_TOKEN` check is the FIRST action after JSON parse |
| T-28-03 mitigated | worker/src/index.js | OPTIONS preflight returns 204 with correct CORS headers |
| T-28-05 mitigated | AIProxyServiceTests.swift | `test_fetchSuggestions_cacheHit_returnsCachedArray` uses JSONEncoder → Data; confirms Plan 02 must follow same pattern |
| T-28-06 mitigated | worker/src/index.js | `body.type` validated before prompt construction; `body.goals` defaults to `[]`, `body.streak` defaults to `0` |
| T-28-07 mitigated | worker/src/index.js | Markdown fence stripping before `JSON.parse`; static fallback on parse failure or array length < 3 |

---

## Self-Check: PASSED

- `worker/src/index.js` — FOUND (SHARED_TOKEN set to deployed UUID)
- `worker/wrangler.toml` — FOUND
- `worker/test-worker.sh` — FOUND (executable, macOS-compatible)
- `worker/.gitignore` — FOUND
- `VitaminG/VitaminG/VitaminGTests/AIProxyServiceTests.swift` — FOUND (6 test methods)
- `VitaminG/VitaminG/VitaminGTests/AIViewModelTests.swift` — FOUND (6 test methods)
- Commit `7288dab` (Task 1) — FOUND in git log
- Commit `6afb75b` (Task 2) — FOUND in git log
- Commit `a62563e` (Task 3 fix) — FOUND in git log
- Worker URL verified live: https://vg-ai-proxy.kileharrington.workers.dev/ai
- Smoke test 4/4 PASSED
- `grep -r "sk-ant-" worker/` — 0 results (T-28-01 verified)
