## Release

Follow this checklist to release a new version and distribute via RubyGems and Homebrew:

1) Version bump
- Update `lib/pretty_git/version.rb` (SemVer).
- Update `CHANGELOG.md` — move entries to a new section `X.Y.Z - YYYY-MM-DD`.

2) Commit and tag
- Commit the changes.
- Create an annotated tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
- Push: `git push && git push --tags`

3) CI: publish to RubyGems (automated)
- Workflow: `.github/workflows/release.yml` triggers on tags `v*.*.*`.
- Requires repo secret `RUBYGEMS_API_KEY` with your RubyGems API key.
- The job builds `pretty-git-*.gem` and runs `gem push`.

4) CI: update Homebrew tap (automated)
- Same workflow creates a PR to your tap with updated `url` and `sha256`.
- Requirements:
  - Repository variable `TAP_REPO` (e.g. `MikoMikocchi/homebrew-tap`).
  - Optional repository variable `TAP_BRANCH` (default: `main`).
  - Repository secret `TAP_GH_TOKEN` with `repo` scope to push a branch and open PR.

5) Manual verification
- After the RubyGems publish completes, ensure the tap PR passed CI and merge it.
- Locally test:
  ```bash
  brew untap MikoMikocchi/tap || true
  brew tap MikoMikocchi/tap
  brew install pretty-git
  pretty-git --version
  ```

Notes
- The Homebrew formula installs the gem into `libexec/vendor` and wraps a single binary `pretty-git`; this avoids file-collision issues on reinstall.
- For any hotfix without version change, you can bump `revision` in the tap formula.
# Contributing to Pretty Git

Thanks for your interest in contributing!

## Code of Conduct
Be respectful. Help us keep a welcoming, inclusive community.

## Getting Started
- Ruby 3.4+
- Git available in PATH
- Clone and setup:
  ```bash
  git clone <repo_url>
  cd pretty-git
  bin/setup
  ```

## Development Workflow
- Run linter and tests locally before committing:
  ```bash
  RSpec: `bundle exec rspec`
  RuboCop: `bundle exec rubocop`
  ```
- Preferred commit style: Conventional Commits
  - feat(scope): summary
  - fix(scope): summary
  - docs, refactor, test, chore, perf
- Write clear PR descriptions. Reference issues when applicable.

See also: `docs/testing.md` — стратегия тестирования, правила детерминизма и golden-тесты (как запускать/обновлять снапшоты).

## Project Structure
- `lib/pretty_git/` — app code
  - `analytics/` — report analytics
  - `render/` — renderers (console/csv/json/md/xml/yaml)
- `spec/` — RSpec tests
- `bin/` — executables

## Adding a Report
1. Implement analytics under `lib/pretty_git/analytics/`
2. Wire renderer(s) in `lib/pretty_git/render/`
3. Register in `PrettyGit::App#analytics_for` and CLI
4. Add specs under `spec/analytics/` and for exporters
5. Update README(s)

## Style & Quality
- RuboCop: no offenses in CI
- Keep classes/methods small and readable; extract modules when needed
- Deterministic output for tests and exporters

## Testing
- Unit specs (analytics, renderers)
- CLI specs for arguments parsing and exit codes
- Determinism/integration specs for exporters per docs

Golden tests (snapshots):

```bash
# run golden-only suite
bundle exec rake spec:golden

# update snapshots (review diffs; dedicated commit)
UPDATE_GOLDEN=1 bundle exec rake spec:golden
```

Примечания:
- Обновление снапшотов управляется `UPDATE_GOLDEN=1` (см. `spec/support/golden_helper.rb`).
- Для XML сравнение нормализует завершающие переводы строки/пробелы.

## Submitting a PR
- Ensure green `rubocop` and `rspec`
- Add/adjust docs when behavior changes
- Include screenshots for console output if UI changed

## Release Process (maintainers)
- Update `CHANGELOG.md`
- Tag release and push gem (when published)
- Announce changes
