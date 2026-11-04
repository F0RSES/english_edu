# Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).
Версионирование — SemVer, вводится в Phase 2 вместе с первой сборкой.
Разделы внутри версии: Added / Changed / Deprecated / Removed / Fixed / Security.

## [Unreleased]

### Added
- `.gitignore` — артефакты сборки и IDE, `pubspec.lock` намеренно не игнорируется.
- ADR-001 «Core stack» — Accepted.
- ADR-002 «Persistence: Drift vs Isar» — Accepted.
- ADR-003 «Domain layer location» — Accepted.
- `pubspec.yaml` — dev-only, без Flutter SDK.
- `analysis_options.yaml` — very_good_analysis + strict-* и кастомные правила.
- `docs/ARCHITECTURE.md` — карта контрактов домена.

### Changed
- `.clinerules/10-project.md`, `README.md` — синхронизированы с ADR-002.
- `README.md` — Status переведён в Phase 1, ссылка на ADR-001 обновлена на Accepted.
- `.clinerules/10-project.md` — возвращена строка про миграции схемы, TZ-вопрос заменён ссылкой на ADR-001.
- ADR-002 — Verification gate формализован (критерий unmaintained).
- BL-01 — критерий приёмки переписан под код контрактов.
- `very_good_analysis` и `test` — версии приняты по pub.dev, перепроверка в 1.1a.
- `docs/PROJECT_CONTEXT.md` — `lib/` и `test/` отнесены к Phase 1 (ADR-003).
- `docs/ARCHITECTURE.md` — добавлен раздел Non-goals.

### Verified
- Host: Dart 3.13.4 stable, linux_x64.
- `dart pub get` — resolved 50 dependencies (very_good_analysis 11.0.0, test 1.33.0).
- `dart analyze` — 0 issues.
- `dart format .` — 0 files changed, baseline зафиксирован.
- `pubspec.lock` создан и не игнорируется; untracked в git на момент записи.
- Note: Cline sandbox не имеет dart в PATH — тулинговые команды запускает пользователь в host shell.

### Deprecated

### Removed

### Fixed
- BL-01 ошибочно закрыт до завершения 1.1 → In progress.

### Security
