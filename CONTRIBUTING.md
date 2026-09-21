# Contributing to TaskNxt

Thanks for your interest in contributing to TaskNxt. This guide will help you
get started.

## Quick start

Requirements: macOS 13+, Xcode 15+ (or the Swift 5.9+ toolchain).

```bash
git clone git@github.com:thamaraiselvam/tasknxt.git
cd tasknxt/app
./Scripts/build_app.sh
open .build/TaskNxt.app
```

This packages a real `TaskNxt.app` bundle (with the app icon, Dock behavior,
etc. all working correctly) rather than running the bare executable. For the
fastest edit/debug loop, open `app/Package.swift` in Xcode and run the
`TaskNxt` scheme directly, or run `swift build` — both work for quick
iteration, but macOS has no bundle to read a custom icon from in that case,
so the app shows a generic icon.

## Running tests

```bash
cd app
swift test
```

All tests cover `TaskNxtCore` (models, persistence, and app state) and must
pass before submitting a PR.

## Pull request expectations

- Keep PRs focused: one logical change per PR.
- Include tests for any new logic in `TaskNxtCore`.
- Follow the existing code style and conventions.
- Make sure all tests pass locally before opening a PR.
- Use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`,
  `fix:`, `docs:`, `ci:`, etc.) for commit and PR titles — releases are
  automated with release-please based on this convention.
- Write a clear description of what your change does and why.

## Architecture overview

The project structure is documented in the [README](README.md#architecture).
A few key decisions worth knowing before diving in:

- **`TaskNxtCore` has no SwiftUI dependency** — it builds and tests cleanly
  with any Swift toolchain, so keep model/persistence logic there rather than
  mixing it into views.
- **Three fixed lanes per tab** — Now / Nxt / Ltr — this ordering is a core
  product decision, not just a default.
- **100% local persistence** — no network calls, no accounts, no telemetry.
  New features should preserve this invariant.
- **Spec-driven changes** — behavioral specs live under `openspec/specs/`,
  and in-flight proposals live under `openspec/changes/`. Check there for the
  current spec of the capability you're touching.

## What makes a good contribution

Good candidates for contribution:

- Bug fixes with a clear reproduction case.
- Additional test coverage in `TaskNxtCore`.
- Accessibility improvements.
- Performance or reliability improvements.

The design of TaskNxt is intentionally minimal and restrained (three lanes,
menu bar only, no accounts). If you are considering UI changes or new
features, please open an issue first to discuss the approach before writing
code.

## Reporting issues

If you find a bug, please open a GitHub issue with:

- macOS version and hardware (Intel or Apple Silicon).
- Steps to reproduce.
- Expected vs. actual behavior.
