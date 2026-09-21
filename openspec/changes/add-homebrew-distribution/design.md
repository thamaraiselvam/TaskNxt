## Context

TaskNxt is a macOS-only menu-bar app, built and released as a universal `.dmg` by the existing `build-and-release.yml` workflow (see proposal.md - Why). There is no Homebrew presence today. Because TaskNxt is a GUI `.app` shipped as a `.dmg` (not a CLI binary/script), the correct Homebrew artifact is a **Cask** (`brew install --cask`), not a Formula — Casks are the mechanism Homebrew uses for GUI application bundles and know how to mount a `.dmg`, copy the `.app` to `/Applications`, and handle `zap`/uninstall.

## Goals / Non-Goals

**Goals:**
- A working Cask (`Casks/tasknxt.rb`) in a new tap repo, `thamaraiselvam/homebrew-tasknxt`, installable via `brew install thamaraiselvam/tasknxt/tasknxt`.
- Zero manual steps after a maintainer pushes a `v*.*.*` tag: the existing release job builds the `.dmg`, publishes the GitHub Release, and a follow-up step updates the Cask's `version`/`sha256`/`url` in the tap and pushes it — so `brew update && brew upgrade` on a user's machine sees the new version immediately.

**Non-Goals:**
- Submitting to `homebrew-core`/`homebrew-cask` (the official, curated Homebrew repos) — those have stricter eligibility and review requirements; a personal tap is the right scope for now and can migrate later if desired.
- Code-signing/notarization changes — the Cask will continue to reference the existing ad-hoc-signed `.dmg`; users will still need Gatekeeper right-click-open (or `xattr -d com.apple.quarantine`) the first time, same as today's manual `.dmg` download. Out of scope for this change.
- Auto-generating release notes or changelog content for the tap — it only needs `version`/`sha256`/`url` to stay current.

## Decisions

- **Personal tap over `homebrew-core`**: `homebrew-core`/`homebrew-cask` require the project to meet notability/maintenance bars and go through PR review per submission; a self-owned tap (`homebrew-tasknxt`) gives full control and lets automation push updates with no external review, which is required for the "no manual step per release" goal.
- **Cask, not Formula**: TaskNxt is a GUI `.app` distributed as a `.dmg`; Homebrew's own guidance is Casks for this shape of artifact (`app "TaskNxt.app"` stanza + Applications symlink), vs. Formulas which are for command-line software built from source or binaries.
- **Automation via `brew bump-cask-pr --write-only`, not a hand-rolled sha256/sed script**: Homebrew ships a built-in command that already knows how to fetch the new `.dmg`, compute its `sha256`, and rewrite the Cask's `version`/`sha256`/`url` fields correctly (including any `livecheck`-style interpolation) — reusing it avoids reimplementing and keeps the generated file `brew audit`-clean. `--write-only` skips its normal "open a PR" flow so the workflow can commit directly to the tap's default branch instead (see next decision).
    - *Alternative considered*: `Justintime50/homebrew-releaser` (a popular GitHub Action for exactly this). Rejected because it targets Formulas built from source-tarballs/scripts, not Casks wrapping a prebuilt `.dmg`/`.app` — it does not generate the `app "TaskNxt.app"`/`zap` stanzas a Cask needs.
- **Direct commit to the tap's default branch, not a PR**: the tap is a single-maintainer, automation-only repo with no review process, so a PR would just need to be immediately self-merged. The new workflow step commits and pushes straight to `main` using a PAT.
- **New fine-grained PAT (`HOMEBREW_TAP_TOKEN`) stored as a repo secret**: the default `GITHUB_TOKEN` is scoped to the repo the workflow runs in and cannot push to the separate tap repo, so a PAT with `contents: write` on `homebrew-tasknxt` is required.
- **Runs on the existing tag-triggered job, gated to real releases**: reuses the `startsWith(github.ref, 'refs/tags/v')` condition already used for "Publish GitHub Release", so dev builds (pushes to `main`) never touch the tap.

## Risks / Trade-offs

- [Risk] `brew bump-cask-pr` runs on the `macos-15` runner already used for the build, but requires a local Homebrew installation and internet access to download the `.dmg` to compute its checksum, adding a few minutes to the release job → Mitigation: acceptable one-time cost per tagged release; runs after the DMG/Release steps so it never blocks the build/test/package path if it fails (`continue-on-error` is not set, so a Homebrew-side failure does surface, but it can't fail the app build itself since it's the last step).
- [Risk] A PAT with push access to another repo is a higher-privilege secret than the default `GITHUB_TOKEN` → Mitigation: scope it as a fine-grained PAT limited to `contents: write` on the single `homebrew-tasknxt` repo only, not a classic all-repo token.
- [Risk] Gatekeeper will still warn on first launch since the `.dmg`/`.app` is only ad-hoc signed (not notarized) → Mitigation: out of scope (see Non-Goals); document the same right-click-open workaround Homebrew Cask users would need, matching current manual-download behavior.
- [Risk] Tap repo doesn't exist yet — this change's automation will fail until it's created once, manually, with an initial `Casks/tasknxt.rb` and branch → Mitigation: tracked as an explicit one-time manual setup task in tasks.md, not something CI can bootstrap itself.

## Migration Plan

1. Manually create the `thamaraiselvam/homebrew-tasknxt` repo and commit an initial `Casks/tasknxt.rb` (pointing at the current latest release) so the tap is installable before automation exists.
2. Create the fine-grained PAT and add it as `HOMEBREW_TAP_TOKEN` in this repo's Actions secrets.
3. Add the new workflow step; verify end-to-end by cutting a test tag and confirming the tap's Cask file updates and `brew install`/`brew upgrade` works against it.
4. Add the `brew install` instructions to the README.

Rollback: revert the workflow step (and/or delete the tap repo); existing `.dmg`-based manual installs are unaffected either way since they're independent distribution channels.
