# 10 — Project

## Продукт
Мобильное приложение для изучения английского. Offline-first: учебный цикл работает без сети.
Пользователь учит слова карточками с интервальным повторением и видит ежедневный прогресс.

## Слои
- presentation — экраны, виджеты, state (Riverpod). Знает про domain, не знает про Drift.
- domain — сущности, value objects, use cases, SM-2, контракты репозиториев. Не зависит от Flutter.
- data — Drift-база, реализации репозиториев, маппинг, export/import.

Правило зависимостей: presentation → domain ← data. Обратных импортов нет.

## Стек
- Flutter 3.47.9 / Dart 3.13.7, flutter_riverpod 3.x, drift 2.35, drift_flutter 0.3.
- Domain-слой — pure Dart (без импортов Flutter), но тулинг общий: flutter analyze / flutter test.
- UI: google_fonts (Inter, static), flutter_animate, smooth_page_indicator (ADR-029).
- Cloud: Supabase (ADR-022, opt-in).

## Ключевые решения
- Persistence: Drift (SQLite) — см. ADR-002 (Accepted).
- Схема БД версионируется миграциями — см. ADR-002.
- SM-2 с обязательным review log: каждая попытка пишется отдельной записью, состояние карточки выводимо из лога.
- Время в БД — только UTC. Локальное время — только на границе отображения.
- Streak считается в локальной TZ: смена дня определяется локальной полуночью, не UTC.
- Export/import — JSON с полем версии схемы; импорт неизвестной более новой версии отклоняется.
- AI hints (Phase 8, ADR-019): прокси DeepSeek, ADR-019. Локальный кэш в word_hints. Согласие — явное нажатие. Данные — только изучаемое слово.
- Sentry: готов (ADR-016, sentry_flutter 10.3), без PII, DSN только через --dart-define.

## Ограничения
- Нет сетевых вызовов в учебном цикле: урок, повторение, прогресс — офлайн.
- Нет аналитики, отправляющей содержимое учебных данных.
- Медиа (аудио) — только локальные ассеты или кэш, без стриминга в MVP.

## Открытые вопросы (текущие)
- License проекта не выбрана — BL-08.
- DSN для release: без проекта в Sentry crash reporting выключен (ADR-016).
- Откат схемы при даунгрейде приложения не проверялся.
- iOS-сборка не проверена: нужен macOS (Phase 6c).
- Напоминания проверены только сборкой; реальное срабатывание и iOS delegate — Phase 6c.
- Облако проверено тестами и сборкой: реальные Supabase RLS и magic link на устройстве не прогонялись (BL-62).

## Правила домена
- Entities/VO — @immutable, ручная equality. Assert на .isUtc → non-const конструктор (WordProgress, ReviewLog).
