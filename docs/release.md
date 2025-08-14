# Релизный пайплайн и чек‑лист (Pretty Git)

Версия: 0.1 (актуально для релиза v0.1.1)
Статус: Accepted

## Цели
- Единая процедура релиза гема в RubyGems и обновления Homebrew tap.
- Идемпотентность и безопасность (guard, проверка существования версии).
- Документированные секреты/переменные и smoke‑тесты.

## Предпосылки / Секреты
- GitHub Secrets:
  - `RUBYGEMS_API_KEY` — API‑ключ RubyGems (MFA-enabled аккаунт). Не логируется в CI.
  - `HOMEBREW_TAP_TOKEN` — токен c правами на push/PR в tap (или стандартный `GITHUB_TOKEN`, если достаточно прав).
- Репозиторий tap: `MikoMikocchi/homebrew-tap` (пример; обновить при изменении).
- Workflow: `.github/workflows/release.yml` (запуск по тегу `vX.Y.Z`).

## Guard и идемпотентность
- Проверка соответствия версии тега и `lib/pretty_git/version.rb` (и/или gemspec). Несоответствие → fail fast.
- Перед `gem push` — HTTP‑проверка, опубликована ли версия на RubyGems. Если да — шаг пропускается.
- PR в tap создаётся независимо от публикации (при условии доступности tarball URL версии).

## Процедура релиза (чек‑лист)
1. Обновить версию в `lib/pretty_git/version.rb` (SemVer): `X.Y.Z`.
2. Обновить `CHANGELOG.md` (секция для версии), `README*` (при необходимости), `CONTRIBUTING.md` (если изменился плейбук).
3. Локально собрать и проверить:
   ```bash
   bundle install
   bundle exec rake build
   bundle exec rake spec
   bundle exec rubocop
   ```
4. Preflight (обязательно, до тега):
   - Gemfile.lock синхронизирован: `bundle install` → `git add Gemfile.lock` → `git commit`.
   - Версии совпадают: `git describe --tags --abbrev=0` ≠ новый `X.Y.Z`, а `lib/pretty_git/version.rb` и `CHANGELOG.md` указывают на новый.
   - CI на ветке зелёный (lint/tests). Если нужно — дождаться.

5. Создать аннотированный тег и пуш:
   ```bash
   git commit -am "Release vX.Y.Z"
   git push origin main
   git tag -a vX.Y.Z -m "Pretty Git vX.Y.Z"
   git push origin vX.Y.Z
   ```
5. Дождаться GitHub Actions: `release.yml`.
   - Убедиться, что шаг guard прошёл.
   - Проверить шаг `gem push` (может быть пропущен, если версия уже опубликована — OK).
   - Проверить создание PR в Homebrew tap.

## Homebrew tap обновление
- Формула: `pretty-git.rb` в tap.
- Автоматически обновляется `url` на tarball релиза GitHub и `sha256`.
- При необходимости добавляется/обновляется `revision`.
- PR должен пройти CI tap, после чего его можно слить.

## Smoke‑тесты (после релиза)
- RubyGems установка:
  ```bash
  gem install pretty-git
  pretty-git --version
  ```
- Homebrew установка:
  ```bash
  brew tap MikoMikocchi/tap
  brew install pretty-git
  pretty-git summary --limit 1
  ```
- Мини‑проверка форматов:
  ```bash
  pretty-git authors --format json | jq . > /dev/null
  pretty-git files --format csv | head -n 5
  pretty-git heatmap --format xml | xmllint --noout -
  pretty-git languages --format md | sed -n '1,5p'
  ```

## Откат
- Если релиз на RubyGems ошибочен:
  - Опубликовать патч‑релиз `X.Y.(Z+1)`; не полагаться на удаление версии.
  - В tap — обновить формулу на новый tarball/sha256.
- Если PR в tap некорректен — закрыть/исправить и повторно запустить workflow с тем же тегом (идемпотентно).

## Точки контроля качества
- Все тесты и RuboCop зелёные в CI (workflow CI).
- Детерминированность экспорта (см. `docs/output_formats.md`, ADR DR‑007).
- CSV соответствует DR‑001, схемам и интеграционным тестам.

## Известные ограничения
- Публикация `gem` может требовать ручного подтверждения MFA (если RubyGems политика изменится). В этом случае допускается ручной `gem push` и повторный запуск workflow — он пропустит публикацию и только создаст PR в tap.
- Tap PR требует доступности tarball релиза GitHub (релиз/тег публичный).

## Улучшения (backlog)
- Автотест формулы: локальный `brew audit`/`brew install --build-from-source` в CI tap.
- Поддержка нескольких taps.
- Автогенерация release notes из `CHANGELOG.md` + сравнение diff (conventional commits).
- Доп. проверка: соответствие версии в gemspec и в `lib/pretty_git/version.rb` (двусторонняя валидация).
