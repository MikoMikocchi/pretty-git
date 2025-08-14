# Детерминизм

Статус: Draft

## Политика
- Стабильные сортировки и тайбрейки для всех отчётов.
- Фиксированный порядок полей в JSON/YAML/XML; CSV/MD — фиксированные заголовки.
- Даты/время — ISO8601 UTC.

## Тайбрейки (общие)
1) Основной ключ метрики (desc), затем
2) Вторичный числовой (desc), затем
3) `path`/`language`/`author_email` (asc)

## Тайбрейки по отчётам
- summary.top_authors: `commits desc`, затем `additions desc`, затем `deletions desc`, затем `author_email asc`.
- summary.top_files: `changes desc`, затем `commits desc`, затем `path asc`.
- activity: `timestamp asc` (bucket start), при одинаковом бакете объединение не допускается.
- authors: `commits desc`, затем `additions desc`, затем `deletions desc`, затем `author_email asc`.
- files: `changes desc`, затем `commits desc`, затем `path asc`.
- heatmap: `day asc`, затем `hour asc`.
- hotspots: `score desc`, затем `commits desc`, затем `changes desc`, затем `path asc`.
- churn: `churn desc`, затем `commits desc`, затем `path asc`.
- ownership: `owner_share desc`, затем `authors desc`, затем `path asc`.
- languages: `bytes desc` (или выбранная метрика), затем `language asc`.

## Интеграционные проверки
- Снимки («golden files») по всем отчётам × форматам × лимитам.
- Хеш‑сравнение вывода при одинаковых входных данных.
 - Фиксация TZ=UTC и локали `C` в тестах/CI.
 - Источник времени мокируется; `generated_at` детерминизирован в снапшотах.

## Связанные документы
- ADR DR‑021 — политика детерминизма.
- `docs/export_schemas/` — схемы для валидации.
