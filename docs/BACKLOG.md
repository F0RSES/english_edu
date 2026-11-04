# Backlog

Приоритет: P0 — блокирует следующий шаг, P1 — нужно к релизу, P2 — после релиза.
Статус: Todo / In progress / Review / Done.

| ID | Приоритет | Задача | Критерий приёмки | Статус |
|---|---|---|---|---|
| BL-01 | P0 | Phase 1 — Архитектура: слои, контракты domain, ADR-002 (Drift vs Isar) | ARCHITECTURE.md committed; lib/domain/ содержит контракты; dart analyze = 0; dart test test/domain/ зелёный | In progress |
| BL-02 | P0 | Phase 1 — Контент-пайплайн: схема seed, скрипт валидации, 300–500 слов с лицензиями | Seed проходит валидацию без ошибок, у каждого слова есть источник и лицензия, объём в диапазоне 300–500 | In progress |
| BL-03 | P0 | Phase 2 — Каркас + Drift schema v1 + миграции + репозитории + export/import JSON | Приложение запускается, схема v1 создаётся с нуля и мигрирует на тестовой базе, export→import возвращает идентичные данные | Todo |
| BL-04 | P0 | Phase 3 — Ядро: SM-2 + review log + due-очередь + LessonScreen + TTS + undo + session complete | Урок пишет review log, пересчитывает интервалы по SM-2 и завершается экраном итогов; undo возвращает предыдущее состояние карточки | Todo |
| BL-05 | P0 | Phase 4 — DictionaryScreen + Settings + onboarding + empty states + daily goal | Новый пользователь проходит onboarding, видит словарь и настройки, у каждого пустого экрана есть empty state, дневная цель сохраняется и отображается | Todo |
| BL-06 | P0 | Phase 5 — Streak (local TZ) + XP + локальные уведомления + accessibility | Streak считается по локальной полуночи и покрыт тестами на смену TZ, уведомление приходит в заданное локальное время, экраны проходят проверку screen reader | Todo |
| BL-07 | P0 | Phase 6 — Бета: TestFlight/Internal Testing, Sentry, CI, smoke-тесты | Сборка уходит в TestFlight и Google Internal Testing, CI гоняет analyze и test на каждый PR, Sentry работает без PII, DSN только через --dart-define | Todo |
| BL-08 | P1 | Phase 7 — Публикация: store listing, privacy policy, support email | Листинги опубликованы в обоих сторах, privacy policy доступна по публичному URL, support email отвечает | Todo |
| BL-09 | P2 | Phase 8 — AI-прокси (post-launch) | AI-функции вызываются только через прокси, ключи отсутствуют в клиенте, решение зафиксировано отдельным ADR | Todo |

## Заметки
- Задача без критерия приёмки в бэклог не попадает.
- Долг, замеченный вне scope, добавляется сюда отдельной строкой, а не правится молча.
