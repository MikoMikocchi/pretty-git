# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project adheres to Semantic Versioning.

## [Unreleased]
### Added
- Docs: `docs/testing.md` про golden‑workflow, обновление/валидацию снапшотов; ссылки из `README.md`, `README.ru.md`, `CONTRIBUTING.md`.
- Tests: инвариантные проверки детерминизма для YAML/XML рендереров (стабильный вывод при разном порядке входа).

### Changed
- Completions: обновлены bash/zsh автодополнения — добавлены короткие флаги `-f`/`-o`/`-l`, значения для `--time-bucket` (`day|week|month`), автодополнение пути репозитория как второго позиционного аргумента.

## [0.1.5] - 2025-08-17
### Added
- CLI: warn to stderr when `--theme`/`--no-color` are used with non-console `--format` values.
- Docs: expanded Filters documentation (branches, authors, paths, time semantics, verbose diagnostics), schemas/examples pointers, performance and CI usage.
- Tests: unit tests for `PrettyGit::Utils::TimeUtils`.

### Changed
- Internals: extracted time parsing/normalization to `PrettyGit::Utils::TimeUtils` and centralized verbose logging via `PrettyGit::Logger`. `Git::Provider` routes verbose messages through the centralized logger (stderr).
- Verbose mode: documentation clarified to note that diagnostics are printed to stderr for easier CI parsing.

### Deprecated
- Filters: legacy `:until` keyword in `PrettyGit::Filters` initialization is accepted for backward compatibility and emits a deprecation warning; use `:until_at` instead.

### Fixed
- Filters: allow initialization via a single Hash argument (legacy call sites) while preserving `Struct` keyword semantics.

## [0.1.4] - 2025-08-17
### Added
- Integration tests for new reports exports: CSV/Markdown/YAML/XML for `hotspots`, `churn`, `ownership`.
- Schema validations: `rake validate:json`, `rake validate:xml` to ensure format compatibility.
- CI: expanded matrix to include macOS; smoke test for installed binary (`--help`, `--version`).

### Changed
- Renderers (`MarkdownRenderer`, `YamlRenderer`, `XmlRenderer`): deterministic sorting for all new reports according to `docs/determinism.md`.
- XML: per-report root elements in XML exports to match XSDs (`hotspotsReport`, `churnReport`, `ownershipReport`, `languagesReport`, etc.).
- Documentation: `README.md` and `README.ru.md` updated with sections and examples for new reports and all export formats.
- CLI: keep `--time-bucket` permissive; default `time_bucket=nil`.

### Fixed
- Time parsing: interpret date-only inputs (`YYYY-MM-DD`) as UTC midnight and normalize to UTC ISO8601.
- CLI UX: error when `--metric` is used outside `languages` report.
- Tests/specs: updated XML specs to per-report roots; added timezone edge cases; fixed Open3 `popen3` stubs (`chdir:`) and integration requires.


## [0.1.3] - 2025-08-14
### Added
- New analytics reports: `hotspots`, `churn`, `ownership` with sorting, scoring, and limits.
- Exporters: CSV and Markdown support for new reports with dynamic headers via mapping constants.
- Docs: Detailed sections for new reports in `README.md` and `README.ru.md` with usage and examples (CSV/JSON/YAML/XML).

### Changed
- Console: dispatching and rendering wired for new reports; consistent theming and width handling.
- CLI/App: unified analytics dispatch for all reports.
- Docs: public READMEs cleaned up from internal DR-* mentions; anchors and headings aligned (CSV).

### Fixed
- Minor documentation inaccuracies and anchor mismatches.


## [0.1.2] - 2025-08-13
### Added
- Languages report: support multiple metrics — `bytes`, `files`, `loc`; dynamic columns in Console/CSV/Markdown; color and percent fields in output.
- CLI: `--metric` option for the `languages` report with value validation.

### Changed
- Languages: JSON language reinstated in the mapping and color scheme; sorting and percent calculations are based on the selected metric; percentages rounded to two decimals.
- Renderers: updated `csv`, `markdown`, and console renderers to work with dynamic metrics.
- Internal specs updated: `docs/output_formats.md`, `docs/cli_spec.md`, `docs/languages_map.md`.

### Fixed
- Git provider: correct commit counting — emit a new commit when a header is read and remove the record separator from the subject (`lib/pretty_git/git/provider.rb`).
- RuboCop: targeted suppressions for complex methods/classes and style fixes in `cli_helpers.rb`.

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
