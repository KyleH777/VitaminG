# Features Research

**Project:** Vitamin G
**Domain:** iOS goal-tracking + gratitude / intentionality app
**Researched:** 2026-04-03
**Confidence:** MEDIUM-HIGH (competitive landscape well-documented; some UX claims from WebSearch corroborated by App Store patterns)

---

## Table Stakes

Features users expect from any goal or habit tracking app. Absent these, users leave within the first week.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Goal creation with title + description | Core function; no goal tracking without it | Low | Already in PROJECT.md model: id, title, description, tier, isCompleted, creationDate, associatedInspiration |
| Tiered / categorized goals | Users need to separate urgent tasks from life vision; single flat list fails mental models | Low-Med | Vitamin G's 4-tier hierarchy (Immediate → Short-Term → Long-Term → Life Goal) is the core differentiator — but having *some* categorization is table stakes |
| Goal completion (check-off) | Basic task completion feedback; without it the app feels pointless | Low | SwiftData `isCompleted` field covers this |
| Streak tracking | Industry standard; every major competitor (Streaks, Strides, Productive, Habitica) has it; users expect the motivational "chain" | Med | Requires computing streaks from completion history; needs a completion-history log beyond a single `isCompleted` bool |
| Progress statistics / completion rate | Charts, success rate, days active — users check these to feel momentum | Med | At minimum: per-tier completion count, overall completion rate, current streak length |
| Push notifications — daily morning reminder | This is Vitamin G's core value proposition ("daily dose of intentionality"); without it the app is just a list | Med | Requires UNUserNotificationCenter permission flow + scheduling; must show active goal summary in notification body |
| iCloud sync across devices | Cross-device sync is a baseline expectation in 2026; apps without it feel unfinished | Med | SwiftData + CloudKit; zero-code path exists but CloudKit imposes model constraints (no @Attribute(.unique), all properties optional or defaulted) |
| Home screen widget | Users want their goal summary visible without opening the app; widget placement drives daily re-engagement | Med | WidgetKit, TimelineProvider; target at minimum the medium home screen widget (systemMedium) showing top active goals |
| Lock screen widget | Quick glance at today's primary goal / streak; introduced iOS 16, now expected by power users | Med | accessoryRectangular or accessoryCircular families; constrained rendering, must be text/gauge-focused |
| Edit and delete goals | Without CRUD, the app is a dead end after first use | Low | Standard SwiftData operations |
| Onboarding / empty states | 25% of users abandon after one use; no onboarding = no understanding of value | Low-Med | At minimum: explain the 4 tiers on first launch; guide user to create first goal before leaving |
| Input validation on all text fields | Required for App Store security bar; also prevents data corruption in SwiftData | Low-Med | Already in PROJECT.md as requirement; character limits + sanitization at model layer |

---

## Differentiators

Features that set Vitamin G apart from generic habit trackers and gratitude journals. Not expected by default, but meaningfully valued when present.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| 4-tier goal hierarchy (Immediate / Short-Term / Long-Term / Life Goal) | No mainstream iOS app maps goals to realistic planning horizons this way; most competitors use flat lists or arbitrary folders. This framing is psychologically grounded: it mirrors how humans actually think about time | Med | The tiers must feel *meaningfully different* in UX — different colors, icons, or visual weight per tier. A flat list with four labels defeats the purpose |
| `associatedInspiration` per goal | Linking a quote, image, or personal statement to a goal creates emotional resonance; competitors (Motiq, Rize) do quotes as a separate feature; Vitamin G embeds it into the goal model itself | Med | For v1: free-text inspiration field (a personal quote or "why" statement). Image/media attachment can be v2 |
| Morning notification with goal summary content | Most apps send a generic "Time to check your goals!" push; Vitamin G can send the user's actual top goals in the notification body, making it actionable and personal. This is the "daily dose" moment | Med | Notification content must pull from SwiftData; be careful about notification payload size limits (~4KB) |
| Tier-aware streak tracking | Tracking streaks per tier (not just globally) lets users see "I've been consistent on Life Goals for 30 days" — a deeper signal than a single app-wide streak | Med | Requires per-tier streak computation; store completion events with tier metadata |
| Intentionality framing ("Vitamin G") | Gratitude + goal tracking as a *wellbeing* practice, not a productivity grind. The branding and copy should feel warm and reflective, not aggressive like OKR tools | Low (copy/design) | This is a tone and visual design decision, not a feature to build — but it differentiates the App Store listing and onboarding significantly |
| Clean native iOS aesthetic (no subscription upsell walls) | Most competitors (Reflectly, Strides, Productive) gate core features behind $29-$59/year subscriptions and interrupt the flow with paywalls. A free, clean, uninterrupted experience is itself a differentiator for a portfolio-quality app | Low (pricing decision) | Keep it free or one-time purchase for v1; no freemium tier complexity to build |
| Goal "Why" field (associatedInspiration as reflection anchor) | Research shows goals with a documented "why" have dramatically higher completion rates; this is the gratitude angle — not just tracking what, but remembering *why* | Low | Surfaces in the morning notification and on the goal detail view; the model already supports it |

---

## Anti-Features (Don't Build in V1)

Explicitly deferred. These features appear in competitors, attract scope creep, and would delay ship without proportional user value at launch.

| Anti-Feature | Why Avoid | What to Do Instead | Effort Saved |
|--------------|-----------|-------------------|--------------|
| Social sharing / friend accountability | PROJECT.md correctly defers this; it requires a backend, user auth, privacy policy, and moderation surface area. Competitors like Orca (formerly HappyFeed) built this and it became their identity — Vitamin G is personal and private | Note on App Store listing: "private by design" | High |
| AI-generated insights / personalization | Reflectly uses AI journaling prompts; tempting to add, but requires an API dependency (OpenAI / Anthropic), adds latency, adds cost, adds a third-party dependency that PROJECT.md explicitly restricts | Static prompts or no prompts in v1 | High |
| Vision board / image collage | Several apps (Gratitude app, Vision Board 2025) offer photo-based vision boards; complex media pipeline, large storage, CloudKit size limits become a real constraint | The `associatedInspiration` text field is the lean version of this idea | Med |
| Goal templates library | Strides ships 150+ habit templates; useful but a content creation project, not an engineering one | Users create their own goals on first launch; templates are a v2 content effort | Med |
| Apple Watch app | Deep Apple ecosystem integration; Streaks and Productive both offer it; engineering complexity high for a glance feature | Lock screen widget covers the glanceable use case at lower cost | High |
| Recurring / scheduled goals | Habit-style daily repetition (e.g., "meditate every day") is a different product primitive than the 4-tier goal model; mixing them creates UX confusion | Keep Vitamin G as *aspirational* goal tracking, not daily habit logging; that's Streaks' lane | Med |
| In-app reminders / calendar integration | Connecting to EventKit or CalDAV is a separate capability; morning push notification covers the reminder use case | Single daily morning push is intentional simplicity | Med |
| Analytics dashboard / export | Charts beyond basic streak/completion stats; CSV export; sharing progress reports | Simple per-tier stats are table stakes; a full analytics view is v2 | Med |
| Markdown / rich text in descriptions | Some journal apps support rich text; overkill for goal descriptions; increases validation complexity and rendering surface area | Plain text with character limits; simpler and safer | Low-Med |
| Gamification (points, badges, levels) | Habitica built an entire RPG around this; meaningful but a product pivot; Vitamin G's tone is reflective, not gamified | Streaks and completion counts are the reward signal | Med |
| Collaboration / shared goals | Out of scope per PROJECT.md; single-user app | — | High |
| Web dashboard | Out of scope per PROJECT.md | — | High |

---

## Feature Dependencies

These dependency relationships must drive phase ordering in the roadmap. Build in dependency order — do not build a feature before its prerequisite is stable.

```
SwiftData model (Goal entity: id, title, description, tier, isCompleted, creationDate, associatedInspiration)
  └── Goal CRUD (create, read, update, delete)
        ├── Goal list UI (sorted by tier)
        │     └── Goal detail view
        │           └── associatedInspiration display
        ├── Completion tracking (toggle isCompleted)
        │     └── Completion history log (for streak computation)
        │           ├── Streak tracking per tier
        │           │     └── Statistics view (per-tier completion rate, streak display)
        │           └── iCloud sync (CloudKit)
        │                 └── [Cross-device testing]
        └── Push notification scheduling
              └── Morning notification content (pulls active goals from SwiftData)

WidgetKit extension
  ├── Depends on: SwiftData model (shared App Group container)
  ├── Home screen widget (systemSmall, systemMedium)
  └── Lock screen widget (accessoryRectangular)
        └── Depends on: iOS 16+ widget families (already satisfied by iOS 17+ minimum)

Onboarding
  └── Depends on: Goal CRUD being stable (user must complete onboarding by creating a goal)
        └── Notification permission request (must happen in onboarding, not mid-session)
```

**Critical path:** SwiftData model → CRUD → Completion history → Streak tracking → iCloud sync

**Widget critical path:** SwiftData model (App Group shared container) → WidgetKit extension → Widget UI

**Notification dependency:** Completion data must exist before notification content is meaningful; build notifications after CRUD is stable but before streaks (so the notification can at least list active goal titles)

**iCloud constraint note:** CloudKit requires all SwiftData model properties to be optional or have defaults, and prohibits `@Attribute(.unique)`. Design the model with this in mind from the start — retrofitting CloudKit compatibility onto a model built without it is a medium-complexity rewrite.

---

## MVP Recommendation

**Prioritize for v1 launch:**

1. SwiftData model + Goal CRUD (non-negotiable foundation)
2. 4-tier goal list UI with per-tier visual distinction
3. Completion toggle + completion history log (prerequisite for streaks)
4. Streak tracking per tier + basic stats view
5. Morning push notification with active goal summary content
6. iCloud sync (CloudKit via SwiftData)
7. Home screen widget (systemMedium showing top active goals)
8. Lock screen widget (accessoryRectangular showing streak or top goal)
9. Onboarding (tier explanation + first goal creation + notification permission)

**Defer to v2:**
- Apple Watch app
- Image/photo `associatedInspiration` (v1: text only)
- Full analytics dashboard
- AI-powered features
- Social features
- Vision board
- Recurring/habit goals

---

## Sources

- [Reclaim: 14 Best Goal Tracker Apps for 2026](https://reclaim.ai/blog/goal-tracker-apps)
- [Mindful Suite: Best Goal Tracker Apps](https://www.mindfulsuite.com/reviews/best-goal-tracker-apps)
- [Strides App Review 2026 — CRM.org](https://crm.org/news/strides-app-review)
- [Strides vs Productive Comparison — DailyHabits](https://www.dailyhabits.xyz/habit-tracker-app/strides-vs-productive)
- [AppleInsider: Strides 15.2.1 Review](https://appleinsider.com/articles/23/02/02/strides-1521-review-visual-habit-tracking-at-its-best)
- [Mindful Browsing: 13 Best Gratitude Apps](https://www.mindfulbrowsing.com/best-gratitude-apps/)
- [Positive Psychology: 11 Best Gratitude Apps](https://positivepsychology.com/gratitude-apps/)
- [Gratitude vs Reflectly comparison — Reflection.app](https://www.reflection.app/best-journaling-apps-compared/gratitude-vs-reflectly)
- [Orca (formerly HappyFeed) — February 2026 rebrand](https://www.happyfeed.co)
- [Reclaim: 10 Best Habit Tracker Apps for 2026](https://reclaim.ai/blog/habit-tracker-apps)
- [Widgetly: 12 Best Habit Tracking Apps 2025](https://www.widgetly.co/blog/best-habit-tracking-apps)
- [WWDC 2025 WidgetKit Guide — DEV Community](https://dev.to/arshtechpro/wwdc-2025-widgetkit-in-ios-26-a-complete-guide-to-modern-widget-development-1cjp)
- [WidgetKit iOS Widget Interactivity 2026 — DEV Community](https://dev.to/devin-rosario/ios-widget-interactivity-in-2026-designing-for-the-post-app-era-i17)
- [Apple Developer: WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [Hacking with Swift: Sync SwiftData with iCloud](https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud)
- [AzamSharp: SwiftData iCloud Sync Status (March 2026)](https://azamsharp.com/2026/03/16/swiftdata-icloud-sync-status.html)
- [Apple Developer: Syncing model data across devices](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices)
- [UXCam: Mobile App Churn Rate Benchmarks 2025](https://uxcam.com/blog/mobile-app-churn-rate/)
- [RevenueCat: State of Subscription Apps 2025](https://www.revenuecat.com/state-of-subscription-apps-2025/)
- [Motiq: Quote + Goal tracking pattern](https://motiq.org/)
- [Topflight Apps: How to Avoid Scope Creep in MVP](https://topflightapps.com/ideas/avoid-scope-creep/)
