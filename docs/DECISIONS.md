# Decisions

Architecture Decision Records: один ADR — одно решение.
Статусы: Proposed → Accepted / Rejected / Superseded by ADR-<NNN>. Утверждает владелец продукта.

## Шаблон

### ADR-<NNN>: <Название>
- **Status:** Proposed | Accepted | Rejected | Superseded by ADR-<NNN>
- **Date:** <YYYY-MM-DD>
- **Context:** <проблема, ограничения, что уже существует>
- **Decision:** <решение одной формулировкой>
- **Alternatives considered:** <вариант — почему отклонён>
- **Consequences:** <что проще, что сложнее, какой долг берём>
- **Open questions:** <что проверить до Accepted>

---

### ADR-001: Core stack
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** Нужен минимальный стек для offline-first приложения для изучения английского: работа без сети, тестируемый domain, минимум зависимостей на старте, предсказуемая сборка. Persistence в этот ADR не входит — выбор хранилища решается отдельно в ADR-002.
- **Decision:** Ядро MVP:
  - Flutter — UI и рантайм.
  - Riverpod, riverpod_generator + riverpod_annotation — state management и DI.
  - go_router — навигация и deep links.
  - freezed + json_serializable — модели, state, сериализация.
  - build_runner — кодогенерация.
  - flutter_tts — произношение.
  - flutter_local_notifications — локальные напоминания.
  - very_good_analysis — линт.
- **Alternatives considered:**
  - Bloc вместо Riverpod — больше шаблонного кода на тот же объём состояния.
  - Ручная навигация вместо go_router — выше стоимость поддержки deep links и вложенных маршрутов.
  - Ручные модели вместо freezed — рутина и риск расхождения equals/copyWith.
  - Manual providers вместо riverpod_generator — меньше зависимостей, но больше boilerplate; оставлено fallback-путём.
- **Scope out:** i18n/l10n вне MVP. UI locale — ru, учебный контент — en. Persistence — ADR-002. Sentry (Phase 6, без PII, DSN только через --dart-define) и AI (out of scope MVP, только через прокси, отдельный ADR, post-launch) в этот ADR не входят.
- **Version policy:** caret ranges в pubspec.yaml; pubspec.lock коммитится и является источником правды по фактическим версиям. Пересмотр версий — при плановом обновлении зависимостей, не по расписанию.
- **Consequences:**
  - (a) flutter_tts и flutter_local_notifications требуют разрешений и platform-конфигурации iOS/Android в Phase 2a.
  - (b) build_runner обязателен в сборке; политика «коммитить generated-файлы (.drift/.freezed/.g/.riverpod) или генерировать в CI» — решение Phase 2a.
  - (c) riverpod_generator + riverpod_annotation — основной путь; при проблемах в Phase 2a допускается fallback на manual providers с обновлением этого ADR.
  - (d) pubspec.lock committed as source of truth for dependency versions. Host SDK: Dart 3.13.4.
- **Open questions:** зрелость пакетов пересмотреть в Phase 2a (см. ADR-002 Verification gate); выбор TZ-пакета — Phase 1.1; лицензия проекта — BL-08.

---

### ADR-002: Persistence — Drift vs Isar
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** Нужно offline-first хранилище. Требования: выборки по dueAt для очереди повторений, версионированные миграции, кодогенерация, in-memory тесты без эмулятора, удобный export/import JSON, зрелость и поддерживаемость. Версии пакетов здесь не фиксируются.
- **Decision:** Принято: Drift.
- **Options:**

| Критерий | Drift | Isar | raw sqflite |
|---|---|---|---|
| Query expressiveness (SQL для SRS) | Полный SQL: выборка по dueAt, join к review log, агрегаты одним запросом | Объектный query API; сложные выборки и агрегаты — фильтры плюс обработка в коде | Полный SQL, но типизация и маппинг целиком ручные |
| Migrations | Версионированные миграции и schema export, сценарии upgrade тестируемы | Схема и миграции ручные, гарантий меньше | Полностью ручные, риск расхождения схемы и кода |
| Codegen cost | build_runner на каждое изменение схемы, холодная сборка медленная | build_runner, объём генерируемого кода меньше | Кодогенерации нет |
| Test support (in-memory) | Нативная in-memory база: тесты без файлов и эмулятора | Нужен файловый путь, изоляция тестов сложнее | In-memory возможна, обвязка ручная |
| Export/import ergonomics | Строки читаются в типизированные объекты, сериализация предсказуема | Документный формат проще, но контроль версии схемы ручной | Полный ручной контроль при полной ручной работе |
| Maturity | Проверить на pub.dev: активность и поддержка платформ | Проверить на pub.dev отдельно | Стабилен как часть платформы, но минимум возможностей |

- **Recommendation:** Drift. Обоснование: очередь повторений — это выборка по dueAt с join к review log и агрегатами по прогрессу, что на SQL выражается прямым запросом без ручной фильтрации; in-memory тесты дают быстрые тесты репозиториев без эмулятора; версионированные миграции нужны с первой версии схемы. Цена — стоимость build_runner и генерируемый код в репозитории. Оценки зрелости предварительные и проверяются по pub.dev в Phase 2a.
- **Consequences:** build_runner обязателен в CI; generated-файлы попадают в репозиторий (финально фиксируется политикой ADR-001, п. b); схема стартует с v1 и с первого дня требует миграционного пути.
- **Verification gate:** зрелость пакетов проверяется в Phase 2a при пине версий. unmaintained = нет релиза > 12 месяцев ИЛИ репозиторий archived ИЛИ открытые критические issue без ответа > 3 месяцев. Если Drift окажется unmaintained — ADR-002 → Superseded ADR-XXX, миграция через export/import. Это не блокирует Accepted.
- **Migration path if switch later:** смена хранилища — export JSON → импорт в новый repository → удаление DAO. Стоимость ограничена объёмом данных пользователя (тысячи записей) — несколько дней. Фиксируется здесь, чтобы будущий Superseded ADR имел явную цену отката.
- **Open questions:** точные версии пакетов; политика commit vs CI-generate для generated-файлов; производительность build_runner при росте числа таблиц.

### ADR-003: Domain layer location
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** Контракты домена — это код, а не документация. Без pubspec и analysis_options контракты не компилируются, `dart analyze` неприменим, DoD «analyze clean» не проверяется. ADR-001 не фиксировал момент появления pubspec в Phase 1.
- **Decision:** Доменный слой живёт в `lib/domain/`, pure Dart, без Flutter SDK. Создаётся `pubspec.yaml` без зависимости от Flutter: только `dev_dependencies` (very_good_analysis, test), `publish_to: none`, environment `sdk: ">=3.5.0 <4.0.0"`. Runtime-зависимостей нет.
- **Alternatives considered:**
  - Держать контракты только в docs до Phase 2a — тогда компиляция и DoD «analyze clean» не проверяются, контракты расходятся с кодом.
  - Выделить domain в отдельный пакет сразу — изоляция лучше, но tooling и структура усложняются до появления второго потребителя.
- **Consequences:** pubspec появляется в Phase 1, а не в Phase 2a; в Phase 1 используются `dart analyze` и `dart test`, `flutter analyze` и `flutter test` — с Phase 2a; runtime-зависимости остаются нулевыми до 2a; домен компилируется независимо от Flutter.
- **Open questions:** проверить в 1.1a актуальные версии very_good_analysis и test и их совместимость с нижней границей `sdk: ">=3.5.0 <4.0.0"`; решить позже, остаётся ли `lib/domain/` внутри приложения или выделяется в пакет.

## Реестр

| ID | Название | Status |
|---|---|---|
| ADR-001 | Core stack | Accepted |
| ADR-002 | Persistence: Drift vs Isar | Accepted |
| ADR-003 | Domain layer location | Accepted |
