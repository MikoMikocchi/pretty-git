# Базовая проверка производительности (v0.1.x)

Этот документ описывает, как запустить простую базовую проверку производительности для Pretty Git без внешних зависимостей.

## Цели
- Измерять «стеночное» время (wall time) для каждого отчёта в нескольких итерациях.
- Опционально снимать RSS процесса на Unix/macOS (best‑effort через `ps`).
- Оставаться переносимым (только stdlib) и дружелюбным к CI.

## Задача Rake

```
rake perf:baseline REPO=/path/to/repo REPORTS="summary,files,authors,languages,activity,heatmap,hotspots,churn,ownership" FORMAT=console ITERS=3 [SINCE=2024-01-01] [UNTIL=2024-12-31]
```

- `REPO`: путь к Git‑репозиторию (по умолчанию — текущая директория).
- `REPORTS`: список отчётов через запятую.
- `FORMAT`: формат вывода (`console|json|csv|md|yaml|xml`).
- `ITERS`: число итераций на отчёт (по умолчанию: 3).
- `SINCE`/`UNTIL`: опциональные временные фильтры, прокидываются в CLI.
- `--allocs`: измерять число аллокаций за итерацию (через `GC.stat`, best‑effort).

### Внутреннее профилирование (PG_PROF)

- Флаг `--prof` для `scripts/perf_baseline.rb` включает ENV `PG_PROF=1` для дочерних процессов `pretty-git`.
- При включении профилирования stderr каждого запуска сохраняется в файл `perf_profile_<report>_iterNN.log` рядом со скриптом.
- Профили сейчас покрывают:
  - `Git::Provider` — общее время, число заголовков коммитов и строк `numstat`.
  - `Analytics::Languages` — общее время и число обработанных файлов.
- В логах присутствуют как человекочитаемые строки `[pg_prof]`, так и компактные JSON‑сводки `[pg_prof_json]` для возможного парсинга.

## Скрипт

Задача делегирует выполнение `scripts/perf_baseline.rb`, который:
- Вызывает напрямую CLI `bin/pretty-git` с заданным отчётом и параметрами.
- Использует `Process.clock_gettime(MONOTONIC)` для замера времени.
- Печатает время по итерациям и сводку (min/avg/max и пиковый RSS, если доступен).

Пример с аллокациями:

```
rake perf:baseline REPO=. REPORTS="summary,files" FORMAT=json ITERS=2 -- --allocs
```

Пример с профилированием:

```
rake perf:baseline REPO=. REPORTS="languages" FORMAT=json ITERS=1 PERF_ARGS="--prof"
```

## Заметки и советы
- Для стабильных измерений закройте фоновые приложения и работайте от сети.
- Предпочтительны крупные реальные репозитории или синтетические тяжёлые фикстуры, чтобы проявить узкие места.
- Используйте `FORMAT=json`, чтобы уменьшить накладные расходы консольного рендера в замерах.
- Сохраняйте результаты и окружение краткой заметкой в этом файле или логах CI.

## Результаты прогонов

### 2025-08-18 00:49 (+03:00)

- __Параметры__: `REPO=.` `REPORTS="summary,files"` `FORMAT=json` `ITERS=2`
- __Сводка__:
  - `summary`: min=0.15s avg=0.30s max=0.45s, RSS≈448 KB
  - `files`:   min=0.15s avg=0.16s max=0.16s, RSS≈464 KB

### 2025-08-18 00:54 (+03:00)

- __Параметры__: `REPO=.` `REPORTS="summary,files"` `FORMAT=json` `ITERS=2` `ALLOCS=1`
- __Сводка__:
  - `summary`: min=0.21s avg=0.21s max=0.21s, RSS≈464 KB; allocs(min/avg/max)=77/98/118
  - `files`:   min=0.21s avg=0.21s max=0.21s, RSS≈448 KB; allocs(min/avg/max)=77/77/77

### 2025-08-18 01:07 (+03:00)

- __Параметры__: `REPO=~/TypeScript-main` `REPORTS="summary,files,authors,languages,activity,heatmap,hotspots,churn,ownership"` `FORMAT=json` `ITERS=3` `ALLOCS=1`
- __Сводка__:
  - `summary`:   min=0.17s avg=0.17s max=0.18s, RSS≈464 KB;  allocs(min/avg/max)=83/99/130
  - `files`:     min=0.16s avg=0.16s max=0.16s, RSS≈5344 KB; allocs(min/avg/max)=83/83/83
  - `authors`:   min=0.16s avg=0.16s max=0.16s, RSS≈448 KB;  allocs(min/avg/max)=83/83/83
  - `languages`: min=5.56s avg=5.83s max=6.03s, RSS≈1312 KB; allocs(min/avg/max)=77/77/77
  - `activity`:  min=0.16s avg=0.19s max=0.25s, RSS≈624 KB;  allocs(min/avg/max)=83/83/83
  - `heatmap`:   min=0.16s avg=0.16s max=0.17s, RSS≈480 KB;  allocs(min/avg/max)=83/83/83
  - `hotspots`:  min=0.16s avg=0.16s max=0.16s, RSS≈1312 KB; allocs(min/avg/max)=83/83/83
  - `churn`:     min=0.16s avg=0.16s max=0.16s, RSS≈560 KB;  allocs(min/avg/max)=83/83/83
  - `ownership`: min=0.16s avg=0.16s max=0.17s, RSS≈448 KB;  allocs(min/avg/max)=83/83/83

### 2025-08-18 01:25 (+03:00) — Профилирование (PG_PROF) на TypeScript-main

- Параметры: `REPO=~/TypeScript-main` `REPORTS="summary,files,authors,languages,activity,heatmap,hotspots,churn,ownership"` `FORMAT=json` `ITERS=3` `--prof` `--allocs`
- Из `perf_profile_languages_iterNN.log`:
  - files≈39601, время по итерациям: 4.848s, 4.759s, 4.791s (avg≈4.80–4.95s)
  - Вывод `[pg_prof_json]` содержит: `{component:"languages", time_sec: <...>, files:39601, metric:"bytes"}`
- Наблюдения:
  - Узкое место — `Analytics::Languages` (скан файлов + подсчёт строк/байт).
  - В stderr отчётов, использующих git, встречалось: `fatal: your current branch 'master' does not have any commits yet`.
    - Вероятная причина: состояние ветки после shallow clone. Проверка: `git -C ~/TypeScript-main log -1`.
    - Если нужно: переключиться на основную ветку и/или углубить историю:
      - `git -C ~/TypeScript-main switch -c main --track origin/main` (если основная ветка — main)
      - `git -C ~/TypeScript-main fetch --deepen 100` (или `--unshallow`)

#### 2025-08-18 01:27 (+03:00) — После оптимизаций (Languages)

- Изменения:
  - В `lib/pretty_git/analytics/languages.rb` строки считаются только при `metric=loc` (для `bytes|files` не читаем файл построчно).
  - В `each_source_file()` убран `File.expand_path` — работаем с относительными путями.
- Результат (TypeScript-main, ITERS=1, `--prof`): `languages` ≈ 1.30s (ранее ≈ 4.9–5.0s).
- Следующий шаг: замерить ITERS=3 и при необходимости оптимизировать include/exclude фильтры.
