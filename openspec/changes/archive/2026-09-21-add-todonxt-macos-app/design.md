## Context

Greenfield native macOS app. See proposal.md for motivation and full capability list. Target: macOS 13 Ventura+, SwiftUI, `MenuBarExtra` API. No backend, no monetization, no third-party network services — everything must work fully offline.

## Goals / Non-Goals

**Goals:**
- Mirror TodoNxt's exact UX: menu-bar-only presence, Now/Nxt/Ltr lanes, up to 4 tabs, drag-and-drop, completed-task countdown/auto-purge, global hotkey, light/dark mode.
- Keep the codebase small and idiomatic SwiftUI/AppKit-interop, since the feature surface is intentionally minimal.
- Ship a distinct custom app icon (separate design task, not part of this change's code).

**Non-Goals:**
- No Stripe/payment flow, no license/activation gating (app is free).
- No Sparkle or any auto-update mechanism (no update server to maintain).
- No CloudKit/iCloud sync, no companion iOS app.
- No telemetry/analytics/crash reporting SDKs.
- Not pursuing Mac App Store distribution in this change (affects entitlements/sandboxing choices only if revisited later).

## Decisions

### 1. Menu bar shell: `MenuBarExtra` (SwiftUI) over `NSStatusItem` (AppKit)
`MenuBarExtra` (macOS 13+) is the native SwiftUI-first way to build a menu-bar-only app with a popover-style `.window` style, and it removes the Dock icon automatically when combined with `LSUIElement = true` in Info.plist. This avoids hand-rolling `NSStatusItem` + `NSPopover` plumbing.
- Alternative considered: raw `NSStatusItem` + `NSPopover` (AppKit) — more control over popover behavior (e.g. exact click-outside dismissal nuances) but more boilerplate. We'll drop to AppKit only where `MenuBarExtra` can't do something (see Decision 2).

### 2. Global hotkey: Carbon `RegisterEventHotKey` (via a thin wrapper) instead of SwiftUI-only APIs
SwiftUI's `MenuBarExtra` has no built-in API for a system-wide keyboard shortcut that works while another app is focused. The standard native approach is the Carbon Event Manager's `RegisterEventHotKey`/`InstallEventHandler`, which still works on modern macOS for this purpose and doesn't require Accessibility permissions (unlike a global `NSEvent` monitor for keyDown, which needs Accessibility access). We'll wrap this in a small `GlobalHotKey` helper type.
- Alternative considered: `NSEvent.addGlobalMonitorForEvents` — simpler API but requires the user to grant Accessibility permission, which is a heavier/more suspicious ask for a "100% private" app. Carbon hotkey registration avoids that permission prompt entirely.

### 3. Persistence: single local JSON file via `FileManager` + `Codable`, not SwiftData/CoreData
Given the small, simple data model (a handful of tabs, each with ≤ a few dozen tasks), a single `Codable` struct tree serialized to JSON in `~/Library/Application Support/<AppName>/store.json` is simpler to reason about, easy to inspect/debug, and trivially avoids any accidental CloudKit entitlement that SwiftData's convenience initializers can pull in. Writes are debounced/atomic (write-to-temp-then-rename) to avoid corruption.
- Alternative considered: SwiftData — nicer relationship modeling and query API, but adds framework complexity and an ORM-style migration story for a dataset this small; explicitly avoided to keep "100% local, no accidental cloud" easy to audit.

### 4. Completed-task auto-purge: computed at read-time + periodic sweep
Rather than scheduling per-task timers, store `completedAt` and a `retentionDays` setting; compute "purged or not" and the countdown label whenever the UI reads tasks, and run a lightweight periodic sweep (e.g. every 60s while the popover is open, plus once on launch) to actually remove expired tasks from the store. This avoids managing a `Timer` per task and keeps logic centralized and testable as pure functions of `(completedAt, retentionDays, now)`.

### 5. Settings storage: part of the same local JSON store
Hotkey binding, launch-at-login flag, retention-days value, and tab list/order all live in the same local store document as tasks, under a `settings` key — one file, one source of truth, simplifying backup/restore and avoiding `UserDefaults`/file split inconsistency.

### 6. Launch at login: `SMAppService.mainApp` (ServiceManagement framework, macOS 13+)
This is the modern replacement for the deprecated `SMLoginItemSetEnabled`, requires no separate helper-app target, and matches our macOS 13+ minimum deployment target exactly.

### 7. Drag-and-drop: SwiftUI native `.draggable`/`.dropDestination` (or `onDrag`/`onDrop` fallback)
Tasks are simple value structs; SwiftUI's transferable/drag-drop modifiers are sufficient for both within-lane reordering and cross-lane/cross-tab moves without needing `NSItemProvider` boilerplate.

## Risks / Trade-offs

- **[Risk] Carbon Event Manager APIs are old and only lightly documented for Swift.** → Mitigation: wrap in a small, well-tested `GlobalHotKey` type; cover with unit tests around registration/unregistration; fall back to a settings-visible "shortcut inactive" state if registration fails rather than crashing.
- **[Risk] JSON-file persistence has no built-in migration framework if the schema changes later.** → Mitigation: include a `schemaVersion` field in the root document from day one; write a simple versioned-migration function even though v1 has nothing to migrate from.
- **[Risk] Periodic sweep for auto-purge could race with user un-completing a task at the same moment.** → Mitigation: sweep and user actions both go through the same serialized store-mutation queue (e.g. an actor), so there's no torn read/write.
- **[Trade-off] No Accessibility-permission-based global monitor means slightly less flexible hotkey capture UI**, but this is the right trade for a "100% private, no scary permission prompts" app.

## Migration Plan

Not applicable — this is a new, greenfield application with no prior version or user data to migrate.
