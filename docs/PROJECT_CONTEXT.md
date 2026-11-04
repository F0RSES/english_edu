# Project Context

Шаблон состояния проекта. Обновляется в конце каждой задачи. Плейсхолдеры `<...>` заполняются по факту.

## Phase
1 — Architecture

## Done
- Phase 0 — Bootstrap: 11 файлов управления проектом (`.clinerules/` + `docs/`).
- Phase 1, task 1.0 — ADR-001 и ADR-002 в статусе Accepted.
- Phase 1, task 1.1a.0 — toolchain verified on Dart 3.13.4; pubspec.lock committed.

## In progress
- BL-01 Phase 1, task 1.1 — domain contracts.

## Next
- BL-01 Phase 1, task 1.1a.1 — VO (WordId, ReviewLogId, LocalDate, ReviewGrade, CardState, StreakInfo) + тесты.

## Структура репозитория
- `.clinerules/` — правила работы в репозитории.
- `docs/` — контекст, ADR, бэклог, discovery, changelog.
- `lib/` — появляется в Phase 1 (ADR-003).
- `test/` — появляется в Phase 1 (ADR-003).

## Ключевые файлы
- `docs/PROJECT_CONTEXT.md` — состояние проекта.
- `docs/DECISIONS.md` — ADR, архитектурные решения.
- `docs/BACKLOG.md` — задачи и критерии приёмки.
- `docs/DISCOVERY.md` — интервью и гипотезы.
- `docs/CHANGELOG.md` — история изменений.

## Открытые вопросы
- TZ-пакет для расчёта streak — Phase 1.1.
- License — выбор отложен до BL-08.
- <вопрос> — <кто и когда решает>

## Известные проблемы
- Cline sandbox: нет dart/flutter в PATH. Команды тулинга (pub get, analyze, format, test) — пользователь в host shell.
- Host: Dart 3.13.4 stable, linux_x64.
- <проблема> — <обходной путь> — <ID задачи>

## Технический долг
- <долг> — <ID задачи>
