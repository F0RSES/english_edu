# Backlog

Приоритет: P0 — блокирует следующий шаг, P1 — нужно к релизу, P2 — после релиза, P3 — гигиена, когда дойдут руки.
Статус: Todo / In progress / Review / Done.

| ID | Приоритет | Задача | Критерий приёмки | Статус |
|---|---|---|---|---|
| BL-01 | P0 | Phase 1 — Архитектура: слои, контракты domain, ADR-002 (Drift vs Isar) | ARCHITECTURE.md committed; lib/domain/ содержит контракты; dart analyze = 0; dart test test/domain/ зелёный | In progress |
| BL-02 | P0 | Phase 1 — Контент-пайплайн: схема seed, скрипт валидации, 300–500 слов с лицензиями | Seed проходит валидацию без ошибок, у каждого слова есть источник и лицензия, объём в диапазоне 300–500 | In progress |
| BL-03 | P0 | Phase 2 — Каркас + Drift schema v1 + миграции + репозитории + export/import JSON | Приложение запускается, схема v1 создаётся с нуля и мигрирует на тестовой базе, export→import возвращает идентичные данные | Done |
| BL-04 | P0 | Phase 3 — Ядро: SM-2 + review log + due-очередь + LessonScreen + TTS + undo + session complete | Урок пишет review log, пересчитывает интервалы по SM-2 и завершается экраном итогов; undo возвращает предыдущее состояние карточки | In progress |
| BL-05 | P0 | Phase 4 — DictionaryScreen + Settings + onboarding + empty states + daily goal | Новый пользователь проходит onboarding, видит словарь и настройки, у каждого пустого экрана есть empty state, дневная цель сохраняется и отображается | In progress |
| BL-06 | P0 | Phase 5 — Streak (local TZ) + XP + локальные уведомления + accessibility | Streak считается по локальной полуночи и покрыт тестами на смену TZ, уведомление приходит в заданное локальное время, экраны проходят проверку screen reader | Todo |
| BL-07 | P0 | Phase 6 — Бета: TestFlight/Internal Testing, Sentry, CI, smoke-тесты | Сборка уходит в TestFlight и Google Internal Testing, CI гоняет analyze и test на каждый PR, Sentry работает без PII, DSN только через --dart-define | Todo |
| BL-08 | P1 | Phase 7 — Публикация: store listing, privacy policy, support email | Листинги опубликованы в обоих сторах, privacy policy доступна по публичному URL, support email отвечает | Todo |
| BL-09 | P2 | Phase 8 — AI-прокси (post-launch) | AI-функции вызываются только через прокси, ключи отсутствуют в клиенте, решение зафиксировано отдельным ADR | Todo |
| BL-10 | P2 | Phase 2 — переименовать PROJECT_CONTEXT/Known issues в Environment; вынести туда факты окружения | PROJECT_CONTEXT без Known issues; факты в Environment; analyze=0 | Todo |
| BL-11 | P2 | Phase 2 — оценить Optional<T> sealed-класс вместо sentinel copyWith; старт при любом из: (a) ≥4 места с `as T?` / sentinel-обнулением в domain, (b) ≥2 bug fix из-за sentinel | ADR с решением keep/replace; analyze=0 | Todo |
| BL-12 | P2 | Phase 2 — устранить дубль «Правила домена» в 10-project.md и 20-code-style.md; одно определение, второй файл ссылается | grep находит один блок правил | Todo |
| BL-13 | P3 | Phase 4 — кэш TodayQueue.all, если профилирование покажет проблему | профиль до/после, <1ms в hot path | Todo |
| BL-14 | P3 | Phase 2 — добавить StatsRepository.getActiveDates(from, to) → List<LocalDate>, если getRange по 3650 строк покажет проблему в профиле | профайлинг, <10ms на вызов | Todo |
| BL-15 | P3 | Phase 5 — вынести _lookbackDays из ComputeStreak в UserSettings или константу конфигурации | ADR + миграция | Todo |
| BL-16 | P3 | Phase 2 — индексы Drift для getAll/replaceAll | профиль экспорта <100ms на 10k записей | Todo |
| BL-17 | P2 | Phase 2 — CI matrix с TZ=UTC, Europe/Berlin, America/Los_Angeles; все streak/review тесты прогоняются во всех трёх | green на всех TZ | Todo |
| BL-18 | P3 | Phase 3 — оценить FSRS/Anki-style для долгих серий | ADR keep SM-2 / switch, тесты на обе формулы | Todo |
| BL-19 | P3 | Phase 2 — вынести `_requireUtc` в общий хелпер, когда появится третий потребитель | один хелпер, analyze=0 | Todo |
| BL-20 | P2 | Phase 2 — все Drift-маппинги конвертируют в UTC до создания сущностей | integration-тест round-trip local→UTC→local для всех DateTime-полей | Todo |
| BL-21 | P2 | Phase 2 — заменить autoTranslated на verified; sourceId: ngsl-auto → ngsl-verified | нет autoTranslated=true в assets/seed/; валидатор 0 warnings | Todo |
| BL-24 | P3 | CI — тесты по Platform.script; dart test из любой директории | тесты зелёные при запуске не из корня | Todo |
| BL-25 | P3 | Phase 3 — mastery-порог на реальных данных (ADR keep/change) | ADR с решением, тесты на оба порога | Todo |
| BL-26 | P3 | Phase 2a.3 — riverpod_annotation + codegen для Riverpod | analyze=0, тесты DI | Todo |
| BL-27 | P3 | Phase 6 — CI matrix: Flutter + Dart для analyze/test | green на обеих матрицах | Todo |
| BL-28 | P2 | Phase 2a.2 или 2a.3 — аудит и возврат 4 линтов: (1) `unnecessary_type_name_in_constructor` — `dart fix`, ревью (меняет `const Foo(...)` на `const new(...)`); (2) `prefer_initializing_formals` — аудит 2a.0c показал, что имена параметров НЕ ломаются, 24 места в 5 файлах `lib/domain/usecases/`, применимо `dart fix` + ревью диффа; (3) `use_null_aware_elements` — `dart fix`, ревью; (4) `unnecessary_const_in_enum_constructor` — `dart fix`, ревью | analyze=0 с 4 включёнными правилами; 174 теста зелёные; `lib/domain` diff отревьюен построчно | Todo |
| BL-29 | P3 | Phase 2a.2 — seed loader: при первом запуске читать `assets/seed/words_v1.json` и вставлять через `WordRepository` | fresh install → 20 слов в БД; повторный запуск не дублирует | Todo |
| BL-30 | P3 | Phase 3 — если `UserSettings.ttsSpeed` даст drift equality при слайдере, переделать на `int ttsSpeedPermille` (аналог easePermille) | ADR keep/change | Todo |
| BL-31 | P3 | Phase 2a.2b — заменить `isA<Exception>()` на конкретные типы (`SqliteException` / `DriftWrappedException`) в `app_database_test` | точные типы исключений в тестах | Done |
| BL-32 | P3 | Phase 3 — перевести `WordRepository.search` на FTS5, если линейный проход станет узким местом | FTS-индекс + миграция схемы, тесты поиска | Todo |
| BL-33 | P3 | Phase 2a.3 — `insertManyIgnore` для batch без конфликта | метод в контракте + тест на дубликаты | Todo |
| BL-34 | P3 | Phase 2a.3 — документировать порядок `replaceAll` при импорте (settings → words → progress → logs → stats) | раздел в ARCHITECTURE + тест порядка | Todo |
| BL-35 | P3 | Phase 2a.3 — chunking `getByIds` по 500 id | тест на 1000+ id без `too many SQL variables` | Todo |
| BL-36 | P2 | Phase 5 — после `ImportProgress` инвалидировать `nextReviewLogIdProvider` с пересчётом `max(id)` | импорт 1000 логов → следующая запись получает id 1001 | Todo |
| BL-37 | P3 | Phase 3b — `RecordReview` возвращает результат с XP, экран перестаёт дублировать `+10` | analyze=0, тест на XP из use case | Done |
| BL-38 | P2 | Phase 5 — notifications + streak UI: `flutter_local_notifications` 22.3.3, `timezone`, `flutter_timezone`; поднять `compileSdk 37`, AGP 9.1.1, включить desugaring; manifest: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` + receivers; iOS: `AppDelegate` + `Podfile` + platform 13.0 | `flutter build apk` зелёный, permission request на старте, ежедневное напоминание срабатывает | Todo |
| BL-39 | P2 | Phase 5 — атомарный `nextId`: транзакция + retry на конфликт id при параллельных вставках | 100 параллельных insert → 100 уникальных id, ни одного исключения | Todo |
| BL-41 | P3 | Phase 4 — `HomeScreen`: `FutureBuilder` получает future из `build`, поэтому любой rebuild перезапускает запросы | `FutureProvider` для серии/цели/очереди, ручной `ref.invalidate` после урока | Done |
| BL-43 | P2 | Phase 5 — подтверждение выхода из недоделанной сессии | `canPop: !_hasProgress` + диалог «Завершить сессию?», тесты на отмену и подтверждение | Done |
| BL-44 | P3 | Phase 5 — файловый export/import вместо clipboard: `file_selector` + `share_plus` (ADR-014) | JSON-файл на устройстве: сохранение через share_plus, выбор через file_selector | Todo |
| BL-45 | P3 | Phase 4 — склонение по числу продублировано в `HomeScreen` и `StreakCard` | `pluralize` в `lib/core/text/plural.dart`, analyze=0, тесты на все формы | Done |
| BL-46 | P2 | Phase 5d — Freeze система (ADR-015): таблица `FrozenDays`, `schemaVersion 2`, `ComputeStreak` учитывает замороженный день, вехи 7/30 выдают freeze | миграция v1→v2 работает, freeze применяется при пропуске одного дня, тест на серию через заморозку | Todo |
| BL-40 | P2 | Phase 4 — `dart format` не применён к репозиторию: 83 файла вне scope задач 2a–3b не соответствуют formatter'у 3.13.7 (tall style) | `dart format lib test tools` одной задачей, diff отревьюен (только пробелы/переносы), analyze=0, тесты зелёные | Done |
| BL-47 | P3 | Phase 6c — performance traces Sentry (`tracesSampleRate > 0`), если понадобятся: сейчас 0 (ADR-016) | ADR + спайк на реальном устройстве: бюджет трейсов и влияние на холодный старт | Todo |
| BL-48 | P2 | Phase 7 — при первой APK-сборке проверить, что `ndkVersion 28.2.13676358` совместим с `jni` из `sentry_flutter` 10.3 | `flutter build apk` зелёный; при несовместимости — поднять/понизить NDK и записать в ADR-016 | Todo |
| BL-49 | P3 | Phase 6c — если `captureException` начнёт бросать, обернуть вызовы в UI в try/catch | ошибка репортёра не ломает обработку сбоя: тест «репортёр бросает → snackbar всё равно показан» | Todo |

## Заметки
- Задача без критерия приёмки в бэклог не попадает.
- Долг, замеченный вне scope, добавляется сюда отдельной строкой, а не правится молча.
