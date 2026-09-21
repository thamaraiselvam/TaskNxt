## Why

TaskNxt is currently only installable by manually downloading a `.dmg` from GitHub Releases (or building from source). macOS users increasingly expect `brew install` for menu-bar utilities like this one, and every new release today requires a manual re-download — there's no way for an existing install to be found and upgraded automatically via Homebrew.

## What Changes

- Publish a Homebrew Cask (`tasknxt`) in a new tap repository (`thamaraiselvam/homebrew-tasknxt`) so users can run `brew install thamaraiselvam/tasknxt/tasknxt` (or `brew tap` + `brew install tasknxt`).
- Extend the existing tag-triggered release workflow (`build-and-release.yml`) so that, immediately after a GitHub Release is published with its `.dmg` asset, a follow-up job automatically updates the Cask's `version`/`sha256`/`url` in the tap repo — no manual step required to keep Homebrew in sync with new releases.
- Document the `brew install` path in the README's "Install" section alongside the existing "Build from source" instructions.

## Capabilities

### New Capabilities
(none — this only adds a packaging/distribution and CI mechanism; no app behavior changes)

### Modified Capabilities
(none — `skip_specs: true` is set in this change's `.openspec.yaml` since no spec-level behavior changes)

## Impact

- `README.md` (new "Homebrew" install instructions)
- `.github/workflows/build-and-release.yml` (new job to publish/update the Cask after a tagged release)
- New repository `thamaraiselvam/homebrew-tasknxt` (the tap), containing `Casks/tasknxt.rb`
- New secret: a GitHub PAT (e.g. `HOMEBREW_TAP_TOKEN`) with push access to the tap repo, stored in this repo's Actions secrets
