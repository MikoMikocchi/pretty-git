# Pretty Git

[![CI](https://github.com/MikoMikocchi/pretty-git/actions/workflows/ci.yml/badge.svg)](https://github.com/MikoMikocchi/pretty-git/actions/workflows/ci.yml)
[![Gem Version](https://img.shields.io/gem/v/pretty-git)](https://rubygems.org/gems/pretty-git)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Ruby 3.4+](https://img.shields.io/badge/ruby-3.4%2B-red)

<p align="right">
  <b>English</b> | <a href="./README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="docs/images/PrettyGitIcon.png" alt="Pretty Git Logo" width="200">
  <br>
</p>

Generator of rich reports for a local Git repository: summary, activity, authors, files, heatmap, languages. Output to Console and formats: JSON, CSV, Markdown, YAML, XML.

— License: MIT.

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI and Options](#cli-and-options)
  - [Filters](#filters)
  - [Output format](#output-format)
  - [Write to file](#write-to-file)
  - [Exit codes](#exit-codes)
- [Reports and Examples](#reports-and-examples)
  - [summary — repository summary](#summary--repository-summary)
  - [activity — activity (day/week/month)](#activity--activity-dayweekmonth)
  - [authors — by authors](#authors--by-authors)
  - [files — by files](#files--by-files)
  - [heatmap — commit heatmap](#heatmap--commit-heatmap)
  - [languages — languages](#languages--languages)
- [Exports](#exports)
  - [Console](#console)
  - [JSON](#json)
  - [CSV (DR-001)](#csv-dr-001)
  - [Markdown](#markdown)
  - [YAML](#yaml)
  - [XML](#xml)
- [Determinism and Sorting](#determinism-and-sorting)
- [Windows Notes](#windows-notes)
- [Diagnostics and Errors](#diagnostics-and-errors)
- [FAQ](#faq)
- [Development](#development)
- [License](#license)

## Features
* **Reports**: `summary`, `activity`, `authors`, `files`, `heatmap`, `languages`.
* **Filters**: branches, authors, paths, time period.
* **Exports**: `console`, `json`, `csv`, `md`, `yaml`, `xml`.
* **Output**: to stdout or file via `--out`.

## Requirements
* **Ruby**: >= 3.4 (recommended 3.4.x)
* **Git**: installed and available in `PATH`

## Installation

### 🍺 Homebrew (recommended)
```bash
brew tap MikoMikocchi/tap
brew install pretty-git
```

### ♦️ RubyGems
```bash
gem install pretty-git
```
Choose one:

1) 🛠️ From source (recommended for development)

```bash
git clone <repo_url>
cd pretty-git
bin/setup
# run:
bundle exec bin/pretty-git --help
```

2) ♦️ As a gem (after the first release)

```bash
gem install pretty-git
pretty-git --version
```

3) 📦 Via Bundler

```ruby
# Gemfile
gem 'pretty-git', '~> 0.1'
```
```bash
bundle install
bundle exec pretty-git --help
```

## Quick Start
```bash
# Repository summary to console
bundle exec bin/pretty-git summary .

# Authors in JSON written to file
bundle exec bin/pretty-git authors . --format json --out authors.json

# Weekly activity for period only for selected paths
bundle exec bin/pretty-git activity . --time-bucket week --since 2025-01-01 \
  --paths app,lib --format csv --out activity.csv
```

## CLI and Options
General form:

```bash
pretty-git <report> <repo_path> [options]
```

Available reports: `summary`, `activity`, `authors`, `files`, `heatmap`, `languages`.

Key options:
* **--format, -f** `console|json|csv|md|yaml|xml` (default `console`)
* **--out, -o** Path to write output file
* **--limit, -l** Number of items shown; `all` or `0` — no limit
* **--time-bucket** `day|week|month` (for `activity`)
* **--since/--until** Date/time in ISO8601 or `YYYY-MM-DD` (DR-005)
* **--branch** Multi-option, can be specified multiple times
* **--author/--exclude-author** Filter by authors
* **--path/--exclude-path** Filter by paths (comma-separated or repeated option)
* **--no-color** Disable colors in console
* **--theme** `basic|bright|mono` — console theme (default `basic`; `mono` forces monochrome)

Examples with multiple values:

```bash
# Multiple branches
pretty-git summary . --branch main --branch develop

# Filter authors (include/exclude)
pretty-git authors . --author alice@example.com --exclude-author bot@company

# Filter paths
pretty-git files . --path app,lib --exclude-path vendor,node_modules
```

### Filters
Filters apply at commit fetch and later aggregation. Date format: ISO8601 or `YYYY-MM-DD`. If timezone is omitted — your local zone is assumed; output timestamps are normalized to UTC.

### Output format
Set via `--format`. For file formats it’s recommended to use `--out`.

### Write to file
```bash
pretty-git authors . --format csv --out authors.csv
```

### Exit codes
* `0` — success
* `1` — user error (unknown report/format, bad arguments)
* `2` — system error (git error etc.)

## Reports and Examples

### summary — repository summary
```bash
pretty-git summary . --format json
```
Contains totals (commits, authors, additions, deletions) and top authors/files.

### activity — activity (day/week/month)
```bash
pretty-git activity . --time-bucket week --format csv
```
CSV columns: `bucket,timestamp,commits,additions,deletions`.
JSON example:
```json
[
  {"bucket":"week","timestamp":"2025-06-02T00:00:00Z","commits":120,"additions":3456,"deletions":2100},
  {"bucket":"week","timestamp":"2025-06-09T00:00:00Z","commits":98,"additions":2890,"deletions":1760}
]
```

### authors — by authors
```bash
pretty-git authors . --format md --limit 10
```
CSV columns: `author,author_email,commits,additions,deletions,avg_commit_size`.
Markdown example:
```markdown
| author | author_email | commits | additions | deletions | avg_commit_size |
|---|---|---:|---:|---:|---:|
| Alice | a@example.com | 2 | 5 | 1 | 3.0 |
| Bob   | b@example.com | 1 | 2 | 0 | 2.0 |
```

### files — by files
```bash
pretty-git files . --paths app,lib --format csv
```
CSV columns: `path,commits,additions,deletions,changes`.
XML example:
```xml
<files>
  <item path="app/models/user.rb" commits="42" additions="2100" deletions="1400" changes="3500" />
  <item path="app/services/auth.rb" commits="35" additions="1500" deletions="900" changes="2400" />
  <generated_at>2025-01-31T00:00:00Z</generated_at>
  <repo_path>/abs/path/to/repo</repo_path>
  <report>files</report>
  <period>
    <since/>
    <until/>
  </period>
</files>
```

### heatmap — commit heatmap
```bash
pretty-git heatmap . --format json
```
JSON: an array of buckets for (day-of-week × hour) with commit counts.
CSV example:
```csv
dow,hour,commits
1,10,5
1,11,7
```

### languages — languages
```bash
pretty-git languages . --format md --limit 10
```
Determines language distribution in a repository by summing file bytes per language (similar to GitHub Linguist). Output includes language, total size (bytes) and percent share.

Console example:
```text
Languages for .

language     bytes percent
-------- ---------- -------
Ruby        123456    60.0
JavaScript   78901    38.3
Markdown      1200     1.7
```

![Console output — languages](docs/images/PrettyGitConsoleLanguages.png)

Notes:
- **Detection**: by file extensions and certain filenames (`Makefile`, `Dockerfile`).
- **Exclusions**: binary files and "vendor"-like directories are ignored. By default `vendor/`, `node_modules/`, `.git/`, build artifacts and caches are skipped. For Python projects additional directories are skipped: `.venv/`, `venv/`, `env/`, `__pycache__/`, `.mypy_cache/`, `.pytest_cache/`, `.tox/`, `.eggs/`, `.ruff_cache/`, `.ipynb_checkpoints/`.
- **JSON**: JSON is not counted as a language by default to avoid data files skewing statistics.
- **Path filters**: use `--path/--exclude-path` (glob patterns supported) to focus on relevant areas.
- **Limit**: `--limit N` restricts number of rows; `0`/`all` — no limit.
- **Console colors**: language names use approximate GitHub colors; `--no-color` disables, `--theme mono` makes output monochrome.

See also: [Ignored directories and files](#ignored-directories-and-files).

Export:
- CSV/MD: columns — `language,bytes,percent`.
- JSON/YAML/XML: full report structure including metadata (`report`, `generated_at`, `repo_path`).

## Exports

Below are exact serialization rules for each format to ensure compatibility with common tools (Excel, BI, CI, etc.).

### Console
![Console output — basic theme](docs/images/PrettyGitConsole.png)
_Example terminal output (theme: basic)._ 
* **Colors**: headers and table heads highlighted; totals: `commits` — yellow, `+additions` — green, `-deletions` — red. `--no-color` fully disables coloring.
* **Themes**: `--theme basic|bright|mono`. `bright` — more saturated headers, `mono` — monochrome (same as `--no-color`).
* **Highlight max**: numeric columns underline max values in bold for quick scanning.
* **Terminal width**: table output respects terminal width; first column is gracefully truncated with ellipsis `…` if needed.
* **Encoding**: UTF‑8, LF line endings.
* **Purpose**: human-readable terminal output.
* **Layout**: boxed tables, auto-truncation of long values.

### JSON
* **Keys**: `snake_case`.
* **Numbers**: integers/floats without localization (dot decimal separator).
* **Boolean**: `true/false`; **null**: `null`.
* **Date/time**: ISO8601 in UTC, e.g. `2025-01-31T00:00:00Z`.
* **Order**: fields arranged logically and consistently (e.g., `report`, `generated_at`, `repo_path`, then data).
* **Encoding/line endings**: UTF‑8, LF.
* **Suggested extension**: `.json`.
* **Example**:
  ```json
  {"report":"summary","generated_at":"2025-01-31T00:00:00Z","totals":{"commits":123}}
  ```

### CSV
* **Structure**: flat table, first line is header.
* **Encoding**: UTF‑8 without BOM.
* **Delimiter**: comma `,`.
* **Escaping**: RFC 4180 — fields with commas/quotes/newlines are enclosed in double quotes, double quotes inside are doubled.
* **Empty values**: empty cell (not `null`).
* **Numbers**: no thousand separators, dot as decimal.
* **Date/time**: ISO8601 UTC.
* **Column order**: fixed per report and stable.
* **Line endings**: LF.
* **Suggested extension**: `.csv`.
* **Excel**: specify UTF‑8 on import.
* **Example**:
  ```csv
  author,author_email,commits,additions,deletions,avg_commit_size
  Alice,a@example.com,2,5,1,3.0
  Bob,b@example.com,1,2,0,2.0
  ```

### Markdown
* **Tables**: GitHub Flavored Markdown.
* **Alignment**: numeric columns are right-aligned (`---:`).
* **Encoding/line endings**: UTF‑8, LF.
* **Suggested extension**: `.md`.
* **Empty datasets**: header-only table or a short `No data` message (depends on report).
* **Example**:
  ```markdown
  | path | commits | additions | deletions |
  |---|---:|---:|---:|
  | app/models/user.rb | 42 | 2100 | 1400 |
  ```

### YAML
* **Structure**: full result hierarchy.
* **Keys**: serialized as strings.
* **Numbers/boolean/null**: standard YAML (`123`, `true/false`, `null`).
* **Date/time**: ISO8601 UTC as strings.
* **Encoding/line endings**: UTF‑8, LF.
* **Suggested extension**: `.yml` or `.yaml`.
* **Example**:
  ```yaml
  report: authors
  generated_at: "2025-01-31T00:00:00Z"
  items:
    - author: Alice
      author_email: a@example.com
      commits: 2
    - author: Bob
      author_email: b@example.com
      commits: 1
  ```

### XML
* **Structure**: elements correspond to keys; arrays — repeated `<item>` or specialized tags.
* **Attributes**: for compact rows (e.g., files report) main fields may be attributes.
* **Text nodes**: used for scalar values when needed.
* **Escaping**: `& < > " ' ` per XML rules; CDATA may be used for arbitrary text.
* **Date/time**: ISO8601 UTC.
* **Encoding/line endings**: UTF‑8, LF; declaration `<?xml version="1.0" encoding="UTF-8"?>` may be added by the generator.
* **Suggested extension**: `.xml`.
* **Example**:
  ```xml
  <authors>
    <item author="Alice" author_email="a@example.com" commits="2" />
    <item author="Bob" author_email="b@example.com" commits="1" />
    <generated_at>2025-01-31T00:00:00Z</generated_at>
    <repo_path>/abs/path</repo_path>
  </authors>
  ```

## Ignored directories and files

To keep language statistics meaningful, certain directories and file types are skipped by default.

**Directories ignored** (any path segment matching one of these):

```
vendor, node_modules, .git, .bundle, dist, build, out, target, coverage,
.venv, venv, env, __pycache__, .mypy_cache, .pytest_cache, .tox, .eggs, .ruff_cache,
.ipynb_checkpoints
```

**Binary/data extensions ignored**:

```
.png, .jpg, .jpeg, .gif, .svg, .webp, .ico, .bmp,
.pdf, .zip, .tar, .gz, .tgz, .bz2, .7z, .rar,
.mp3, .ogg, .wav, .mp4, .mov, .avi, .mkv,
.woff, .woff2, .ttf, .otf, .eot,
.jar, .class, .dll, .so, .dylib,
.exe, .bin, .dat
```

These lists mirror the implementation in `lib/pretty_git/analytics/languages.rb` and may evolve.

## Determinism and Sorting
Output is deterministic given the same input. Sorting for files/authors: by changes (desc), then by commits (desc), then by path/name (asc). Limits are applied after sorting; `all` or `0` means no limit.

## Windows Notes
Primary targets — macOS/Linux. Windows is supported best‑effort:
* Running via Git Bash/WSL is OK
* Colors can be disabled by `--no-color`
* Carefully quote arguments when working with paths

## Diagnostics and Errors
Typical issues and solutions:

* **Unknown report/format** — check the first argument and `--format`.
* **Invalid date format** — use ISO8601 or `YYYY-MM-DD` (e.g., `2025-01-31` or `2025-01-31T12:00:00Z`).
* **Git not available** — ensure `git` is installed and in the `PATH`.
* **Empty result** — check your filters (`--since/--until`, `--branch`, `--path`); your selection might be too narrow.
* **CSV encoding issues** — files are saved as UTF‑8; when opening in Excel, pick UTF‑8.

## FAQ
* **Why Ruby 3.4+?** The project uses dependencies aligned with Ruby 3.4+ and targets the current ecosystem.
* **New formats?** Yes, add a renderer under `lib/pretty_git/render/` and wire it in the app.
* **Where does data come from?** From system `git` via CLI calls.

## Development
```bash
# Install deps
bin/setup

# Run tests and linter
bundle exec rspec
bundle exec rubocop
```

Style — RuboCop clean. Tests cover aggregators, renderers, CLI, and integration scenarios (determinism, format correctness).

## License
MIT © Contributors
