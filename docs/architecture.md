# Архитектура Pretty Git

Статус: Draft

## Обзор модулей
- `PrettyGit::App` — точка входа, оркестрация: парсинг CLI, выбор аналитики, выбор экспортёра, вывод/файл.
- `PrettyGit::Analytics::*` — отчёты: `summary`, `activity`, `authors`, `files`, `heatmap`, `languages`, `hotspots`, `churn`, `ownership`.
- `PrettyGit::Exporters::*` — сериализация: `console`, `json`, `csv`, `md`, `yaml`, `xml`.
- `PrettyGit::Git::Provider` — доступ к git (CLI; Rugged — будущий флаг).
- `ConsoleRenderer` — табличный вывод, темы, ширина терминала, подсветка максимумов.

## Потоки данных
`git provider` → `analytics(report)` → `exporter(format)` → `stdout|file`.

## Границы ответственности
- Analytics не знает про формат вывода.
- Exporters не знают про git — только о структуре данных отчёта.
- App связывает всё и валидирует параметры.

## Диаграмма взаимодействия (логическая)
1. CLI: парсинг → валидируем флаги → строим контекст фильтров.
2. Provider: выборка коммитов/диффов (с учётом фильтров).
3. Analytics: агрегации и сортировки (детерминизм, тайбрейки).
4. Exporter: сериализация (стабильный порядок полей/строк).

## Инварианты
- Детерминизм сортировок и заголовков.
- Время в UTC в серилизуемых форматах.
- Отсутствие утечек IO в analytics.

## Связанные документы
- `docs/determinism.md`
- `docs/output_formats.md`
- `docs/performance.md`
