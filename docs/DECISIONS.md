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
  - v2: `+ frozenDays`. v1 импортируется с пустым `frozenDays` (backward compat). `ExportPayload.currentSchemaVersion = 2`; будущие изменения — v3.
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
- **Date:** 2026-11-13
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
