# Security Policy

TaskNxt is a menu bar task list. All tabs, tasks, settings, and the archive
are stored only in local, on-device storage — there is no account, no cloud
sync, no network calls, and no telemetry. Please keep that in mind when
assessing impact: the primary security concerns are local data handling
(e.g. how tasks are persisted on disk) rather than network-facing attack
surface.

## Supported versions

Only the latest release receives security fixes. Update via
`brew upgrade thamaraiselvam/tasknxt/tasknxt` or the latest
[GitHub Release](https://github.com/thamaraiselvam/tasknxt/releases).

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Use [GitHub private vulnerability reporting](https://github.com/thamaraiselvam/tasknxt/security/advisories/new) —
it goes straight to the maintainer and stays private until a fix ships.

You can expect an initial response within a few days. If the report is
valid, a fix will be released as soon as practical and you'll be credited
in the release notes (unless you prefer otherwise).

## Scope

Reports especially welcome for:

- Any way local task/tab/settings data could be read, modified, or exposed
  outside the app without user action.
- Any unexpected network activity — TaskNxt is designed to make zero
  network calls.
- Sandbox or entitlement issues that grant the app more access than it
  needs.
- Anything that lets untrusted input (e.g. a crafted task title) cause
  unintended code execution or crashes.
