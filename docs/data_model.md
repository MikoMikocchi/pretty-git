# Источник данных и модель

Версия: 0.1

## Выбор источника
- v1: Используем системный `git` CLI (надёжно, без внешних гемов). Позже возможен переход на `rugged`.

## Причины выбора git CLI
- Доступность и предсказуемость
- Производительные команды (`git log --numstat`, `--since/--until`, `--author`, `--pretty`)
- Лёгкость потокового парсинга без загрузки в память

## Команды (база)
- Получение коммитов c numstat:
```
git log --no-merges --date=iso-strict \
  --pretty=format:%H%x1f%an%x1f%ae%x1f%ad%x1f%s%x1e \
  --numstat [filters]
```
- Фильтры:
  - `--since=<ISO>` `--until=<ISO>`
  - `--author=<pattern>`
  - `--branches=<name>` или `branch -- <paths>` при анализе конкретной ветки
  - Пути: `-- <glob1> <glob2>`

## Внутренние структуры
```ruby
module PrettyGit
  module Types
    Commit = Struct.new(
      :sha, :author_name, :author_email, :authored_at, :message,
      :additions, :deletions, :files, keyword_init: true
    )

    FileStat = Struct.new(:path, :additions, :deletions, keyword_init: true)

    TimeBucket = Struct.new(:key, :commits, :additions, :deletions, keyword_init: true)
  end
end
```

## Контракты провайдера
```ruby
# input: фильтры
# output: Enumerator<PrettyGit::Types::Commit>
provider.each_commit(filters) { |commit| ... }
```

## Контракты агрегаторов
```ruby
# на вход — перечислитель коммитов, на выход — Hash/DTO для дальнейшего рендера
Analytics::Summary.call(enum, filters) => Hash
Analytics::Activity.call(enum, bucket: :week) => Hash
Analytics::Authors.call(enum, filters) => Hash
Analytics::Files.call(enum, limit: 10) => Hash
Analytics::Heatmap.call(enum) => Hash
```

## Валидация и timezone
- Преобразуем всё время в UTC ISO8601.
- Входные даты валидируем и нормализуем.

## Семантика фильтров
- Ветки: по умолчанию текущая; при нескольких `--branch` использовать объединение коммитов без дублей.
- Пути: `--path`/`--exclude-path` применяются на уровне `git log -- <paths>` и постфильтрации по numstat.
- Авторы: фильтры по имени/email; v1 без сложных регэкспов.

## Потоковая обработка
- Провайдер возвращает ленивый `Enumerator` без накопления всех коммитов в памяти.
- Парсинг `git log --numstat` построчно; коммит закрывается по разделителю `0x1E`.
- Подсчёт additions/deletions как сумма по `FileStat`.

## Детерминированность и сортировки
- Политика детерминизма, порядок и тайбрейки описаны в `docs/determinism.md`.

## Совместимость Windows
- См. `docs/compatibility.md` (пути/CRLF/TTY/WSL) и `docs/architecture.md` (ConsoleRenderer цвета/темы).
