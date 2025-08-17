# Спецификация CLI/Help

Статус: Draft

## Команды и флаги
- `<report> <repo_path> [options]`
  - `<repo_path>` по умолчанию `.` если опущен
  - альтернативно можно указать репозиторий через `--repo PATH`
- `--format, --out, --limit, --time-bucket, --since/--until, --branch, --author/--exclude-author, --path/--exclude-path, --no-color, --theme, --metric`.

## Совместимости/валидации
- Примеры несовместимых флагов и ожидаемых ошибок.

## Генерация справки
Опорный источник — YAML с описанием команд/флагов. На его основе генерируется `--help` и разделы README.

### Структура YAML (пример)
```yaml
commands:
  - name: pretty-git
    summary: Git analytics reports
    arguments:
      - name: report
        values: [summary, activity, authors, files, heatmap, hotspots, churn, ownership, languages]
    options:
      - name: --format
        values: [console, json, csv, yaml, xml, markdown]
        default: console
      - name: --limit
        values: ["0", "all", "<int>"]
        default: 10
      - name: --time-bucket
        values: [day, week, month]
        applies_to: [activity, heatmap]
      - name: --metric
        values: [bytes, files, loc]
        applies_to: [languages]
      - name: --since
        type: datetime
      - name: --until
        type: datetime
      - name: --branch
        repeatable: true
      - name: --path
        repeatable: true
      - name: --exclude-path
        repeatable: true
      - name: --author
        repeatable: true
      - name: --exclude-author
        repeatable: true
      - name: --out
        type: path
      - name: --no-color
      - name: --theme
        values: [basic, bright, mono]
```

### Генерация `--help`
- Рендер дерева команд, опций, значений и значений по умолчанию.
- Для опций с ограниченным доменом значений — печать допустимых значений.
- Для repeatable — пометка `repeatable`.
- Для `applies_to` — вывод ограничений с примерами.
- Автоматическая синхронизация README: куски help вставляются в секции при сборке.

## Матрица несовместимых/условных флагов

- `--time-bucket` применим только к: `activity`, `heatmap`.
- `--metric` применим только к: `languages`.
- `--no-color` влияет только на `console` формат.
- Примеры конфликтов:
  - `--time-bucket` с `authors|files|summary|hotspots|churn|ownership|languages` → ошибка (exit 1).
  - Негативные `--limit` → ошибка (exit 1).
  - `--since > --until` → ошибка (exit 1).

Валидация выполняется на уровне CLI до запуска анализа. Сообщения см. `docs/error_handling.md`.
