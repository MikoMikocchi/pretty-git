# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]
 

## [0.1.1] - 2025-08-13
### Changed
- Release automation: added GitHub Actions workflow to publish gem on tags and open PR to Homebrew tap (`.github/workflows/release.yml`).
- Documentation: README badges and installation instructions for Homebrew and RubyGems in `README.md` and `README.ru.md`.
- Gemspec: bounded runtime dependencies for `csv` and `rexml` to satisfy RubyGems recommendations.

### Fixed
- Homebrew formula installation stability: formula installs gem into `libexec/vendor` and wraps `pretty-git` binary to avoid file collisions on reinstall.

## [0.1.0] - 2025-08-13
### Added
- Languages report: bytes per language, percentages, sorting, limit.
- Console: colorized languages section; terminal width handling via `TerminalWidth`.
- Export: languages in Markdown/CSV/JSON/YAML/XML.
- CLI: `languages` report wired into App and renderers.
- Tests: analytics/languages specs (aggregation, globs, filename detection, limit).
- Docs: English primary `README.md` + `README.ru.md` with language switcher.
- Docs: Ignored directories and binary extensions list.
- Docs: Added screenshot `PrettyGitConsoleLanguages.png`.

### Changed
- Analytics: exclude JSON from language mapping by default to avoid data skew.
- Analytics: ignore Python env/cache directories by default.
- Refactor: `ConsoleRenderer` split (LanguagesSection, TerminalWidth); reduced complexity.
- App: extracted `analytics_for` from `App#run`.

### Fixed
- RuboCop violations in new specs and minor guard clause spacing.
