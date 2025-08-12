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
  bundle exec rubocop -f s
  bundle exec rspec -f documentation
  ```
- Preferred commit style: Conventional Commits
  - feat(scope): summary
  - fix(scope): summary
  - docs, refactor, test, chore, perf
- Write clear PR descriptions. Reference issues when applicable.

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

## Submitting a PR
- Ensure green `rubocop` and `rspec`
- Add/adjust docs when behavior changes
- Include screenshots for console output if UI changed

## Release Process (maintainers)
- Update `CHANGELOG.md`
- Tag release and push gem (when published)
- Announce changes
