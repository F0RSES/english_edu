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
  - stts — STT/TTS; используется только TTS (flutter_tts заменён в ADR-018).
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
  - (a) stts (ранее flutter_tts) и flutter_local_notifications требуют разрешений и platform-конфигурации iOS/Android в Phase 2a.
  - (b) build_runner обязателен в сборке; политика «коммитить generated-файлы (.drift/.freezed/.g/.riverpod) или генерировать в CI» — решение Phase 2a.
  - (c) riverpod_generator + riverpod_annotation — основной путь; при проблемах в Phase 2a допускается fallback на manual providers с обновлением этого ADR.
  - (d) pubspec.lock committed as source of truth for dependency versions. Host SDK: Dart 3.13.4.
  - (e) effective minimum Dart SDK — 3.13.4 (dev_deps VGA 11 требует ^3.13.0); pubspec lower bound >=3.5.0 — официальная совместимость, фактическая — 3.13.
  - (f) Domain may depend on package:meta for @immutable; meta — annotations only, no runtime.
  - (g) Major versions зафиксированы в ADR-007.
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
- **Consequences:**
  - pubspec появляется в Phase 1, а не в Phase 2a; в Phase 1 используются `dart analyze` и `dart test`, `flutter analyze` и `flutter test` — с Phase 2a; домен компилируется независимо от Flutter.
  - runtime-зависимости: meta (annotations only, no runtime code). Иных runtime-зависимостей до Phase 2a нет.
  - LocalDate stores days since epoch; no implicit TZ conversion; fromDateTime uses Y/M/D as provided.
  - assert на DateTime.isUtc требует non-const конструктора; WordProgress и ReviewLog — non-const, runtime assert.
- **Open questions:** решить в Phase 2a: остаётся ли `lib/domain/` внутри приложения или выделяется в отдельный Dart-пакет.

### ADR-004: WordStatus source of truth
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** `Word` и `WordProgress` оба содержали `status`. При upsert двух записей это даёт два источника истины и расхождение между ними.
- **Decision:** Статус принадлежит `WordProgress`. `Word` — словарная статья: `term`, `translation`, `transcription`, `partOfSpeech`, `exampleSentence`.
- **Alternatives considered:**
  - (A) Денормализация в `Word` — отклонено: синхронизация при каждом upsert, два места для одного бага.
  - (C) Статус только в `Word` — отклонено: прогресс без статуса не имеет смысла для SRS и streak.
- **Consequences:** `WordRepository.getByStatus` удалён; добавлен `getByIds` — очередь собирается двумя запросами вместо N+1; join остаётся делом реализации Drift в Phase 2, контракт domain остаётся чистым.
- **Open questions:** индексы Drift для `getByIds` и `getDueBefore` — Phase 2.

### ADR-005: ReviewLog append-only + replaceAll for import
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** REPLACE-импорт требует атомарной замены всех записей. Для журнала ответов это противоречит append-only, который защищает историю от перезаписи.
- **Decision:** Append-only сохраняется для работы с одной записью (`append`). `replaceAll` — единственное исключение, доступное только импорту и восстановлению; dartdoc контракта прямо запрещает вызывать его из обычного кода.
- **Alternatives considered:**
  - Оставить `clear()` + цикл вставок — два вызова вместо одного, промежуточное пустое состояние, больше точек отказа.
  - Отказаться от REPLACE в пользу merge — отложено до Phase 5, требует отдельного ADR.
- **Consequences:** Четыре репозитория получают `replaceAll`; `getAll` добавлен в progress/log/stats для экспорта; экспорт больше не зависит от перечисления `WordStatus` и диапазонов дат.
  - v2: `+ frozenDays`. v1 импортируется с пустым `frozenDays` (backward compat).
  - v3: `+ Word.category` (BL-57). Снимки v1/v2 читаются с `category = null`.
  - v4: `+ Word.level` (BL-67, ADR-023). Снимки v1/v2/v3 читаются с `level = A1`: формат уровня в них не было, а A1 — безопасный дефолт словаря. `ExportPayload.currentSchemaVersion = 4`.
- **Open questions:** межрепозиторная атомарность (транзакция на все пять шагов) — Phase 2.

### ADR-006: Flutter bootstrap
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** Phase 2a — каркас приложения. До этого проект был pure Dart с готовым доменным слоем и 173 тестами.
- **Decision:** Flutter-проект создаётся в корне репозитория (`flutter create .`); `lib/domain/` не меняется; Flutter-зависимости добавляются в `pubspec.yaml`; тулинг переходит на `flutter analyze` / `flutter test`. Вместо `sqlite3_flutter_libs` используется `drift_flutter` (ADR-007).
- **Alternatives considered:**
  - Отдельный подкаталог `app/` — усложняет пути к домену и дублирует pubspec.
  - Оставить `dart test` для домена и `flutter test` для виджетов — два прогона и два набора правил вместо одного.
- **Consequences:** `dart test` заменён на `flutter test` (домен-тесты идут через Flutter-раннер); созданы `android/` и `ios/`; `environment.sdk = ">=3.13.0 <4.0.0"`, минимальный Dart 3.13.7; анализатор Flutter строже — четыре линта отключены (см. ADR-007).
- **Open questions:** CI matrix (Phase 6), сборка APK/IPA (Phase 6).

---

### ADR-007: Package versions at Phase 2a
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** Проверка pub.dev на 2026-11-04 показала мажоры выше спеки: `flutter_riverpod` 3.4.3 (спека: 2.6), `go_router` 18.1.3 (14), `flutter_local_notifications` 22.3.3 (18), `flutter_lints` 6.0.0 (5). Пакет `sqlite3_flutter_libs` отдаёт `0.6.0+eol` с описанием «Not used anymore, update to version 3.x of package:sqlite3 instead».
- **Decision:** `flutter_riverpod ^3.4.3`, `drift ^2.35.3`, `drift_flutter ^0.3.1` (вместо `sqlite3_flutter_libs`), `go_router ^18.1.3`, `flutter_local_notifications ^22.3.3`, `flutter_tts ^4.2.5`, `meta ^1.19.0`, `path ^1.9.1`, `very_good_analysis ^11.0.0`, `build_runner ^2.16.1`, `drift_dev ^2.35.2`, `test ^1.31.1`. `flutter_lints` удалён (VGA достаточно). `environment.flutter` не указан.
- **Alternatives considered:**
  - Взять версии из спеки (`riverpod 2.6`, `go_router 14`, `fln 18`) — устаревшие мажоры без причины, кода на этих API ещё нет.
  - `sqlite3_flutter_libs ^0.5.0` — EOL-пакет.
  - `test ^1.33.0` — несовместим: требует `test_api 0.7.15`, Flutter 3.47.9 пинит `0.7.12`; у `1.31.1` ровно `0.7.12`.
  - `build_runner ^2.17.1` — требует `analyzer ^14.3.0`, что конфликтует с `test 1.31.1`; 2.16.1 совместим.
- **Consequences:** `riverpod_generator`/`riverpod_annotation` отложены до 2a.3 (BL-26); миграция Riverpod 2→3 не нужна, кода нет; анализатор Dart 3.13.7 включил четыре новых линта на уже написанном домене — они отключены в `analysis_options.yaml`, механическая уборка вынесена в BL-28.
- **Lint exceptions (временно, см. BL-28):**
  - `unnecessary_type_name_in_constructor` — стилистическое; автофикс заменяет `const Foo(...)` на `const new(...)`, то есть переводит код на новый синтаксис конструкторов Dart 3.13.
  - `prefer_initializing_formals` — **аудит 2a.0c: имена параметров НЕ ломаются.** Автофикс превращает `{required Repo stats} : _stats = stats` в `{required this._stats}`, а вызов `UseCase(stats: …)` остаётся валидным (проверено в изолированном пакете: `dart analyze` чист). 24 срабатывания в 5 файлах `lib/domain/usecases/`. Достаточно `dart fix`, ревью диффа.
  - `use_null_aware_elements` — стилистическое.
  - `unnecessary_const_in_enum_constructor` — стилистическое.
  Правила возвращаются после механической уборки (BL-28).
- **Open questions:** версия `riverpod_annotation` — 2a.3; снять ли отключённые линты после BL-28.

### ADR-008: Generated files committed
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** `build_runner` генерирует `lib/data/db/app_database.g.dart` (147K). Нужно решить, живёт ли он в репозитории или собирается на месте.
- **Decision:** Сгенерированные файлы коммитятся в репозиторий.
- **Alternatives considered:**
  - (A) Commit — принято: solo-разработка, diff сгенерированного кода ревьюится вместе с исходником, не требует одинаковой версии `build_runner` у всех и в CI.
  - (B) Генерация в CI — отклонено: сложнее отладка в VS Code (локально файла нет), CI должен фиксировать `build_runner 2.16.1` бит-в-бит.
  - (C) `.gitignore` для `*.g.dart` — отклонено: проект не соберётся без локального запуска `build_runner`.
- **Consequences:** `.g.dart` попадает в историю git; при обновлении `build_runner`/`drift_dev` возможны крупные diff'ы в сгенерированном коде; `dart fix` на сгенерированных файлах не применяется.
- **Open questions:** проверка «generated актуален» в CI — Phase 6 (BL-27).

### ADR-009: ReviewLogId generation
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** `ReviewLog.id` обязателен в домене. `RecordReview` принимает `ReviewLogId Function() nextLogId`, а при DI нужно, чтобы идентификаторы не повторялись после рестарта и не конфликтовали с уже существующими логами.
- **Decision:** В БД `review_logs.id` — обычный primary key без `autoIncrement`. При старте приложения читается `SELECT MAX(id)`, создаётся `NextReviewLogIdGenerator(max + 1)`, и провайдер отдаёт его метод `next` как `ReviewLogId Function()`.
- **Alternatives considered:**
  - (A) `autoIncrement` в БД + nullable `id` в домене — отклонено: тянет изменение контракта домена.
  - (B) id на основе timestamp — отклонено: риск коллизий при быстрых последовательных вставках.
  - (C) `max + 1` при каждой записи — отклонено: race condition и лишний запрос на каждый ответ.
- **Consequences:** после импорта логов с большими id счётчик нужно пересоздать (`max + 1`), иначе новые записи конфликтуют; рестарт приложения пересчитывает `max` автоматически. Пока пересчёт не автоматизирован — см. open questions.
- **Open questions:** при `ImportProgress` инвалидировать/пересоздавать генератор (listener на журнал) — 2a.3.

### ADR-010: Undo semantics
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** В сессии нужен откат последнего ответа. Журнал append-only, а состояние карточки после ответа уже изменено; откат требует и удаления записи, и восстановления `CardState`.
- **Decision:** Undo — компенсирующее действие: удаление последней записи журнала плюс восстановление `CardState` из её `previousCardState`. Доступно только в активной сессии, до экрана итогов. Реализация — `UndoLastReview` + `ReviewLogRepository.delete(ReviewLogId)` как явное исключение из append-only.
- **Alternatives considered:**
  - (A) Компенсирующий лог с обратным состоянием — отклонено: удваивает историю ради временного действия, усложняет выборку «последний ответ».
  - (B) Только удаление лога без восстановления прогресса — отклонено: карточка осталась бы в состоянии, которого не было.
- **Consequences:** `ReviewLogRepository` получает второй метод-исключение (`delete`); долгосрочная история остаётся нетронутой, потому что undo живёт только внутри сессии. Статистика (`DailyStats`) и XP не откатываются: задним числом XP не отзывается.
- **Open questions:** атомарность двух репозиториев (delete + upsert) — Phase 5 (BL-34).

### ADR-011: RecordReview returns outcome
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** UI показывал «+10 XP», но `RecordReview` возвращал только `CardState`. Правила XP дублировались в экране и в use case — при изменении правил они разъезжались (BL-37).
- **Decision:** `RecordReview` возвращает `ReviewOutcome` (`newCardState`, `xpGained`, `isCorrect`). Правила XP и «верно/неверно» централизованы в `XpRules`: hard → 5, good → 10, easy → 15, again → 0. `XpRules` используют и `RecordReview`, и `UndoLastReview`.
- **Alternatives considered:**
  - Оставить `CardState` и считать XP в UI — отклонено: дублирование уже привело к расхождению.
  - Возвращать `DailyStats` целиком — избыточно: экрану нужны только XP и признак верного ответа.
- **Consequences:** контракт `RecordReview` меняется (breaking для тестов и вызовов); `SessionSummary` берёт XP из накопленных `ReviewOutcome`, а не из `correct * 10`; `UndoLastReview` вычитает из `DailyStats` те же значения, что начислил `RecordReview`.
- **Open questions:** XP за streak/freeze — Phase 5.

### ADR-012: TTS and notifications architecture
- **Status:** Accepted
- **Date:** 2026-11-04
- **Context:** TTS и локальные уведомления — платформенные сервисы. `flutter_local_notifications` 22.3.3 требует `compileSdk 37`, AGP 9.1.1 и core library desugaring, а Android SDK в среде отсутствует — сборку проверить нельзя.
- **Decision:** Сейчас подключается только TTS: `TtsService` (интерфейс) + `SttsTtsService` (обёртка над `stts`, до ADR-018 — `FlutterTtsService` над `flutter_tts`), в манифест добавлен `<queries>` с `android.intent.action.TTS_SERVICE`. Уведомления отложены до Phase 5 (BL-38).
- **Alternatives considered:**
  - Подключить notifications сейчас на 22.3.3 — отклонено: `compileSdk 37` + AGP 9.1.1 + desugaring невозможно проверить без Android SDK, правки ушли бы «вслепую».
  - Взять старую версию плагина под текущий toolchain — отклонено: откат на устаревший мажор ради непроверяемой функции.
  - Не добавлять `<queries>` — отклонено: без него TTS не работает на Android 11+.
- **Consequences:** TTS изолирован в одном файле и тестируется через `FakeTtsService`; `ProfileScreen` содержит настройки TTS, блок напоминаний отключён с подсказкой «Появится в Phase 5». Notifications потребуют отдельного шага с подъёмом `compileSdk`/AGP и настройкой iOS (`AppDelegate`, `Podfile`).
- **Open questions:** проверка TTS на реальном устройстве (Phase 6); подъём `compileSdk 37` и AGP 9.1.1 (Phase 5).

### ADR-013: Reset progress semantics
- **Status:** Accepted
- **Date:** 2026-11-05
- **Context:** Нужна danger-zone «начать заново». Возможные сценарии: (A) сбросить прогресс, оставив словарь; (B) удалить всё и пересеять; (C) удалить только добавленные вручную слова. Словарь — самый ценный ресурс пользователя: его потеря означает повторный seed (или ручной ввод, если seed недоступен). MVP не имеет ни file-picker, ни сетевой синхронизации, поэтому необратимое удаление словаря нельзя предложить.
- **Decision:** MVP реализует (A). Удаляются `WordProgress`, `ReviewLog`, `DailyStats`; `Word` и `UserSettings` сохраняются. Исполнение — `ResetProgress` (порядок: прогресс → логи → статистика, чтобы не оставить логи на удалённые карточки), UI — подтверждающий диалог в `ProfileScreen`. (B) и (C) — Phase 5+.
- **Consequences:** После сброса серия = 0, дневная цель = 0 из суммы лимитов, все слова снова «новое», `dueAt = CardState.initial`. `ProfileScreen` инвалидирует `computeStreakProvider`, `getTodayQueueProvider`, `dailyGoalProvider`, `dictionaryEntriesProvider` — иначе экраны показали бы старые числа. Отмена сброса невозможна: бэкап надо делать через экспорт (**ADR-014**) заранее.
- **Open questions:** (B) «удалить всё и пересеять» — Phase 5; (C) «только пользовательские слова» — Phase 5, требует признака источника у `Word`.

### ADR-014: Export/Import MVP via clipboard
- **Status:** Accepted
- **Date:** 2026-11-05
- **Context:** Экспорт/импорт JSON уже реализован в домене (`ExportProgress`/`ImportProgress`, ADR-005), но у него нет UI. Файловый сценарий требует `file_selector` и `share_plus` — двух пакетов, разрешений платформ и iOS entitlements, а также проверки на устройстве, которой в среде нет. Снимок словаря на сотни слов — это единицы-десятки килобайт JSON, что помещается в буфер обмена.
- **Decision:** MVP работает через clipboard, без внешних пакетов: экспорт копирует JSON схемы v1 в буфер (`Clipboard.setData`), импорт принимает вставленный текст в многострочном поле, проверяет JSON и версию схемы, запрашивает подтверждение и вызывает `ImportProgress` (REPLACE). Сериализация — `ExportPayloadCodec` в data-слое, экраны получают его через `payloadCodecProvider`, чтобы presentation не импортировал data.
- **Consequences:** Ноль новых зависимостей и разрешений. Импорт необратимо заменяет состояние — отсюда обязательный диалог подтверждения; ошибки разбора показываются внутри диалога, а не в `SnackBar`, который перекрыт модальным окном. Пользователь должен сам позаботиться о сохранении текста (мессенджер, заметки).
- **Open questions:** файловый экспорт/импорт через `file_selector` + `share_plus` — Phase 5 (**BL-44**); слияние вместо замены — Phase 5.

### ADR-015: Streak freeze semantics
- **Status:** Accepted
- **Date:** 2026-11-05
- **Context:** Пропущенный день обрывает серию, хотя пользователь мог заболеть или не иметь доступа к телефону. Жёсткий сброс наказывает за разовую осечку и обесценивает длинную серию. Нужен механизм «заморозки», но он требует хранения состояния: `StreakInfo` — чистая производная от `DailyStats` и ничего не помнит.
- **Decision:**
  - Хранилище — таблица `frozen_days` (`dateEpochDays` PK, `consumedAtUtc`, `reason`); схема `schemaVersion 1 → 2`, миграция только добавляет таблицу (`onUpgrade`, без пересоздания v1).
  - `StreakInfo` расширяется: `+int frozenAvailable`, `+Set<LocalDate> frozenDates`; оба поля участвуют в `==`/`hashCode`.
  - Freeze начисляется за вехи: 1 за серию 7 дней, ещё 1 за 30 (максимум 2 доступных) — `StreakRule.frozenEarnedFor` + `StreakRule.maxAvailable`.
  - `ComputeStreak` при пропуске проверяет `frozenDates`: если день заморожен, серия продолжается и день входит в счёт; `frozenAvailable = clamp(earned(count) - frozen.length, 0, 2)`.
  - Расход заморозки — `MarkMissedDay`, вызывается из `bootstrapApp` для вчерашнего дня; условие — серия на конец дня перед пропуском уже заработала заморозку, и она не потрачена.
  - UI: `StreakCard` показывает остаток (`frozenAvailable`) и бейдж «Freeze использован», если заморозка израсходована за последние 7 дней.
- **Alternatives considered:** JSON-набор дат в `UserSettings` — отклонено: пришлось бы расширять формат экспорта ради одного поля, а `UserSettings` стал бы частично учебным состоянием.
- **Consequences:** Миграция схемы v1→v2 покрыта тестом (данные v1 переживают `onUpgrade`). Заморозки **не входят** в export/import формата v1 и не очищаются `ResetProgress` — BL-51. Полная логика непрерывности и защита от ручного добавления заморозок — BL-50.
- **Open questions:** сколько дней подряд можно морозить; попадут ли заморозки в формат экспорта v2; откат миграции при даунгрейде приложения.

### ADR-016: Sentry crash reporting
- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** Без crash reporting бета слепая: сбои видны только если пользователь сам пришлёт лог. Учебный цикл offline-first, поэтому сеть допустима только для телеметрии сбоев и не должна попадать в критический путь.
- **Decision:**
  - `sentry_flutter ^10.3.0` — единственный внешний сервис сбоев.
  - DSN только через `--dart-define=SENTRY_DSN=...`; в коде, pubspec, ассетах и git его быть не может.
  - Пустой DSN → `NoOpCrashReporter`: приложение работает, сбои уходят в `Logger`.
  - `sampleRate`: 1.0 в debug, 0.2 в release.
  - `tracesSampleRate: 0` — performance-трейсы в MVP выключены (BL-47).
  - `sendDefaultPii: false`, `attachStacktrace: true`.
  - iOS: `sentry_flutter` 10.x удалил CocoaPods и требует SPM; Flutter 3.47 включает SPM по умолчанию. `Podfile` не создаём.
  - Android: `minSdk 26` (требование `sentry_flutter` 10.x), `compileSdk`/`targetSdk`/`ndkVersion` не меняются.
- **Alternatives considered:**
  - `sentry_flutter` 9.x с CocoaPods — отклонено: устаревшая ветка, SPM уже default в Flutter 3.47.
  - Firebase Crashlytics — отклонено: зависимость от Google-сервисов, хуже для privacy.
  - Rollbar/Bugsnag — отклонено: меньше опыта в Flutter-экосистеме.
- **Consequences:**
  - Release-сборка требует `--dart-define` с DSN, иначе crash reporting молча выключен.
  - `minSdk` поднят 24 → 26 (Android 8.0): устройства на Android 7 больше не поддерживаются.
  - Тесты не поднимают нативный SDK: `bootstrapApp` принимает `sentryInit`, тесты передают no-op.
  - `presentation` зависит от `CrashReporter`, а не от Sentry: смена провайдера сбоев не затрагивает экраны.
- **Open questions:**
  - IP-адрес: `sendDefaultPii: false` не отключает сбор IP на стороне Sentry — это настройка проекта (Project Settings → Security & Privacy). Инструкция в README.
  - Performance traces — BL-47 (нужен ADR и спайк на устройстве).
  - Совместимость `jni`/`ndkVersion 28.2.13676358` с `sentry_flutter` 10.3 — BL-48, проверяется на первой APK-сборке.

### ADR-017: Local notifications
- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** Напоминания критичны для retention. Существующий Android-таргет: `compileSdk 36`, AGP 9.1.0, `minSdk 26`, Gradle 9.3.1, JDK 25 — всё это уже удовлетворяет `flutter_local_notifications` 22.3.3 (требуется `compileSdk 35+`, AGP 8.11.1+, десугаринг и `multiDex`).
- **Decision:**
  - `flutter_local_notifications ^22.3.3`, `timezone ^0.11.2`, `flutter_timezone ^5.1.1`.
  - `compileSdk = 36` литералом (не `flutter.compileSdkVersion`), AGP 9.1.0 без изменений.
  - Desugaring: `isCoreLibraryDesugaringEnabled = true` + `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.
  - `multiDexEnabled = true`.
  - `AndroidScheduleMode.inexactAllowWhileIdle`; `SCHEDULE_EXACT_ALARM` **не** запрашивается.
  - Manifest: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationReceiver` и `ScheduledNotificationBootReceiver` (`exported="false"`, 4 action из README пакета).
  - Провайдер `notificationServiceProvider` (override в `main`); `NotificationService` — `requestPermission`, `scheduleDailyReminder`, `cancelAll`.
  - Разрешение запрашивается при первом включении напоминаний в `ProfileScreen`, а не на старте.
- **Alternatives considered:**
  - `exact` + `SCHEDULE_EXACT_ALARM` — отклонено для MVP: Android 14+ не выдаёт разрешение автоматически, Play ограничивает его использование. BL-53 на будущее.
  - `workmanager` с ручной логикой — отклонено: избыточно для одного ежедневного напоминания.
  - `firebase_messaging` — отклонено: это push, а не локальные уведомления; сеть в offline-first MVP не нужна.
- **Consequences:**
  - Срабатывание «плавает» на ±5–15 минут (inexact alarm).
  - `compileSdk` зафиксирован литералом: смена дефолта во Flutter не меняет таргет молча.
  - iOS delegate (`AppDelegate`) не настроен — Phase 6c (нужен macOS).
  - В тестах плагин не поднимается: `bootstrapApp` принимает `notificationServiceBuilder`, `ProfileScreen` берёт сервис из DI.
  - TTS: `stts 1.3.4`, без Kotlin Gradle Plugin — предупреждение сборки, которое давал `flutter_tts`, устранено (ADR-018).
- **Open questions:** реальное срабатывание на устройстве (Phase 6c); точные будильники (BL-53); iOS delegate.

### ADR-018: TTS migration to stts
- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** `flutter_tts 4.2.5` применяет Kotlin Gradle Plugin. Сборка Flutter 3.47.9 предупреждает, что будущие версии Flutter перестанут собирать такие плагины («plugins that apply KGP»), то есть зависимость — отложенная поломка сборки. `stts 1.3.4` даёт TTS (и STT) без применения KGP, поддерживает текущий Flutter (>=3.44.0) и требует `minSdk 21`.
- **Decision:** Заменить `flutter_tts` на `stts ^1.3.4`; `FlutterTtsService` → `SttsTtsService`; `ttsProvider` → `SttsTtsService(Tts())`. Интерфейс `TtsService` (`speak`, `stop`) не меняется. Скорость пересчитывается ×2 из шкалы приложения `0.1..1.0` в rate платформы `0.1..10.0`.
- **Alternatives considered:**
  - Оставить `flutter_tts` и ждать версию с Built-in Kotlin — отклонено: поломка наступит при обновлении Flutter, а обновление неизбежно.
  - `flutter_tts` со своим форком — отклонено: поддержка форка на нашей стороне не оправдана.
- **Consequences:**
  - Размер APK немного больше: `stts` содержит и STT-код, который мы не используем.
  - `setVoice` не перенесён: выбор голоса остаётся через `setLanguage` (BCP-47), конкретный голос — Phase 8.
  - AGP не пришлось поднимать: несмотря на `classpath 9.2.1` в модуле `stts`, сборка на AGP 9.1.0 и Gradle 9.3.1 прошла. Предупреждение KGP исчезло.
- **Open questions:** выбор конкретного голоса (Phase 8); проверка звука на реальном устройстве (Phase 6c).

### ADR-019: AI associations via proxy
- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** Пользователю нужна мнемоническая ассоциация к слову. Прямой вызов провайдера модели из приложения означал бы ключ в APK (запрещено), поэтому развёрнут прокси `https://english-edu-ai.forses17.workers.dev/`. Учебный цикл остаётся offline-first: без сети урок, повторение и прогресс работают как раньше.
- **Decision:**
  - `AiClient` (`lib/data/ai/ai_client.dart`) поверх `http.Client`: `POST` JSON `{"word": ...}` на прокси, таймаут 10 с, ответ `{"association": ...}`.
  - Ошибки — типизированный `AiException` (статус, невалидный JSON, пустая ассоциация); таймаут — `TimeoutException`. UI показывает SnackBar, карточка остаётся рабочей.
  - Запрос только по явному нажатию «Подсказка» и только после раскрытия карточки: до ответа подсказка выдавала бы перевод.
  - Ключ провайдера живёт только на прокси; в клиенте, `.env`, ассетах и git его нет.
  - `aiClientProvider` создаётся в DI, тесты подменяют его `MockClient`.
- **Alternatives considered:**
  - Прямой вызов DeepSeek из приложения — отклонено: ключ попадал бы в артефакт, и его нельзя отозвать без релиза.
  - Локальная модель в MVP — отклонено: размер, батарея, качество.
  - Без AI вовсе — отклонено владельцем: подсказка нужна в бете.
- **Consequences:**
  - Нажатие «Подсказка» отправляет **одно слово** на прокси — это учебные данные, но действие явное и точечное. Ни прогресс, ни ответы, ни статистика не уходят.
  - Без сети подсказка недоступна (SnackBar), остальное приложение работает.
  - Прокси — внешняя зависимость: его падение не ломает урок, но и подсказок не будет.
  - Локальный кэш в `word_hints` (schema v4): повторное нажатие не ходит в сеть. Инвалидация по `term` — при редактировании слова кэш перезапрашивается. Ошибки AI не кэшируются.
- **Open questions:** TTL для кэша (сейчас запись вечная) — BL-58; rate limiting на прокси; что показывать при 429; отправка контекста (перевод/пример) для более точной ассоциации.

### ADR-020: Error Hunter contract
- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** Прокси `error_hunter` обновлён (systemPrompt + fallback на воркере) и теперь всегда возвращает `correctWord`. Проверено запросами к живому эндпоинту: `{"sentence":"She have sent the invoice…","wrongWord":"have","correctWord":"has","options":["have","has","had"]}` — поле есть во всех трёх пробах (`book`, `invoice`, `server`). До этого клиент выводил ответ как первый вариант ≠ `wrongWord`, то есть порядок `options` фактически был контрактом.
- **Decision:** `correctWord` — обязательное поле ответа. Порядок `options` контрактом **не** является: правильный вариант определяется только по `correctWord`.
- **Alternatives considered:**
  - Оставить вывод по порядку `options` — отклонено: любое перемешивание вариантов на сервере ломало бы проверку ответа.
  - Хардкодить правильный ответ в приложении — невозможно: задание генерируется на лету.
- **Consequences:**
  - BL-59 закрыт: клиент читает `correctWord` напрямую (`ErrorHunterTask.fromJson`).
  - Клиентский fallback («первый вариант ≠ `wrongWord`») остаётся как защита от старых версий прокси, но при новом контракте не используется.
  - Прокси валидирует `wrongWord` и `correctWord` до одного слова (`split(' ')[0]` + системный промпт): клиент ожидает ровно одно слово, потому что сравнивает его с отдельными словами предложения. **BL-60 закрыт** (правка на воркере, клиент не менялся).
- **Open questions:** нормализовать ли `wrongWord` на воркере (всегда одно слово) или научить клиент искать фразу в предложении — BL-60.

### ADR-021: Analytics — read-only dashboard
- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** Пользователю нужен обзор прогресса: сколько слов выучено, как шли последние дни, что даётся тяжело и когда ждать полного mastery. Все данные уже есть в `words`, `word_progresses` и `daily_stats` — писать нечего, нужен только срез.
- **Decision:**
  - `GetAnalytics` (domain) собирает `Analytics`: счётчики по статусам, топ-5 слов по `lapses`, статистику за 7 дней и прогноз даты mastery. Только чтение, ничего не сохраняет.
  - Слова без записи в `WordProgress` считаются новыми — та же семантика, что в `GetTodayQueue`.
  - Прогноз — `LocalDate?`: скорость = `mastered / дни с первого показа`; при `mastered == 0` или отсутствии остатка прогноз не строится (null), а не выдаётся из нуля.
  - `analyticsProvider` — `FutureProvider`, данные приходят в `AnalyticsSection` на `ProfileScreen`.
- **Alternatives considered:**
  - Считать в виджете — отклонено: правила запрещают доменную логику в presentation, и это ломало бы тестируемость.
  - Хранить агрегаты в БД — отклонено: избыточно, источники уже есть, а кэш пришлось бы инвалидировать на каждом ответе.
  - Линейная регрессия по дням — отклонено для MVP: истории mastery по дням нет, оценка была бы необоснованной.
- **Consequences:**
  - Три чтения БД (`getAll` слов, `getAll` прогресса, `getRange` за 7 дней) на открытие секции; при росте словаря — BL-55 (SQL-агрегация).
  - Прогноз — эвристика: при нерегулярных занятиях дата сдвигается, и это честно показывается как оценка.
  - Окно графика — ровно 7 дней, включая сегодня (пустые дни дают минимальный столбец).
- **Open questions:** нужен ли фильтр по периоду (30 дней); показывать ли XP; агрегировать ли в SQL при росте словаря.

### ADR-022: Cloud sync via Supabase (optional, manual)
- **Status:** Accepted
- **Date:** 2026-11-06
- **Context:** Прогресс живёт только в локальной Drift-базе: смена устройства или потеря телефона означает потерю всей истории повторений. Нужен бэкап и перенос между устройствами, при этом учебный цикл обязан оставаться офлайновым.
- **Decision:**
  - Источник истины — локальная БД. Облако (Supabase) хранит копию `WordProgress` в таблице `user_progress` с составным ключом `(user_id, word_id)`.
  - Контракты в domain: `CloudSyncService` (`push`/`pull`/`sync`) и `CloudAuthService`; Supabase-реализации — в `lib/data/sync/`. Presentation не импортирует Supabase.
  - Транспорт отделён интерфейсом `RemoteProgressStore`: слияние тестируется без сети и без SDK.
  - Конфликты разрешаются по `updated_at_utc` (для записи это `lastReviewedAt ?? firstSeenAt`): побеждает более поздняя строка, равные метки не перезаписываются, чтобы повторный `pull` не писал в БД без причины.
  - Время в облаке — UTC-миллисекунды epoch (`bigint`), как и в остальной системе: строки не зависят от часового пояса устройства.
  - Синхронизация ручная (кнопка в профиле). Фонового обмена нет: офлайн-цикл не должен зависеть от сети, а фоновая синхронизация потребовала бы планировщика и разрешений.
  - Конфигурация только через `--dart-define=SUPABASE_URL` и `--dart-define=SUPABASE_ANON_KEY`. Пустые значения → `isCloudConfigured == false`, провайдеры отдают заглушки (`UnavailableCloudAuthService`, `UnavailableCloudSyncService`), профиль показывает «недоступна».
  - Вход — magic link (`signInWithOtp`), возврат по схеме `io.supabase.englishedu://login-callback/`, объявленной в `AndroidManifest.xml`; SDK перехватывает ссылку сам.
  - RLS: пользователь читает и пишет только строки со своим `auth.uid()`; `user_id` подставляет клиент из текущей сессии, без сессии операция падает `CloudSyncException`.
- **Alternatives considered:**
  - Firebase — отклонено: Firestore потребовал бы другой модели данных и не дал бы SQL/RLS-контроля над прогрессом.
  - Собственный бэкенд — отклонено: вне scope MVP, требует хостинга и своей аутентификации.
  - Автоматическая фоновая синхронизация — отклонено на этом этапе: планировщик, разрешения и разрешение конфликтов в фоне дают больше рисков, чем пользы, пока синхронизация ручная и предсказуемая.
  - Last-write-wins по времени устройства — отклонено: часы устройств не синхронизированы, поэтому метка берётся из доменного события ответа, а не из `now()` в момент отправки.
- **Consequences:**
  - Прогресс переносится между устройствами, но не автоматически: пользователь нажимает кнопку и видит счётчики «отправлено / получено».
  - Удаление прогресса локально (сброс) не удаляет строки в облаке: следующий `pull` вернёт их. Это осознанно — облако работает как бэкап; полноценное удаление — отдельная задача.
  - `user_progress` не хранит `Word`-контент: слова приходят из seed и `words`; при расхождении словарей строка прогресса для отсутствующего слова остаётся невидимой, но не теряется.
  - anon key передаётся флагом сборки: он публичный по дизайну Supabase, но привязан к проекту и в репозиторий не попадает.
  - Синхронизируются только `WordProgress`; `review_logs`, `daily_stats`, настройки и заморозки — нет (см. Open questions).
- **Open questions:** синхронизировать ли `review_logs` и `frozen_days` (сейчас состояние выводимо из прогресса лишь частично); нужен ли инкрементальный `pull` по `updated_at_utc > since`; как показывать удаление прогресса в облаке; нужна ли автопроверка конфликта версий схемы облака.

### ADR-023: CEFR level (A0–C2) for words and for the user
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Словарь рос без градации сложности: новичок получал в уроке `ubiquitous` наравне с `cat`, а грубые метки вида «beginner/intermediate» не дают ни фильтра, ни осмысленного подбора. Нужна шкала, которую знают пользователи и в которую можно раскладывать контент.
- **Decision:**
  - `CefrLevel` (domain, `lib/domain/value_objects/cefr_level.dart`) — enum `a0…c2` с `label` (`A0`…`C2`) и `description`; порядок значений задаёт шкалу, поэтому сравнение идёт через `index`. `A0` — Pre-A1, которого нет в оригинальном CEFR, но он нужен для слов до первого уровня.
  - `Word.level` (default `a1`) и `UserSettings.preferredLevel` (default `a1`). Оба non-nullable: «нет уровня» и «A1» вели бы себя одинаково, а nullable-поле пришлось бы обрабатывать в каждом фильтре.
  - `newWords` в `GetTodayQueue` фильтруются по `word.level.index <= settings.preferredLevel.index`. Причина: слово выше уровня пользователь разберёт грамматически неверно и только закрепит ошибку.
  - `dueWords` не фильтруются: если пользователь уже начал учить слово (добавил вручную или уровень понизили), расписание SM-2 важнее фильтра — иначе прогресс по нему замирает навсегда.
  - Словарь даёт фильтр по уровню как отдельный UI-фильтр, который складывается по AND с категорией и вкладкой. Фильтр словаря не влияет на очередь: это инструмент просмотра, а не настройка обучения.
  - В БД уровень хранится меткой в нижнем регистре (`a0`…`c2`), а не индексом enum: индексы привязаны к порядку в коде, а метка — к смыслу. DDL-дефолт `'a1'` совпадает с регистром записываемых значений; чтение (`CefrLevel.fromLabel`) регистр не учитывает.
  - Seed без поля `level` даёт `A1`: контент не переписывается в этой задаче (Phase 13b).
- **Alternatives considered:**
  - «beginner / intermediate / advanced» — отклонено: три ступени не дают ни фильтра, ни предсказуемого порядка, и расходятся с тем, как уровни называют в учебниках и на экзаменах.
  - Индекс enum в БД — отклонено: перестановка значений в коде сделала бы старые строки неоднозначными.
  - Фильтр очереди по уровню и для `dueWords` — отклонено: пользователь теряет доступ к уже начатым словам.
  - Автоматическое определение уровня по ответам (адаптивный тест) — отклонено для MVP: нет калиброванных данных, а ложное определение молча спрятало бы половину словаря.
- **Consequences:**
  - Миграция **v5 → v6**: `words.level` и `user_settings.preferred_level` с `DEFAULT 'a1'`; старые строки получают A1 без потери данных (тест `migration v5 to v6 adds level and preferred_level columns`).
  - Онбординг вырос до четырёх страниц: выбор уровня спрашивается до первого урока, иначе очередь на первом запуске фильтруется по A1 по умолчанию.
  - Смена уровня в профиле инвалидирует `getTodayQueueProvider` и `dailyGoalProvider`: иначе до перезапуска показывался бы план по старому уровню.
  - Уровень перенесён в export: `Word.level` — схема снимка v4 (ADR-005, **BL-67** Done), `UserSettings.preferredLevel` — v5 (**BL-68** Done). Снимки v1–v4 читаются с `preferredLevel = A1`.
  - Слова без метки в seed — все A1: пока контент не размечен, фильтр по B1+ в словаре даёт пусто (BL-65).
- **Open questions:** насыщение словаря по уровням — Phase 13b (BL-65); нужен ли отдельный «сложный режим» (слова выше уровня по явному запросу); учитывать ли уровень в `AddWordDialog`.

### ADR-024: Duplicate prevention
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Пользователь может добавить `apple` и `Apple` — это две карточки на одно слово, каждая со своим прогрессом SM-2. Тот же эффект даёт импорт снимка, собранного до слияния словаря или правленного руками. Дубликаты ломают очередь дня (одно слово показывается дважды) и статистику (mastery считается по карточкам, а не по словам).
- **Decision:**
  - `WordRepository.findByTerm` — точный поиск по нормализованному `term` (`trim().toLowerCase()`), сравнение в SQL по индексированной колонке. Подстроки не совпадают: `apple` не блокирует добавление `apple pie`.
  - `AddWordDialog` перед вставкой проверяет `findByTerm` и при совпадении показывает диалог «Слово уже есть: «apple» — яблоко. Перейти к нему?» с кнопками «Отмена» / «Перейти». Дубликат не сохраняется ни при каком ответе: «Перейти» закрывает форму и возвращает `AddWordOutcome.duplicate`, «Отмена» оставляет форму открытой для правки.
  - `DictionaryScreen` различает исходы: `added` — инвалидация списка и SnackBar «Добавлено», `duplicate` — SnackBar «Слово уже есть в словаре».
  - `ExportPayloadCodec.decode` дедуплицирует слова по `term.trim().toLowerCase()`, оставляя первое вхождение. Прогресс отброшенных слов тоже удаляется — иначе внешний ключ `word_progresses → words` не даст импорт; журнал ответов остаётся (он append-only и без FK, ADR-005). Отчёт уходит в лог: `import: skipped N duplicates, M progress rows`.
  - Нормализация одна на всех: `trim` + нижний регистр. Хранение `term` уже нормализовано (seed и `AddWordDialog`), поэтому поиск и сравнение совпадают.
- **Alternatives considered:**
  - UNIQUE-индекс по `term` в БД — отклонено на этом этапе: миграция v6 → v7 и падение вставки вместо диалога; пользователю нужно объяснение, а не исключение. Кандидат на Phase 14 вместе с гомонимами.
  - Поиск через `search` + сравнение в Dart — отклонено: `search` ищет подстроку по term И translation и нашёл бы лишнее; на каждый ввод читалась бы вся таблица.
  - Молча пропускать дубликат при добавлении — отклонено: пользователь не понимает, почему слово не появилось.
  - Слияние прогресса дубликатов при импорте (максимум из двух) — отклонено: два прогресса на один `wordId` дают конфликт первичного ключа, а правило «какой из них главнее» пришлось бы угадывать.
- **Consequences:**
  - Одно слово — одна карточка: повторный ввод в любом регистре и с пробелами по краям даёт диалог, а не вторую строку.
  - Гомонимы (`apple` — яблоко, `Apple` — компания) теперь невозможно завести двумя словами: нужен `Word.senses`, это BL-69.
  - Импорт старого снимка с дублями проходит, но теряет прогресс отброшенных записей. Предупреждение в логе — единственный след; UI об этом не сообщает.
  - Проверка перед вставкой не атомарна: два параллельных добавления одного слова теоретически могут пройти оба. Практически ввод идёт через модальный диалог, но надёжная гарантия — UNIQUE-индекс (BL-69/Phase 14).
- **Open questions:** гомонимы и senses (BL-69); UNIQUE-индекс по `term` с миграцией; сообщать ли пользователю о пропущенных прогрессах при импорте.

### ADR-025: Cloze Test architecture
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Нужна вторая мини-игра, которая проверяет не узнавание перевода, а активное воспроизведение слова в контексте. Прокси уже отдаёт задание по `{type: "cloze_test", word}`; генерация стоит денег и времени, а словарь пользователя повторяется — значит задание имеет смысл кэшировать.
- **Decision:**
  - `ClozeTask` (VO) — `sentence` с пропуском `___` и `answer`; `fromJson` живёт в domain рядом с VO (как у `ErrorHunterTask`), `dart:convert` туда не протекает.
  - Контракт `ClozeGenerator` в domain, реализация — `AiClient.generateCloze` (data): presentation не знает про HTTP, прямой доступ к провайдеру модели запрещён (ADR-019).
  - Кэш — таблица `cloze_tasks` (schema **v6 → v7**): `wordId` PK → `words.id` ON DELETE CASCADE, `sentence`, `answer`, `createdAtUtc`. Одна запись на слово, `insertOnConflictUpdate`.
  - `GetClozeTask` — кэш → генерация → кэш. Ошибка генератора **не** кэшируется: офлайн-экран показывает «не удалось», задание появится, когда появится сеть.
  - Время создания приходит из домена (`clock`), data-слой системные часы не читает — иначе тесты недетерминированы.
  - Экран `ClozeTestScreen` берёт **случайное** слово из словаря, а не из очереди дня: игра не должна тратить дневной лимит новых слов и портить расписание SM-2.
  - Сравнение ответа — `trim` + нижний регистр + удаление непечатаемых символов; верный ответ закрывает ввод и открывает «Следующее задание», неверный оставляет попытку.
  - Кэш заданий не входит в export/import: это производные данные, которые можно сгенерировать заново; сброс прогресса их не трогает.
- **Alternatives considered:**
  - Хранить только `sentence` и выводить ответ из пропуска в словаре — отклонено: прокси присылает `answer`, а угадывание формы слова (время, число) давало бы ложные проверки.
  - Генерировать задание каждый показ — отклонено: сеть в учебном цикле и оплата каждого повтора; кэш даёт мгновенный второй показ.
  - Брать слово из `TodayQueue` — отклонено: игра шла бы по тем же карточкам, что урок, и раскрывала бы ответы дня.
  - Отдельная таблица со всеми вариантами ответа — избыточно для MVP.
- **Consequences:**
  - Миграция **v6 → v7** — только `m.createTable(clozeTasks)`, существующие данные не пересоздаются (тест `migration v6 to v7 creates the cloze_tasks table`).
  - Кэш растёт на одну строку на слово; при удалении слова задание уходит каскадом.
  - Задание не инвалидируется при редактировании термина: кэш ключуется по `wordId`, а не по `term` — в отличие от подсказок (ADR-019). Для игры это приемлемо: пропуск остаётся валидным для смысла слова; при необходимости — `term` в таблицу.
  - Первый показ слова требует сети: экран честно показывает ошибку с «Повторить» вместо пустого задания.
  - Игра не влияет на `DailyStats` и XP: это развлечение, а не учебная сессия.
- **Open questions:** инвалидировать ли кэш по `term`; показывать ли подсказку-перевод после двух ошибок; добавить ли cloze-задания в очередь повторения как отдельный тип карточки.

### ADR-026: Weak words review
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** SRS показывает слово ровно тогда, когда созрело `dueAt`, и это правильно для долговременной памяти. Но проблемные карточки — те, что пользователь уже проваливал (`lapses > 0`) или чей ease-фактор просел ниже 2.0 — всплывают по расписанию слишком редко: за неделю `again` по слову успевает забыться. Нужен способ «добить» их по своей воле, не ломая расписание.
- **Decision:**
  - `GetWeakWordsQueue` (domain): фильтр `lapses > 0 || ease < 2.0`, сортировка — сначала больше провалов, при равенстве — меньше ease. `newWords` пуст: это повторение, а не изучение.
  - Порог ease — **2.0**, а не стартовые 2.5: 2.5 — норма новой карточки, поэтому «ниже 2.0» ловит просевшие, а не все подряд.
  - Прогресс без слова (слово удалили) пропускается; статус (`learning`/`mastered`) не фильтр — провал возвращает в повторение и выученное слово.
  - `LessonMode` (`normal` / `weak`) + `LessonScreen({mode})`: один экран на два сценария, различие — источник очереди и заголовок. Дублировать экран ради другого провайдера значило бы разъезжаться в поведении карточки, отката и `PopScope`.
  - В weak-режиме заголовок — «Сложные слова» вместо счётчика карточек: счётчик остаётся в обычном уроке, где он и есть основной ориентир.
  - Кнопка «Повторить сложные (N)» на главном экране появляется только при `N > 0`; при нуле — `SizedBox.shrink()`, чтобы не вести на пустой экран.
  - Провайдеры: `getWeakWordsQueueProvider` (use case), `weakWordsQueueProvider` (`FutureProvider<TodayQueue>`, читается уроком), `weakWordsCountProvider` (`FutureProvider<int>`, бейдж).
- **Deviates from the task text:** в задании сказано «после weak-сессии home providers не инвалидировать, weak не влияет на daily goal». Это неверно для текущего кода: ответ в weak-режиме идёт через тот же `RecordReview`, который поднимает `DailyStats` (XP, ответы, серия) — значит дневная цель и серия **меняются**, и оставлять их устаревшими нельзя. Инвалидация выполняется в обоих режимах, плюс сбрасывается `weakWordsQueueProvider`: после ответов ease и `lapses` изменились, и бейдж должен пересчитаться.
- **Alternatives considered:**
  - Отдельный экран под weak-режим — отклонено: копия 300 строк с риском разъехаться в откате и подтверждении выхода.
  - Менять `GetTodayQueue` флагом — отклонено: очередь дня — контракт главного экрана, режим повторения не должен его касаться.
  - Показывать кнопку всегда (с нулём) — отклонено: пустой экран после нажатия.
  - Считать weak-ответы «не настоящими» (не писать в `DailyStats`) — отклонено: это меняет SRS/статистику, что запрещено рамками задачи, и обесценивает работу пользователя.
- **Consequences:**
  - Пользователь может явно повторить проблемные слова. Это **не** замена SRS: `dueAt` по-прежнему определяет обычную очередь, weak-сессия лишь даёт дополнительный проход.
  - Weak-сессия влияет на прогресс и дневную статистику (XP, серия) — так же, как обычный урок.
  - Порог `lapses > 0` включает любое слово, проваленное хотя бы раз: после `again` карточка попадёт в «сложные» до первого уверенного ответа.
  - Бейдж считает по всей базе (`getAll` прогресса) — при росте словаря до десятков тысяч нужен SQL-фильтр (BL-55).
- **Open questions:** Smart review — алгоритм сам выбирает, что повторить (пропущенные, трудные, давно не виденные) — BL-70; нужен ли отдельный порог `lapses >= 2` для «совсем плохих».

### ADR-027: Word Scramble
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Нужна тренировка орфографии: узнавание перевода (урок) и вставка слова в предложение (cloze, ADR-025) не проверяют, помнит ли пользователь, как слово пишется. AI для этого не нужен — слова и переводы уже в локальном словаре, поэтому игра работает офлайн.
- **Decision:**
  - `ScramblePuzzle` (VO): `word`, `translation`, `scrambled` (буквы в случайном порядке), `solution` (lowercase). Порядок букв входит в равенство — это часть задания, а не деталь реализации.
  - `GenerateScramblePuzzles` (domain): случайные `count` слов словаря (по умолчанию 10), буквы перемешиваются до тех пор, пока `scrambled != solution` (до 10 попыток).
  - `Random` инжектится: тесты подставляют `Random(seed)` и получают детерминированный результат, приложение — несеяный.
  - Слова короче двух букв отбрасываются: у `a` и `i` нет нетривиальной перестановки, гарантия `scrambled != solution` для них физически недостижима.
  - Автопроверка при полном ответе: пользователь не нажимает «Проверить», сравнение идёт по `solution` после последней буквы.
  - Неверный ответ: `shakeX` поля, красные плашки, `heavyImpact`, через 800 мс ответ сбрасывается. Верный: `scaleXY`-пульс, `mediumImpact`, SnackBar, через 800 мс следующая карточка.
  - Пока идёт пауза после ответа, ввод заблокирован (`_waiting`): иначе двойной тап перескочил бы карточку.
  - После последней карточки — диалог «Сессия завершена» с итогом и выбором «Ещё раз» / «Готово».
  - Прогресс SRS игра **не** пишет: это развлечение, а не повторение (BL-71).
- **Alternatives considered:**
  - Проверка по кнопке «Проверить» — отклонено: лишний тап на каждой карточке, автопроверка по длине слова очевидна пользователю.
  - Генерация через AI (как cloze) — отклонено: усложняет и требует сети ради данных, которые уже есть локально.
  - Хранить задания в БД — отклонено: перемешивание детерминировано из слова, кэш ничего не экономит (в отличие от cloze).
  - Записывать `RecordReview` — отложено (BL-71): сейчас ответы в игре не влияют на `dueAt`, иначе игра начала бы менять расписание урока.
- **Consequences:**
  - Игра работает без сети и без ключей — единственная из трёх, полностью офлайновая.
  - Порядок слов в сессии случайный: два запуска подряд дают разные наборы (дубли между сессиями возможны).
  - Односложные слова в игру не попадают — пользователь их там и не ждёт.
  - Схема БД не меняется: новых таблиц нет, миграции нет.
- **Open questions:** записывать ли `RecordReview` после раунда (BL-71); нужен ли режим «только проблемные слова» через `GetWeakWordsQueue`; стоит ли давать подсказку-первую букву после двух ошибок.

### ADR-028: Listening Dictation + SRS integration
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Узнавание перевода и орфография уже тренируются, но слух — нет: пользователь читает слово, а не слышит его, хотя в разговоре опознать слово на слух важнее. Кроме того, мини-игры были изолированы от SRS (BL-71): ответы в них не влияли на расписание, то есть игра не помогала запоминанию.
- **Decision:**
  - `GenerateDictationQueue` (domain) — до 10 случайных слов словаря; `Random` инжектится, тесты детерминированы.
  - TTS читает слово; голос и скорость берутся из `UserSettings`, сервис — через `ttsProvider` (ADR-012/018), а не напрямую из плагина.
  - Диктант пишет прогресс в SRS: верный ответ — `ReviewGrade.good`, ошибка — `ReviewGrade.again`, через тот же `RecordReview`, что и урок.
  - `Word Scramble` тоже пишет SRS (BL-71 закрыт): `good` за верный ответ, `again` — только когда слово не собралось с трёх попыток. Одна опечатка не должна портить расписание.
  - **Запись не больше одного раза на слово за сессию** (`Set<WordId> _recorded`): в диктанте Enter можно нажать несколько раз, в scramble слово можно пересобрать — повторная запись перезаписала бы прогресс «угадыванием».
  - После записи инвалидируются кэши главного экрана (серия, очередь, дневная цель, бейдж слабых слов) — ответ меняет статистику так же, как в уроке.
  - Правильный ответ в диктанте показывается только после ошибки: иначе это была бы не проверка слуха, а чтение.
- **Alternatives considered:**
  - Не писать SRS из игр — отклонено (это и был BL-71): игра без влияния на прогресс не помогает запоминанию.
  - Писать `again` за любую ошибку в scramble — отклонено: перестановка букв лояльна к случайным опечаткам, `again` должен означать «слово не знаю».
  - Отдельная таблица прогресса игр — отклонено: два источника истины по одному слову разъедутся.
  - `ReviewGrade.easy` за быстрый верный ответ — отклонено для MVP: измерение времени добавило бы состояние и таймеры без доказанной пользы.
- **Consequences:**
  - Ответы в диктанте и scramble влияют на `dueAt`; SRS остаётся единственным источником прогресса.
  - Схема БД не меняется: новых таблиц нет, миграции нет.
  - Диктант требует озвучки: без TTS слово не услышать, поэтому падение плагина показывается SnackBar, а слово остаётся доступным по памяти.
  - Сбой записи в SRS не обрывает сессию: ошибка уходит в лог, ответ просто не попадает в прогресс.
  - Error Hunter по-прежнему не пишет в SRS: он про грамматику, а не про запоминание слов (BL-72).
- **Open questions:** записывать ли Error Hunter (BL-72); давать ли `easy` за верный ответ без ошибок и быстро; показывать ли пользователю, что игра пишет прогресс.

### ADR-029: UI dependencies
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** В `pubspec.yaml` появились `google_fonts`, `flutter_animate` и `smooth_page_indicator` без записи в DECISIONS.md — нарушение правила `40-forbidden.md` п.11 («новая зависимость без ADR»). Пакеты уже используются: типографика Inter, анимации карточек и индикатор страниц онбординга. Оставлять решение незафиксированным нельзя, а удалять работающий UI ради формы — дороже, чем записать решение.
- **Decision:**
  - `google_fonts` — статические TTF (Inter) в `assets/google_fonts/`, runtime fetching отключён (`GoogleFonts.config.allowRuntimeFetching = false` в `main`). Из сети шрифты не качаются: offline-first не нарушается ни на первом запуске, ни в тестах.
  - `flutter_animate` — анимации (`fadeIn`, `slideY`, `shakeX`, `scaleXY`) на интерактивных экранах и в играх.
  - `smooth_page_indicator` — индикатор страниц в онбординге.
  - Все три пакета живут только в presentation; domain и data их не импортируют.
- **Alternatives considered:**
  - Не фиксировать ADR (оставить как есть) — отклонено: прямое нарушение правила, и следующая зависимость добавилась бы так же молча.
  - Убрать пакеты и написать вручную — отклонено: анимации и индикатор уже работают; ручная реализация даст больше кода без выгоды для пользователя.
  - `flutter_animate` → `AnimationController` вручную — отклонено: тот же объём поведения дороже в поддержке.
  - Шрифт из сети (поведение `google_fonts` по умолчанию) — отклонено: первый кадр без сети показывал бы системный шрифт.
- **Consequences:** три пакета в `pubspec.yaml` (версии — см. `pubspec.yaml`; источник правды по факту — `pubspec.lock`, ADR-007); presentation зависит от них, domain/data — нет; сетевой загрузки шрифтов нет, офлайн-цикл не затронут; размер ассетов растёт на файлы Inter.
- **Open questions:** альтернативы для сложных анимаций (Lottie: confetti при завершении сессии, переходы между экранами) — BL-74.

### ADR-030: Daily Challenge
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Retention — главный KPI беты: пользователь забывает про приложение через три дня, а SRS сам по себе не даёт причины открыть его сегодня. Нужна ежедневная цель, которая заметна на главном экране и награждается.
- **Decision:**
  - Отдельная таблица `daily_challenges` (**schema v7 → v8**), одна запись на локальный день (`dateEpochDays` PK). Тип хранится именем значения enum, а не индексом: порядок значений в коде может измениться.
  - Четыре типа (`DailyChallengeType`): `review20` (20 повторов, 50 XP), `streak10` (10 верных подряд, 30 XP), `new5` (5 новых слов, 40 XP), `noMistakes` (10 без ошибок, 60 XP). Цель и награда — поля самого значения, поэтому расхождение между ними невозможно.
  - Тип выбирается случайно **один раз за день** при первом обращении и дальше живёт в БД: иначе цель «переизбиралась» бы до удобной.
  - Прогресс двигается внутри `RecordReview` (`required UpdateChallengeProgress challengeProgress`), то есть на всех путях ответа — урок, слабые слова, диктант, scramble. Альтернатива «из экрана» оставила бы игры без прогресса (нарушение ADR-028).
  - Ошибка шага задания **не откатывает** ответ: `UpdateChallengeProgress` глушит её внутри (`catch` → `return`), `RecordReview` не знает о сбое. Задание — вспомогательный слой, SRS первичен.
  - Награду выдаёт use case `ClaimDailyChallenge`, а не виджет: XP пишется в `DailyStats`, а presentation не имеет права ходить в репозитории (`40-forbidden.md` п.16, `20-code-style.md` п.21). Повторное нажатие возвращает 0 и не начисляет XP дважды.
  - `noMistakes`: `hard` нейтрален (ни +1, ни сброс) — трудный ответ не считается чистым, но и не обнуляет серию.
  - Карточка `DailyChallengeCard` стоит после `DailyGoalCard` (Streak → DailyGoal → Challenge): задание необязательно, а серия и план — первичны.
- **Alternatives considered:**
  - Проверка выполнения в экране урока — отклонено: диктант и scramble шли бы через тот же `RecordReview`, но не двигали бы задание.
  - XP прямо из виджета (`DailyStats.xpGained +=`) — отклонено: прямой доступ к данным из presentation.
  - `const` конструктор `DailyChallenge` — отклонено: `completedAt`/`claimedAt` проверяются на UTC в runtime, `assert` в release вырезан (как у `WordProgress`).
  - Пять разных таблиц под каждый тип — отклонено: одна таблица с полем типа проще и не требует миграции при добавлении типа.
- **Consequences:** миграция v8 покрыта тестом (`migration v7 to v8 creates the daily_challenges table`); 671 тест. Прогресс серийных заданий может **уменьшаться** (`again` сбрасывает), поэтому индикатор на карточке ходит назад — это ожидаемое поведение типа, а не сбой. Челлендж не входит в export/import: снимок переносит прогресс слов, а задание привязано к конкретному дню устройства. Двойное начисление XP (ответ + награда) суммируется в `DailyStats.xpGained`.
- **Open questions:** серия выполненных челленджей — BL-75; кастомные типы заданий — Phase 16; показывать ли челлендж в статистике (`GetAnalytics`).

### ADR-031: Homonyms via duplicate terms
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Английский полон гомонимов: `bank` — банк и берег, `apple` — фрукт и компания. Блокировка дублей (ADR-024) не давала завести второе значение: пользователь видел «Слово уже есть» и не мог сохранить другой смысл. При этом две карточки на один термин — это ровно то, что нужно SRS: значения запоминаются независимо.
- **Decision:**
  - Разные `Word` с одинаковым нормализованным `term` и **разными** `id` — это разные senses. Ограничение «одно слово — одна карточка» снимается.
  - `WordRepository.findAllByTerm` возвращает все senses одного термина; `findByTerm` **не меняется** и остаётся проверкой seed/import.
  - `AddWordDialog` при непустом результате показывает диалог «Добавить ещё одно значение?» со списком существующих переводов и частью речи; «Добавить как новое» создаёт карточку с новым `id` (его даёт `nextId()`), «Отмена» оставляет форму открытой.
  - `partOfSpeech` выводится рядом с переводом в словаре и в диалоге: это единственное, что отличает senses визуально («яблоко (noun)» против «компания (noun)»).
  - SRS: каждая sense — отдельная карточка со своим `WordProgress`, `dueAt` и статистикой. Ошибка в одной не влияет на другую.
  - **Схема БД не меняется** (остаётся v8): ограничения UNIQUE по `term` нет, поэтому новые типы не нужны.
  - `AddWordOutcome.duplicate` удалён: исход «такое уже есть» стал недостижим, а мёртвый код запрещён DoD. Отмена выражается `null`.
- **Alternatives considered:**
  - (A) `Word.senses: List<Translation>` — отложено (BL-76): требует миграции v8→v9, переделки всех экранов и объединения senses в одной SRS-карточке; для MVP дороже, чем даёт.
  - (B) UNIQUE-индекс по `term` с падением вставки — отклонено: пользователю нужно объяснение и выбор, а не исключение.
  - Молча разрешать дубли без диалога — отклонено: пользователь не понимает, почему в словаре две одинаковые строки.
- **Consequences:** одна sense — одна карточка SRS: `apple` (фрукт) и `apple` (компания) считаются в статистике отдельно, а mastery и `lapses` у них независимы. В словаре гомонимы стоят рядом (сортировка по `term`), различаются переводом и частью речи. Импорт старого снимка с дублями по-прежнему схлопывает их (`ExportPayloadCodec.decode` дедуплицирует по term) — это осознанная асимметрия: снимок переносит словарь, а не смыслы, и `BL-76` её уберёт.
- **Open questions:** объединение senses в одной SRS-карточке и перенос senses в export/import — BL-76; нужен ли выбор смысла при показе карточки урока.

### ADR-032: Challenge Streak
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Daily Challenge (ADR-030) даёт причину открыть приложение сегодня, но не даёт причины открыть его завтра: выполнил задание — и всё. Основная серия дней (ADR-015) считает любую активность, поэтому не различает «зашёл и полистал» и «выполнил задание». Нужен второй контур мотивации, привязанный именно к выполнению задания.
- **Decision:**
  - Отдельная таблица `challenge_streaks` (**schema v8 → v9**), строка одна — `CHECK (id = 1)`, как у `user_settings`.
  - Поля: `currentStreak`, `bestStreak`, `lastCompletedDateEpochDays` (nullable), `updatedAtUtc`. Истории дней в таблице нет: она выводима из `daily_challenges`.
  - Серия обновляется при выдаче награды (`ClaimDailyChallenge`) — то есть только за **выполненное и забранное** задание, а не за открытие экрана.
  - Пропуск дня не обнуляет счётчик в ноль, а начинает новую серию с 1: один выполненный челлендж — уже результат, и «0» обесценивал бы возвращение.
  - `bestStreak` только растёт и не сбрасывается никогда.
  - Шаг идемпотентен по дню (`lastCompletedDate == today` → без изменений и без записи), поэтому его можно безопасно повторить при сбое.
  - Серия обновляется **до** записи награды: если шаг упадёт, пользователь увидит ошибку и не получит XP без отмеченного дня; повтор ничего не задвоит.
  - Бейдж `Серия: N дней · Лучший: M` встроен в карточку задания (отдельный виджет не понадобился). Ошибка чтения серии не ломает карточку — бейдж просто не рисуется.
- **Alternatives considered:**
  - (A) Три поля в `UserSettings` + `CHECK` — отклонено: `UserSettings` стал бы частично игровым состоянием, а миграция всё равно нужна.
  - (B) Считать из `DailyStats` — отклонено: разные сущности, понадобился бы диапазон дат и полный проход, а «забран ли челлендж» в статистике не отражён.
  - Считать из `daily_challenges` на лету — отклонено: нужен `getRange`, который уже есть в BL-75-критерии, но `best` всё равно пришлось бы хранить (он переживает сброс текущей серии).
  - `current = 0` при пропуске — отклонено по смыслу: обнуление обесценивает одинокое возвращение.
- **Consequences:** два независимых счётчика: основная серия (активность) и серия челленджей (выполнение). Обе видны на главном, обе не мешают друг другу. Единственный источник истины по дню — `lastCompletedDate`: редактировать серию вручную из UI нельзя. Серия не входит в export/import и не очищается `ResetProgress` — это открытый вопрос ниже.
- **Open questions:** достижения за серию 7/30/100 — BL-77; очищать ли серию челленджей при `ResetProgress`; входит ли серия в export/import (сейчас нет — как и `frozen_days` до v2).

### ADR-033: Smart Review
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Weak Words (ADR-026) просто фильтрует `lapses > 0 || ease < 2.0` и сортирует по числу провалов. Проблема шире: слово может быть лёгким, но не виденным месяц (давность — главный враг памяти), или иметь просевший ease без единого провала. Фильтр «проваливал / не проваливал» не умеет ранжировать: он либо показывает слово, либо нет.
- **Decision:**
  - `SmartReviewItem` (VO): слово + прогресс + `priorityScore` + `reason` для UI.
  - Score = `lapses * 10 + daysSinceReview + (2.5 - ease) * 20`, где `daysSinceReview` считается от `lastReviewedAt`, а если ответов не было — от `firstSeenAt`. Давность учитывается только свыше 7 дней.
  - Веса выбраны так, что один провал (10) весит больше девяти дней давности (9), а просадка ease на 0.1 даёт 2 балла. Это делает `lapses` доминирующим фактором, но не отменяет остальные.
  - `reason` — первая сработавшая причина в порядке «трудное → давность», иначе «Низкий ease»: у просевшего ease своей причины нет, и называть его «трудным» было бы неправдой.
  - Сортировка по `priorityScore` desc, `maxItems = 20` — защита от бесконечной сессии (очередь строится из всей базы, а не из дневного лимита).
  - `mastered` исключается: выученное слово не нужно поднимать вручную. Слова без прогресса тоже не входят — для них есть SRS.
  - Отдельный `LessonMode.smart` в том же `LessonScreen`: различие снова сведено к источнику очереди и заголовку (как в ADR-026).
  - Use case только читает: ничего не пишет в БД, поэтому его можно звать на каждом открытии главной.
- **Alternatives considered:**
  - (A) ML-модель по истории ответов — отклонено: оверкилл для MVP, данных для обучения почти нет, а объяснить пользователю решение было бы нечем.
  - (B) Оставить только `lapses` — уже есть в Weak Words, не решает проблему давности.
  - (C) Учитывать `grade` из review log (last grade = again → boost) — отложено (BL-78): нужен join с `review_logs`, а use case тогда перестаёт быть чисто read-only по двум таблицам.
  - Считать score в виджете — отклонено: правила должны быть тестируемы без Flutter.
- **Consequences:** пользователь видит слова, важные именно сегодня, а не всё подряд. Две похожие кнопки на главной («Повторить сложные» и «Умное повторение») — осознанная цена: первая показывает всё проблемное, вторая — топ-20 по важности. Порог 7 дней и веса — эвристика; при жалобах на качество подбора менять здесь, а не в UI.
- **Open questions:** учитывать `grade` из review log — BL-78; нужен ли фильтр по уровню CEFR (сейчас нет); показывать ли `reason` на карточке урока, а не только в очереди.

### ADR-034: Custom categories
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Категории слов были жёстко зашиты в константу `wordCategories` (Бизнес, IT, Путешествия, Быт). Пользователь не может завести свою, а фильтр словаря и диалог добавления берут список из кода — расширить его без релиза невозможно.
- **Decision:**
  - Таблица `user_categories` (**schema v9 → v10**): `id` (autoIncrement), `name` (`UNIQUE`), `color_hex` (nullable), `created_at_utc`.
  - Миграция вставляет четыре базовые категории в порядке 1..4; по этому признаку они защищены от удаления (`isBuiltIn`).
  - `Word.category` **не меняется**: остаётся `text` nullable, без FK. Старые слова и снимки export/import работают без миграции.
  - `CreateUserCategory` проверяет пустое имя (`ArgumentError`) и дубль без учёта регистра (`StateError`); `UNIQUE` в БД — последняя линия обороны, а не основной механизм.
  - `CreateCategoryDialog` — имя, палитра из восьми цветов, валидация и сообщение при дубле.
  - `AddWordDialog` берёт список из `userCategoriesProvider`; последний пункт — «+ Создать категорию…» (сентинел `__create__`, потому что `null` уже занят значением «без категории»).
  - Фильтр словаря получает имена из того же провайдера, но с fallback на базовый список, пока БД читается: фильтр не должен исчезать при открытии экрана.
  - Профиль получает пункт «Управление категориями» (создание категории).
- **Alternatives considered:**
  - FK `words.category_id` → `user_categories.id` — отклонено: требует миграции данных и ломает обратную совместимость снимков; для одной строки без неё достаточно.
  - Хранить категории в `UserSettings` как JSON — отклонено: `UserSettings` стал бы частично словарём, а поиск по имени пришлось бы писать руками.
  - Разрешить удаление базовых категорий — отклонено: слова с ними остались бы без фильтра.
- **Consequences:** пользователь создаёт свои категории, старые слова продолжают работать. Дубль по имени ловится и в use case, и `UNIQUE`-индексом. Удаление категории **не** трогает слова с ней: они станут «без категории» только по имени, а строка категории исчезнет из фильтра — поэтому UI пока предупреждает, а не удаляет.
- **Open questions:** расширенный color picker (wheel) вместо восьми кружков — BL-80; удаление категории из словаря (иконка X на чипе) не реализовано — BL-80; нужен ли фильтр «без категории» отдельным чипом.

### ADR-035: Achievements
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Мотивация — критичный фактор retention, но одной серии дней мало: она отвечает на «зайти сегодня», а не на «расти месяцами». Нужны долгосрочные цели, которые видно всегда и которые не зависят от ежедневного темпа.
- **Decision:**
  - Девять достижений (`AchievementType`): серия 7/30/100, слов 100/500/1000, верных подряд 10/50, челленджей 7.
  - Таблица `achievements` (**schema v10 → v11**): `id` = `AchievementType.key`, `progress`, `unlockedAtUtc`, `lastUpdatedAtUtc`.
  - `CheckAchievements` пересчитывает метрики из существующих источников: серия — `ComputeStreak`, выученные слова — `WordStatus.mastered`, верные подряд — журнал ответов, челленджи — `ChallengeStreak`.
  - Вызывается после `RecordReview`; результат приходит в `ReviewOutcome.newlyUnlockedAchievements`, чтобы UI показал тост только за новые.
  - В `RecordReview` зависимость **опциональна** (`CheckAchievements?`): достижения вспомогательные, их отсутствие или сбой не должны менять исход ответа.
  - Полностью офлайн: никаких сетевых вызовов и никаких серверных достижений.
- **Alternatives considered:**
  - Хранить только счётчики в `UserSettings` — отклонено: девять порогов и моменты открытия в настройках сделали бы их свалкой.
  - Считать на лету без таблицы — отклонено: `unlockedAt` нужен для показа даты и не выводится из метрик.
  - Тост через `SnackBar` — отклонено: SnackBar перекрывает нижние кнопки урока; нужен Overlay.
- **Consequences:** пользователь видит долгосрочный прогресс и дату открытия. Метрика `perfect` считается по журналу ответов одним проходом — при десятках тысяч записей это станет заметно (BL-81).
- **Open questions:** расширить до 20–30 достижений — BL-81; тост в уроке не реализован (данные уже прокинуты через `ReviewOutcome`).

### ADR-036: Word Match (memory game)
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Нужна короткая игра на 2–3 минуты — пауза между серьёзными сессиями, когда полный урок начинать не хочется. Memory — проверенная механика (Duolingo, LingQ): правила понятны без обучения, а узнавание пары EN↔RU тренирует связь «слово — перевод» без SRS-нагрузки.
- **Decision:**
  - `MemoryCard` + `MemoryCardState` (`hidden` / `flipped` / `matched`) и `MemoryGame` (карточки, открытые id, ходы, флаг победы). Enum назван `MemoryCardState`, а не `CardState`: имя `CardState` уже занято VO расписания SM-2.
  - `GenerateMemoryGame` — случайные N пар (по умолчанию 8), инжектированный `Random`; при нехватке слов берётся сколько есть, пустой словарь даёт пустую партию (экран показывает «Добавьте слова»).
  - `FlipMemoryCard` — чистая функция: открыть карточку, проверить пару, отметить `matched`, посчитать ход. Отдельный `resetFlipped` закрывает несовпавшие.
  - UI держит задержку 800 мс перед сбросом и таймер отменяет в `dispose`: домен о времени не знает.
  - Сетка 4×4, 16 карточек; победа — диалог «Победа!» с числом ходов и кнопками «Заново» / «Выйти».
  - Полностью офлайн, схема БД не меняется (v11): рекорды не сохраняются.
- **Alternatives considered:**
  - 10 пар — отклонено: на телефоне 20 карточек мелкие, игра превращается в разглядывание.
  - Cross-word (пересечение слов) — отклонено: слишком сложно для 2-минутной паузы.
  - Хранить рекорды сразу — отложено (BL-84): нужна ещё одна таблица и решение по формату.
- **Consequences:** на главной теперь пять тренировок; игра не влияет на `DailyStats`, XP и SRS — это развлечение, а не учебная сессия (как Cloze, ADR-025).
- **Open questions:** адаптивное число пар по уровню CEFR — BL-83; рекорды (лучшее время/ходы) — BL-84.

### ADR-037: Typing Speed
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Все мини-игры проверяют узнавание (перевод → слово), подстановку (cloze) или слух (диктант), но ни одна не тренирует **воспроизведение с клавиатуры** — навык, который нужен в реальной переписке. Нужна короткая игра с измеримым результатом, чтобы был виден прогресс.
- **Decision:**
  - `TypingSession` (VO): 10 случайных слов, индекс, число верных; `next(wasCorrect:)` двигает сессию.
  - `GenerateTypingSession` — случайные слова, инжектированный `Random`, fallback при нехватке слов.
  - `SubmitTypingAnswer` — чистая функция: сравнение `trim` + нижний регистр, чтобы регистр и лишний пробел не считались ошибкой.
  - `SaveTypingRecord` — WPM = `верные * 60 / секунды`, точность = доля верных, очки = `wpm * accuracy / 100`. Сессия короче секунды считается секундой: иначе WPM был бы бесконечным.
  - Таблица `typing_records` (**schema v11 → v12**): каждая сессия — отдельная строка, поэтому виден топ-10 и лучший результат, а история не теряется.
  - Экран `/typing-speed`: перевод крупным шрифтом, ввод с клавиатуры, живой WPM раз в секунду (`Timer.periodic`), зелёный/красный SnackBar с правильным ответом, диалог итогов с «Ещё раз» / «Выйти».
  - Полностью офлайн; игра не влияет на `DailyStats`, XP и SRS — это тренировка, а не учебная сессия.
- **Alternatives considered:**
  - WPM по символам (`chars / 5 / минуты`) — отклонено: на коротких словах расходится с ощущением игрока, а сравнивать сессии между собой проще по словам.
  - Хранить только лучший результат — отклонено: пропадает история и топ-10.
  - Таймер на всё упражнение (60 с) — отложено (BL-85): это другой режим, а не замена.
- **Consequences:** шестая тренировка на главной, сетка переведена на три колонки. Рекорды копятся локально, без сети.
- **Open questions:** режим «60 секунд» — BL-85; показывать ли топ-10 в UI (репозиторий уже умеет).

### ADR-038: Phrasebook
- **Status:** Accepted
- **Date:** 2026-11-07
- **Context:** Словарь учит отдельным словам, но в поездке и переписке нужны готовые конструкции («Где выход на посадку?»). Заводить их словами нельзя: у фразы нет SM-2-прогресса и статуса, а `term` из нескольких слов сломал бы очередь дня и статистику.
- **Decision:**
  - Отдельная таблица `phrases` (**schema v12 → v13**): `phrase`, `translation`, `category`, `level`, `createdAtUtc`.
  - Контент — ассет `assets/seed/phrases_v1.json`, загружается лениво: `phrasesProvider` наполняет таблицу при первом открытии экрана (`PhraseSeedLoader` идемпотентен). Bootstrap не трогаем: разговорник не нужен для старта и не должен его задерживать.
  - Контракт `PhraseRepository` только на чтение (`getAll`, `getByCategory`, `count`, `insertMany`): пользователь контент не правит.
  - Экран `/phrasebook`: вкладки строятся из категорий в данных (новая тема в контенте = новая вкладка), поиск по фразе и переводу.
  - `tools/generate_phrases.dart` — dev-инструмент: генерирует фразы через DeepSeek в отдельный файл, ассеты автоматически не перезаписываются (машинный перевод требует ручной проверки).
  - Полностью офлайн; фразы не влияют на SRS, XP и статистику.
- **Alternatives considered:**
  - Хранить фразы в `words` с многословным `term` — отклонено: ломает очередь, дедупликацию и поиск.
  - Грузить фразы в bootstrap — отклонено: лишняя работа на старте ради экрана, который открывают редко.
  - Отдельный экран без вкладок — отклонено: тем становится много, список превращается в свалку.
- **Consequences:** седьмая тренировка на главной (сетка три колонки). Контент расширяется скриптом и ревью, без релиза приложения — только пересборкой ассета.
- **Open questions:** озвучка фраз через TTS; избранное и повторение фраз; связь фраз с уровнем пользователя (сейчас просто метка).

### ADR-039: Reading Mode
- **Status:** Accepted
- **Date:** 2026-11-12
- **Context:** Нужна механика погружения (implicit learning): короткие рассказы на уровне пользователя дают естественное повторение уже известных слов и контекст для новых. Карточки учат слова изолированно; связный текст показывает, как они живут в речи.
- **Decision:**
  - Сущность `Story` (id, title, text, translation, level: `CefrLevel`) и таблица `stories` (**schema v13 → v14**) — отдельно от `words` и `phrases`.
  - Ленивый `StorySeedLoader`: наполняет таблицу из `assets/seed/stories_v1.json` при первом открытии экрана, не при старте.
  - `ExtractUnknownWords`: очистка текста регекспом + сравнение со словарём; незнакомые слова добавляются в словарь с `translation: '?'` — пользователь редактирует вручную.
  - Экраны `/reading` (список с CEFR-фильтром A1–C1, дефолт — `preferredLevel`) и `/reading/:id` (текст, перевод по кнопке, диалог незнакомых слов).
  - Контент генерируется dev-скриптом `tools/generate_stories.dart` (DeepSeek) и сливается `tools/merge_stories.dart`; в APK попадает только проверенный `stories_v1.json`.
- **Alternatives considered:**
  - (A) Вставить рассказы в `words` (term = весь текст) — отклонено: сломает SM-2, дубли и mastery.
  - (B) Генерировать рассказы на лету через AI — отклонено: оффлайн-требование учебного цикла.
- **Consequences:**
  - Восьмая карточка на главной («Чтение»); чтение не влияет на SRS, XP и статистику.
  - Демо-рассказы в seed: 4, плюс 30 сгенерированных через tools/generate_stories.dart (итого 34: A1×11, A2×12, B1×11). Уровни добавлены вручную после ревью. Пользователь расширяет через generate_stories.dart + merge_stories.dart.
  - Добавленные незнакомые слова попадают в очередь дня как новые (уровень рассказа).
- **Open questions:** озвучка рассказа через TTS (BL-87).

### ADR-041: Chat with AI bot
- **Status:** Proposed
- **Date:** 2026-11-13
- **Context:** Нужен интерактивный помощник для вопросов про английский. Приложение ходит через прокси (ADR-019), ключ модели живёт на сервере. История сообщений — локально (Drift), в облако не синхронизируется.
- **Decision:**
  - Таблица `chat_messages` (**schema v14 → v15**): `id` autoIncrement, `role` ('user' | 'assistant'), `content`, `createdAtUtc`; индекс `idx_chat_messages_created` по `createdAtUtc`.
  - `SendChatMessage` (domain): сохраняет сообщение пользователя, берёт последние 10 сообщений (включая новое) как контекст, отправляет через доменный контракт `ChatGenerator`, сохраняет ответ. Пустое сообщение — `ArgumentError`.
  - `AiClient.sendChat` (data) реализует `ChatGenerator` (паттерн ADR-019): POST `{"type":"chat","messages":[...],"word":level}` на прокси, таймаут 30 с, ответ `{"message":...}`, `AiException` при ошибке.
  - UI: `ChatScreen` (`/chat`, slide-up) + FAB «Помощник» на Home + ListTile в Profile. Приветствие — заглушка UI, в БД не сохраняется. Очистка истории — с подтверждением.
  - Уровень пользователя (`preferredLevel.label`) передаётся в поле `word` для правильного тона ответа.
  - История хранится локально и НЕ синхронизируется в облако (приватность); при ошибке AI сообщение пользователя остаётся в истории.
- **Alternatives considered:**
  - (A) Отдельный сервис (ChatGPT API) — отклонено: два провайдера, второй ключ и второй прокси.
  - (B) Локальная модель — отклонено: качество и размер приложения.
- **Consequences:** +1 таблица. Токены DeepSeek тратятся на чат (~$0.0002/обмен). Лимит 10 сообщений — экономия токенов. Содержимое переписки уходит на прокси только по явной отправке; privacy policy обновлена.
- **Open questions:** rate limiting (BL-89), оффлайн-кэш ответов (BL-90).

### ADR-042: Error Helper
- **Status:** Proposed
- **Date:** 2026-11-13
- **Context:** Пользователь ошибается в игре, но не понимает почему. Нужна контекстная помощь через AI, не блокирующая игру.
- **Decision:**
  - `ErrorExplainer` — доменный контракт объяснения ошибки (паттерн ADR-019).
  - `AiClient.explain` через прокси: POST `{"type":"explain_error","word":context}` → `{"explanation":...}`, таймаут 30 с, `AiException` при ошибке.
  - `ExplainError` (domain) добавляет уровень пользователя в контекст для тона объяснения.
  - `ErrorHelperButton` — переиспользуемый виджет: иконка робота, loading, нижний лист с объяснением и кнопкой «Понятно».
  - Показ в 5 играх: Cloze, Error Hunter, Scramble, Listening, Typing.
  - Иконка только после неверного ответа; игра не блокируется. В Cloze/Scramble/Listening SnackBar «Неверно» заменён persistent-карточкой (SnackBar исчезает, а объяснение нужно позже); в Error Hunter карточка живёт в листе вариантов, в Typing — до следующего ответа без паузы заезда.
- **Alternatives considered:**
  - (A) Отдельный экран — отклонено: лишний клик.
  - (B) Напоминание в начале игры — отклонено: отвлекает.
- **Consequences:** +1 AI-тип в прокси (уже готов), новой таблицы нет. Токены ~$0.0003 на объяснение. По явному тапу на прокси уходят предложение/слово, ответ пользователя и правильный ответ; до тапа ничего не отправляется. Privacy Policy обновлена (EN + RU).
- **Open questions:** rate limit (BL-92).

## Реестр

| ID | Название | Status |
|---|---|---|
| ADR-001 | Core stack | Accepted |
| ADR-002 | Persistence: Drift vs Isar | Accepted |
| ADR-003 | Domain layer location | Accepted |
| ADR-004 | WordStatus source of truth | Accepted |
| ADR-005 | ReviewLog append-only + replaceAll for import | Accepted |
| ADR-006 | Flutter bootstrap | Accepted |
| ADR-007 | Package versions at Phase 2a | Accepted |
| ADR-008 | Generated files committed | Accepted |
| ADR-009 | ReviewLogId generation | Accepted |
| ADR-010 | Undo semantics | Accepted |
| ADR-011 | RecordReview returns outcome | Accepted |
| ADR-012 | TTS and notifications architecture | Accepted |
| ADR-013 | Reset progress semantics | Accepted |
| ADR-014 | Export/Import MVP via clipboard | Accepted |
| ADR-015 | Streak freeze semantics | Accepted |
| ADR-016 | Sentry crash reporting | Accepted |
| ADR-017 | Local notifications | Accepted |
| ADR-018 | TTS migration to stts | Accepted |
| ADR-019 | AI associations via proxy | Accepted |
| ADR-020 | Error Hunter contract | Accepted |
| ADR-021 | Analytics — read-only dashboard | Accepted |
| ADR-022 | Cloud sync via Supabase (optional, manual) | Accepted |
| ADR-023 | CEFR level (A0–C2) for words and for the user | Accepted |
| ADR-024 | Duplicate prevention | Accepted |
| ADR-025 | Cloze Test architecture | Accepted |
| ADR-026 | Weak words review | Accepted |
| ADR-027 | Word Scramble | Accepted |
| ADR-028 | Listening Dictation + SRS integration | Accepted |
| ADR-029 | UI dependencies | Accepted |
| ADR-030 | Daily Challenge | Accepted |
| ADR-031 | Homonyms via duplicate terms | Accepted |
| ADR-032 | Challenge Streak | Accepted |
| ADR-033 | Smart Review | Accepted |
| ADR-034 | Custom categories | Accepted |
| ADR-035 | Achievements | Accepted |
| ADR-036 | Word Match (memory game) | Accepted |
| ADR-037 | Typing Speed | Accepted |
| ADR-038 | Phrasebook | Accepted |
| ADR-039 | Reading Mode | Accepted |
| ADR-041 | Chat with AI bot | Proposed |
| ADR-042 | Error Helper | Proposed |
