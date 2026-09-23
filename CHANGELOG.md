# Changelog

## [1.0.4](https://github.com/thamaraiselvam/TaskNxt/compare/v1.0.2...v1.0.4) (2026-09-23)

Re-release of the 1.0.3 changes (the v1.0.3 tag could not be published).


### Bug Fixes

* keep popover anchored when the menu bar badge count changes ([d376c30](https://github.com/thamaraiselvam/TaskNxt/commit/d376c307b024d821c5f0ee696d4ddf6abdc2aceb))
* make task text editable with a single click ([31b0bc3](https://github.com/thamaraiselvam/TaskNxt/commit/31b0bc3ccb0b3e5671c686b4614940c14838b953))
* make the whole settings and tab chips clickable ([ef50c31](https://github.com/thamaraiselvam/TaskNxt/commit/ef50c313e6f17138223c11a431714750b3185f05))
* show the real app version and icon in About ([a0544e5](https://github.com/thamaraiselvam/TaskNxt/commit/a0544e5deb3101bbd5b1953e7a0fd79a0dcf55e3))

## [1.0.1](https://github.com/thamaraiselvam/tasknxt/compare/v1.0.0...v1.0.1) (2026-09-21)


### Bug Fixes

* interpolate UUIDs in LocalStoreTests JSON fixture ([7b9c41c](https://github.com/thamaraiselvam/tasknxt/commit/7b9c41ca5abd5ef1d877bd030ec81012de168402))
* make AppTab.tasks JSON encoding toolchain-stable ([1e9b951](https://github.com/thamaraiselvam/tasknxt/commit/1e9b951cb09a9172d7c98f10ffea726f4c50d8f7))
* resolve Swift 6 concurrency build error in AppState sweep timer ([b8ddf66](https://github.com/thamaraiselvam/tasknxt/commit/b8ddf6630a7956eda5ad16e18007a71e1b75a812))

## 1.0.0 (2026-09-21)

First public release of TaskNxt — a free, local-first macOS menu bar task manager.

### Highlights

* **Three lanes** — Now, Nxt, and Ltr — for organizing what matters today, what's coming next, and what can wait
* **Tabs** — up to 4 named tabs (e.g. Work, Personal), each with its own lanes and a live menu bar badge count
* **Retention & archive** — completed tasks auto-purge after a configurable retention period, with an optional browsable archive
* **Global shortcut** — configurable hotkey to summon the popover from anywhere
* **100% local & private** — no accounts, no cloud sync, no telemetry — everything lives in local on-device storage
