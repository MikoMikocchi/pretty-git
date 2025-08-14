# Спецификация форматов вывода

> Статус (на текущее состояние):
> - [x] ConsoleRenderer — заголовки/таблицы/цвета
> - [x] JsonRenderer — pretty JSON
> - [x] CSV экспорт и проверка по DR-001 (RFC 4180, заголовки)
> - [x] Markdown экспорт (таблицы)
> - [x] YAML экспорт
> - [x] XML экспорт

Версия: 0.1

Источник истины для форматов/валидаторов:
- Схемы: `docs/export_schemas/` (JSON Schema и XSD) — использовать для автоматической валидации.
- Правила детерминизма и сортировок: `docs/determinism.md`.
  - JSON: `docs/export_schemas/json/*.schema.json`
  - XML (XSD): `docs/export_schemas/xml/*.xsd`

Примеры:
- JSON: `docs/examples/json/`
- XML: `docs/examples/xml/`

## Общие принципы
- Единая внутренняя структура результатов → сериализация разными экспортёрами.
- Поля в snake_case.
- Таймстемпы в ISO8601 UTC.
 - Детерминированный порядок элементов при одинаковых входных данных.

## Базовые типы
Смотри `docs/data_model.md` (структуры Commit/FileStat и т.п.). Ниже примеры иллюстративны, а не нормативны.

## CSV: Общие правила
- Плоские таблицы без вложенных структур; одна строка — один элемент.
- Заголовок всегда присутствует.
- Кодировка UTF‑8, разделитель — запятая, экранирование по RFC 4180.
- Пустые значения — пустая ячейка (без `null`).

## Схемы колонок по отчётам

### summary
- JSON/YAML/XML/Markdown — основной формат.
- Для CSV допускаются дополнительные таблицы:
  - `summary_totals.csv`: `commits,authors,additions,deletions`
  - `summary_top_authors.csv`: `author,commits,additions,deletions,avg_commit_size`
  - `summary_top_files.csv`: `path,commits,additions,deletions,changes`

### activity (CSV)
- Колонки: `bucket,timestamp,commits,additions,deletions`
- `bucket`: `day|week|month`

### authors (CSV)
- Колонки: `author,author_email,commits,additions,deletions,avg_commit_size`

### files (CSV)
- Колонки: `path,commits,additions,deletions,changes`

### heatmap (CSV)
- Колонки: `dow,hour,commits`
- `dow`: 0..6 (вс..сб) или 1..7 (пн..вс) — выберем 1..7 (пн=1) для согласованности с примером XML

### hotspots (CSV)
- Колонки: `path,score,commits,additions,deletions,changes`
- `score` = `commits * (additions + deletions)`
- Порядок см. `docs/determinism.md` (тайбрейки для отчёта hotspots)

### churn (CSV)
- Колонки: `path,churn,commits,additions,deletions`
- `churn` = `additions + deletions`
- Порядок см. `docs/determinism.md`

### ownership (CSV)
- Колонки: `path,owner,owner_share,authors`
- `owner` — строка `"Name <email>"`
- `owner_share` — доля владельца в %, округление до 2 знаков
- `authors` — количество уникальных авторов файла
- Порядок см. `docs/determinism.md`

## summary (JSON пример)
```json
{
  "report": "summary",
  "repo_path": "/path/to/repo",
  "period": {"since": "2025-01-01T00:00:00Z", "until": "2025-08-12T23:59:59Z"},
  "totals": {"commits": 1234, "authors": 17, "additions": 45678, "deletions": 34567},
  "top_authors": [{"author": "Ivan", "commits": 120, "additions": 3000, "deletions": 2500}],
  "top_files": [{"path": "app/models/user.rb", "changes": 3500, "commits": 42}],
  "generated_at": "2025-08-12T14:40:00Z"
}
```

## activity (CSV пример)
```csv
bucket,timestamp,commits,additions,deletions
week,2025-06-02T00:00:00Z,120,3456,2100
week,2025-06-09T00:00:00Z,98,2890,1760
```

## authors (YAML пример)
```yaml
report: authors
period:
  since: 2025-01-01T00:00:00Z
  until: 2025-08-12T23:59:59Z
items:
  - author: Ivan Petrov <ivan@example.com>
    commits: 120
    additions: 3000
    deletions: 2500
    avg_commit_size: 45
```

## files (Markdown пример)
```markdown
# Top Files

| path | commits | additions | deletions | changes |
|---|---:|---:|---:|---:|
| app/models/user.rb | 42 | 2100 | 1400 | 3500 |
| app/services/auth.rb | 35 | 1500 | 900 | 2400 |
```

## heatmap (XML пример)
```xml
<heatmap generated_at="2025-08-12T14:40:00Z">
  <bucket day="1" hour="10" commits="5" />
  <bucket day="1" hour="11" commits="7" />
</heatmap>
```

## hotspots (JSON пример)
```json
{
  "report": "hotspots",
  "items": [
    {"path": "app/models/user.rb", "score": 7350, "commits": 42, "additions": 2100, "deletions": 1400, "changes": 3500},
    {"path": "app/services/auth.rb", "score": 5760, "commits": 35, "additions": 1500, "deletions": 900, "changes": 2400}
  ]
}
```

## churn (YAML пример)
```yaml
report: churn
items:
  - path: app/models/user.rb
    churn: 3500
    commits: 42
    additions: 2100
    deletions: 1400
  - path: app/services/auth.rb
    churn: 2400
    commits: 35
    additions: 1500
    deletions: 900
```

## ownership (Markdown пример)
```markdown
| path | owner | owner_share | authors |
|---|---|---:|---:|
| app/models/user.rb | Ivan Petrov <ivan@example.com> | 62.5 | 3 |
| app/services/auth.rb | Anna Sidorova <anna@example.com> | 57.14 | 2 |
```

## languages (схемы)

### CSV
- Колонки: `language,<metric>,percent,color`
- `<metric>` — одна из `bytes|files|loc` (выбирается опцией `--metric`, по умолчанию `bytes`)
- `percent` — доля по выбранной метрике (0..100), округление до 2 знаков
- `color` — шестнадцатеричный RGB без `#` (например, `f34b7d`)

### JSON/YAML/XML/Markdown
- Поля элемента: `language`, `bytes`, `files`, `loc`, `percent`, `color`
- Поля верхнего уровня: `metric` (одно из `bytes|files|loc`), `totals` с суммами по всем метрикам: `{bytes,files,loc,languages}`
- Порядок элементов: см. `docs/determinism.md`

Схема для JSON: `docs/export_schemas/json/languages.schema.json`.

### Примеры

CSV пример (`--metric bytes`):
```csv
language,bytes,percent,color
Ruby,120340,65.12,cc342d
JavaScript,40320,21.82,f1e05a
Markdown,24210,13.06,083fa1
```

YAML пример (`--metric files`):
```yaml
report: languages
metric: files
totals: {bytes: 184870, files: 57, loc: 12340, languages: 3}
items:
  - language: Ruby
    bytes: 120340
    files: 30
    loc: 8200
    percent: 52.63
    color: cc342d
  - language: JavaScript
    bytes: 40320
    files: 18
    loc: 2900
    percent: 31.58
    color: f1e05a
```

Markdown пример (`--metric loc`):
```markdown
| language | loc | percent | color |
|---|---:|---:|---|
| Ruby | 8200 | 60.12 | cc342d |
| JavaScript | 2900 | 21.28 | f1e05a |
```

## Консольный вывод (guidelines)
- Заголовок с именем отчёта и периодом
- Таблицы с выравниванием по столбцам
- Цвета: заголовки и важные значения
- Сообщение "No data" при пустом результате
  - Для `heatmap` `dow` использует диапазон 1..7 (пн=1)

## Эволюция форматов и совместимость

- Версионирование схем: верхнеуровневое поле `schema_version` (semver, строка), обязательное для JSON/YAML/XML.
- Обратная совместимость:
  - Добавление новых необязательных полей — допустимо (minor).
  - Переименование/удаление полей — только в major, с периодом деприкации ≥1 минорной версии.
  - Изменение смысла поля — только в major.
- Деприкации:
  - Помечаются в спецификации, добавляется раздел "Deprecated" с датой/версией удаления.
  - Экспортеры могут эмитировать предупреждения в stderr при включённом флаге `--warn-deprecations`.
- Миграции:
  - Для breaking‑изменений публикуется скрипт миграции примеров в `docs/examples/` и changelog‑секция "Migration".
  - Схемы для предыдущих major сохраняются в подпапках `vX/` (не использовать в новых проверках).

## Краевые случаи (edge cases)

- Пустые отчёты → корректные пустые коллекции `items: []` и информативные поля `totals` (0), без `null`.
- Очень длинные пути/имена файлов → не влияют на данные; в консоли только визуальная обрезка.
- Бинарные файлы и большие артефакты → исключаются из некоторых отчётов согласно `languages_map.md`.
- Нормализация Unicode путей (NFC/NFD) — см. `docs/compatibility.md`; экспорт содержит канонизированные пути.
- Таймзоны → все `generated_at` и timestamps в экспортах нормализованы в UTC.
