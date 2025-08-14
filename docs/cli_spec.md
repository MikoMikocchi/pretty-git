# CLI Спецификация: pretty-git

> Статус (на текущее состояние):
> - [x] Базовая команда и парсер опций (`--help`, `--version`)
> - [x] Опции: `--repo`, `--branch`, `--author`, `--exclude-author`, `--path`, `--exclude-path`, `--limit`, `--format`, `--out`, `--no-color`
> - [x] Отчёты: `summary`, `authors`
> - [x] Коды возврата 0/1/2
> - [x] Отчёты: `activity`, `files`, `heatmap`
> - [x] Отчёт: `languages`
> - [x] Форматы: `csv`, `md`, `yaml`, `xml`
> 
> Примечание: исчерпывающий справочник по флагам и совместимостям — в `docs/cli_help.md`. Ниже — поведенческие требования и примеры.

Версия: 0.1

## Команда
```
pretty-git [REPORT] [options]
```
- REPORT (опц.): имя отчёта. По умолчанию `summary`.
- Рабочая директория должна быть внутри Git-репозитория или указывается `--repo`.

## Отчёты (v1)
- `summary` — сводка репозитория
- `activity` — активность по времени (day/week/month)
- `authors` — статистика по авторам
- `files` — топ-файлы/директории по изменениям
- `heatmap` — час x день недели
- `languages` — распределение по языкам (метрики: bytes|files|loc; %, цвет)
- `hotspots` — «горячие» файлы по активности (score = commits * (additions + deletions))
- `churn` — волатильность по файлам (churn = additions + deletions)
- `ownership` — владение кодом по файлам (владелец и доля по churn)

## Общие опции
- `--repo PATH` — путь к репозиторию (по умолчанию `.`)
- `--branch NAME` — одна или несколько (повторяемая опция)
- `--since DATETIME` — начало периода (ISO8601 или `YYYY-MM-DD`)
- `--until DATETIME` — конец периода (включительно)
- `--author NAME_OR_EMAIL` — включить автора (повторяемая)
- `--exclude-author NAME_OR_EMAIL` — исключить автора (повторяемая)
- `--path GLOB` — включить путь/маску (повторяемая)
- `--exclude-path GLOB` — исключить путь/маску (повторяемая)
- `--time-bucket BUCKET` — `day|week|month` (для `activity`)
- `--limit N` — ограничение топов (по умолчанию 10); `0` или `all` — без ограничения
- `--format FMT` — `console|json|csv|md|yaml|xml` (по умолчанию `console`)
- `--metric NAME` — только для `languages`: `bytes|files|loc` (по умолчанию `bytes`)
- `--out FILE` — путь для сохранения, иначе stdout
- `--no-color` — отключить цвета в консоли
- `--theme THEME` — `basic|bright|mono` (только для консоли)
- `--help` — показать помощь
- `--version` — показать версию
 
## Поведение и значения по умолчанию
- **Ветки (`--branch`)**: дефолт — текущая; несколько значений объединяются (union) без дублей коммитов.
- **Даты/время**: см. `docs/compatibility.md` (TZ/локали) и `docs/determinism.md` (ISO8601 UTC на выводе).
- **Пути**: `--path`/`--exclude-path` применяются на уровне `git log -- <paths>` + постфильтр numstat.
- **Лимиты (`--limit`)**: по умолчанию 10; `0`/`all` — без ограничения. Тайбрейки и порядок — см. `docs/determinism.md`.
- **Детерминированность**: см. политику в `docs/determinism.md`.
- **Цвета и Windows**: см. `docs/compatibility.md` (TTY/CRLF/WSL) и `docs/architecture.md` (ConsoleRenderer/темы).

## Коды возврата
- 0 — успех
- 1 — пользовательская ошибка (валидация опций, не найден репозиторий)
- 2 — системная/непредвиденная ошибка

## Примеры
```
pretty-git summary --since 2025-01-01 --until 2025-08-12 --format md --out report.md
pretty-git activity --time-bucket week --author "Ivan" --format json
pretty-git authors --branch main --since 2025-05-01
pretty-git files --path "app/**/*.rb" --limit 20
pretty-git heatmap --format console
pretty-git languages --limit 15 --format csv --out languages.csv
pretty-git languages --metric files --format md
pretty-git languages --metric loc --format json
pretty-git summary --theme bright
pretty-git hotspots --limit 15 --format console
pretty-git churn --format csv --out churn.csv
pretty-git ownership --limit 20 --format md
```

## Сообщения об ошибках (примеры)
- "Not a git repository: /path/to/dir"
- "Invalid --since: expected ISO8601 or YYYY-MM-DD"
- "Unknown report: <name>. Supported: summary, activity, authors, files, heatmap, languages, hotspots, churn, ownership"
- "No commits found for the given filters"
