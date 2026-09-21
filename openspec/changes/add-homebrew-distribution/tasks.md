## 1. Tap repository setup (one-time, manual)

- [x] 1.1 Create the `thamaraiselvam/homebrew-tasknxt` GitHub repository (public, name must start with `homebrew-` for tap discovery) — done by the repo owner (cloned locally at `/Users/tham/repo/github/homebrew-tasknxt`); SSH access there authenticates as `thamaraiselvam` directly, unlike this session's `gh` CLI account
- [x] 1.2 Author an initial `Casks/tasknxt.rb` with real values from the published `v1.0.0` release (`sha256` from `gh release view v1.0.0 --json assets`), plus a tap `README.md`; committed and pushed to `homebrew-tasknxt` main
- [x] 1.3 Verified locally: `brew tap thamaraiselvam/tasknxt && brew install --cask tasknxt` resolves the cask, downloads the `.dmg`, and passes checksum verification (install itself stopped only because `/Applications/TaskNxt.app` already existed from an earlier manual install — confirms the Cask definition is correct)

## 2. Release automation credentials

- [ ] 2.1 Create a fine-grained GitHub PAT scoped to `contents: write` on only the `homebrew-tasknxt` repo — **manual, pending**: fine-grained PATs can only be created interactively via github.com/settings, not via `gh`/API; requires the repo owner
- [ ] 2.2 Add it as the `HOMEBREW_TAP_TOKEN` secret in the `tasknxt` repo's Actions settings — **manual, pending**: blocked on 2.1 (needs the token value); this session also confirmed it lacks `secrets` read/write permission on `thamaraiselvam/tasknxt` (`gh secret list` → 403)

## 3. Workflow automation

- [x] 3.1 Add a new `homebrew` job to `build-and-release.yml`, gated on `startsWith(github.ref, 'refs/tags/v')`, `needs: build`, running on `macos-15`
- [x] 3.2 In that job, run `brew bump-cask-pr --write-only --no-audit --no-browse --version="$VERSION" --url="$DMG_URL" thamaraiselvam/tasknxt/tasknxt` against a local checkout of the tap repo (checked out via `actions/checkout` with `HOMEBREW_TAP_TOKEN`, tapped from that local path)
- [x] 3.3 Commit and push the updated `Casks/tasknxt.rb` straight to the tap's default branch using `HOMEBREW_TAP_TOKEN` (no-op commit if nothing changed)
- [ ] 3.4 Verify by pushing a test tag: confirm the tap repo's Cask file is auto-updated with the new version/sha256/url and that `brew update && brew upgrade tasknxt` picks it up — blocked on 2.1/2.2 (needs `HOMEBREW_TAP_TOKEN` to exist); workflow validated with `actionlint` (0 issues) but not run end-to-end yet since the secret isn't set

## 4. Documentation

- [x] 4.1 Add a "Homebrew" install option to README.md's "Install" section (`brew install thamaraiselvam/tasknxt/tasknxt`), alongside the existing "Build from source" instructions
- [x] 4.2 Note the Gatekeeper/ad-hoc-signing caveat (same first-launch right-click-open step as the manual `.dmg` download) so Homebrew users aren't surprised
