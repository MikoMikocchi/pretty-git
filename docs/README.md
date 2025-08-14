# Внутренние спецификации (docs/)

В этой директории находятся разработческие спецификации, ADR и служебные документы, используемые для Spec‑Driven Development.

Важно:
- Эти документы публично доступны в репозитории и служат источником правды для разработки и планирования.
- Чтобы не повышать связность, на файлы `docs/` не следует ссылаться из исходного кода (комментарии, сообщения об ошибках и т.п.) и публичных README/CHANGELOG.
- Папка `docs/` не включается в релизные артефакты (gem/Homebrew, GitHub source archives) через настройки `gemspec` и `.gitattributes`.

Примечание: не путать с директорией тестов `spec/` (RSpec). Здесь — проектные спецификации и инженерные документы.

Состав:
- `analytics_notes.md` — алгоритмы hotspots/churn/ownership, инварианты
- `architecture.md` — архитектура модулей и потоки данных
- `cli_help.md` — полная спецификация CLI и UX
- `cli_spec.md` — поведение CLI (входы/выходы)
- `compatibility.md` — кроссплатформенность, локали/TZ
- `data_model.md` — источник данных и модели
- `decisions.md` — ADR (архитектурные решения)
- `determinism.md` — политика детерминизма и сортировок
- `error_handling.md` — коды ошибок, сообщения, выходы
- `i18n_docs.md` — синхронизация README.md/README.ru.md
- `languages_map.md` — карта языков/расширений/цветов
- `output_formats.md` — форматы и схемы экспорта
- `performance.md` — бюджеты и методика бенчмарков
- `release.md` — релизный пайплайн и чек‑листы
- `requirements.md` — требования и критерии приёмки
- `roadmap.md` — дорожная карта версий (планы)
- `security.md` — политика секретов и доступов
- `tasks.md` — план работ по итерациям
- `examples/` — примеры экспортов (json/xml)
- `export_schemas/` — JSON Schema и XSD, README
- `rfcs/` — RFC‑шаблоны и предложения
- `templates/` — шаблоны spec/adr/rfc/changelog_entry

Политика изменений:
- Все изменения в публичном поведении должны синхронно отражаться здесь и в публичной документации.
- ADR создаются/обновляются при изменении ключевых решений.

## Автоматизация проверок

- Локально:
  - `bundle exec rake validate:json` — валидация JSON примеров против JSON Schema.
  - `bundle exec rake validate:xml` — валидация XML примеров против XSD.
  - `bundle exec rake lint:markdown` — markdownlint для `docs/**/*.md`.
- CI:
  - `/.github/workflows/validate-specs.yml` — запускается только при изменениях в `docs/**` и конфигов линтеров.
  - `/.github/workflows/release-safety.yml` — на тегах релиза выполняет проверку содержимого gem.
- CODEOWNERS:
  - Изменения в `docs/**` и рабочих конфигурациях требуют ревью владельца.

## Исключения из релизов

- `pretty-git.gemspec` включает только код и публичные файлы (`lib/**`, `bin/pretty-git`, `README*`, `LICENSE`, `CHANGELOG.md`).
- `.gitattributes` c `export-ignore` исключает `docs/` и служебные конфиги из GitHub source архивов.
- Rake‑таск `release:check_gem_files` гарантирует отсутствие внутренних документов и конфигов в собранном gem (используется локально и на CI релиза).
