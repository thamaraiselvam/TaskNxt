## 1. Tap repository setup (one-time, manual)

- [x] 1.1 Create the `thamaraiselvam/homebrew-tasknxt` GitHub repository (public, name must start with `homebrew-` for tap discovery) — done by the repo owner (cloned locally at `/Users/tham/repo/github/homebrew-tasknxt`); SSH access there authenticates as `thamaraiselvam` directly, unlike this session's `gh` CLI account
- [x] 1.2 Author an initial `Casks/tasknxt.rb` with real values from the published `v1.0.0` release (`sha256` from `gh release view v1.0.0 --json assets`), plus a tap `README.md`; committed and pushed to `homebrew-tasknxt` main
- [x] 1.3 Verified locally: `brew tap thamaraiselvam/tasknxt && brew install --cask tasknxt` resolves the cask, downloads the `.dmg`, and passes checksum verification (install itself stopped only because `/Applications/TaskNxt.app` already existed from an earlier manual install — confirms the Cask definition is correct)

## 2. Release automation credentials

- [x] 2.1 Create a fine-grained GitHub PAT scoped to `contents: write` on only the `homebrew-tasknxt` repo — done by the repo owner via github.com/settings/personal-access-tokens
- [x] 2.2 Add it as the `HOMEBREW_TAP_TOKEN` secret in the `tasknxt` repo's Actions settings — confirmed present via `gh secret list --repo thamaraiselvam/tasknxt`

## 3. Workflow automation

- [x] 3.1 Add a new `homebrew` job to `build-and-release.yml`, gated on `startsWith(github.ref, 'refs/tags/v')`, `needs: build`, running on `macos-15`
- [x] 3.2 In that job, run `brew bump-cask-pr --write-only --no-audit --no-browse --version="$VERSION" --url="$DMG_URL" thamaraiselvam/tasknxt/tasknxt` — **fixed after local testing**: `brew bump-cask-pr` always edits Homebrew's own managed tap clone (`$(brew --repository <tap>)`), never an arbitrary `actions/checkout`'d path, so the job now taps directly from GitHub with the token embedded in the remote URL and resolves `TAP_DIR` from `brew --repository` instead of checking out the tap separately
- [x] 3.3 Commit and push the updated `Casks/tasknxt.rb` straight to the tap's default branch using `HOMEBREW_TAP_TOKEN`, from that same Homebrew-managed clone
- [x] 3.4 Verified by pushing a real test tag (`v1.0.1`): the `homebrew` job ran successfully end-to-end — `homebrew-tasknxt/Casks/tasknxt.rb` was auto-updated to version `1.0.1` with the correct sha256/url, committed as `chore: update tasknxt to 1.0.1`, and `brew info --cask thamaraiselvam/tasknxt/tasknxt` confirms it resolves to `1.0.1`

## 4. Documentation

- [x] 4.1 Add a "Homebrew" install option to README.md's "Install" section (`brew install thamaraiselvam/tasknxt/tasknxt`), alongside the existing "Build from source" instructions
- [x] 4.2 Note the Gatekeeper/ad-hoc-signing caveat (same first-launch right-click-open step as the manual `.dmg` download) so Homebrew users aren't surprised
