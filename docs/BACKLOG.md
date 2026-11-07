# Backlog

Приоритет: P0 — блокирует следующий шаг, P1 — нужно к релизу, P2 — после релиза, P3 — гигиена, когда дойдут руки.
Статус: Todo / In progress / Review / Done.

| ID | Приоритет | Задача | Критерий приёмки | Статус |
|---|---|---|---|---|
| BL-01 | P0 | Phase 1 — Архитектура: слои, контракты domain, ADR-002 (Drift vs Isar) | ARCHITECTURE.md committed; lib/domain/ содержит контракты; dart analyze = 0; dart test test/domain/ зелёный | Done |
| BL-02 | P0 | Phase 1 — Контент-пайплайн: схема seed, скрипт валидации, 300–500 слов с лицензиями | Seed проходит валидацию без ошибок, у каждого слова есть источник и лицензия, объём в диапазоне 300–500 | Done |
| BL-03 | P0 | Phase 2 — Каркас + Drift schema v1 + миграции + репозитории + export/import JSON | Приложение запускается, схема v1 создаётся с нуля и мигрирует на тестовой базе, export→import возвращает идентичные данные | Done |
| BL-04 | P0 | Phase 3 — Ядро: SM-2 + review log + due-очередь + LessonScreen + TTS + undo + session complete | Урок пишет review log, пересчитывает интервалы по SM-2 и завершается экраном итогов; undo возвращает предыдущее состояние карточки | Done |
| BL-05 | P0 | Phase 4 — DictionaryScreen + Settings + onboarding + empty states + daily goal | Новый пользователь проходит onboarding, видит словарь и настройки, у каждого пустого экрана есть empty state, дневная цель сохраняется и отображается | Done |
| BL-06 | P0 | Phase 5 — Streak (local TZ) + XP + локальные уведомления + accessibility | Streak считается по локальной полуночи и покрыт тестами на смену TZ, уведомление приходит в заданное локальное время, экраны проходят проверку screen reader | Done |
| BL-07 | P0 | Phase 6 — Бета: TestFlight/Internal Testing, Sentry, CI, smoke-тесты | Сборка уходит в TestFlight и Google Internal Testing, CI гоняет analyze и test на каждый PR, Sentry работает без PII, DSN только через --dart-define | Done |
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
| BL-21 | P2 | Phase 2 — ревью `autoTranslated` контента | **MVP-проход закрыт:** выборка 200 слов (`--sample=200`), 6 проблем исправлены через `tools/manual_review_overrides.json` (`accord`, `articulate`, `boycott`, `assault`, `block`, `bludgeon`), warnings 2071 → 2065. Полное ревью остальных 2065 слов — BL-79 | Done |
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
| BL-38 | P2 | Phase 5 — notifications: `flutter_local_notifications` 22.3.3, `timezone`, `flutter_timezone`; desugaring + multiDex; manifest: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` + 2 receivers; `compileSdk` 36 и AGP 9.1.0 оставлены (пакет требует 35+/8.11.1+); exact alarms — BL-53; iOS delegate — 6c | `flutter build apk --debug` зелёный, `inexactAllowWhileIdle`, разрешение спрашивается при включении напоминаний | Done |
| BL-39 | P2 | Phase 5 — атомарный `nextId`: транзакция + retry на конфликт id при параллельных вставках | 100 параллельных insert → 100 уникальных id, ни одного исключения | Todo |
| BL-41 | P3 | Phase 4 — `HomeScreen`: `FutureBuilder` получает future из `build`, поэтому любой rebuild перезапускает запросы | `FutureProvider` для серии/цели/очереди, ручной `ref.invalidate` после урока | Done |
| BL-43 | P2 | Phase 5 — подтверждение выхода из недоделанной сессии | `canPop: !_hasProgress` + диалог «Завершить сессию?», тесты на отмену и подтверждение | Done |
| BL-44 | P3 | Phase 5 — файловый export/import вместо clipboard: `file_selector` + `share_plus` (ADR-014) | JSON-файл на устройстве: сохранение через share_plus, выбор через file_selector | Todo |
| BL-45 | P3 | Phase 4 — склонение по числу продублировано в `HomeScreen` и `StreakCard` | `pluralize` в `lib/core/text/plural.dart`, analyze=0, тесты на все формы | Done |
| BL-46 | P2 | Phase 5d — Freeze система (ADR-015): таблица `FrozenDays`, `schemaVersion 2`, `ComputeStreak` учитывает замороженный день, вехи 7/30 выдают freeze | миграция v1→v2 работает, freeze применяется при пропуске одного дня, тест на серию через заморозку | Done |
| BL-40 | P2 | Phase 4 — `dart format` не применён к репозиторию: 83 файла вне scope задач 2a–3b не соответствуют formatter'у 3.13.7 (tall style) | `dart format lib test tools` одной задачей, diff отревьюен (только пробелы/переносы), analyze=0, тесты зелёные | Done |
| BL-47 | P3 | Phase 6c — performance traces Sentry (`tracesSampleRate > 0`), если понадобятся: сейчас 0 (ADR-016) | ADR + спайк на реальном устройстве: бюджет трейсов и влияние на холодный старт | Todo |
| BL-48 | P2 | Phase 7 — при первой APK-сборке проверить, что `ndkVersion 28.2.13676358` совместим с `jni` из `sentry_flutter` 10.3 | `flutter build apk` зелёный; при несовместимости — поднять/понизить NDK и записать в ADR-016 | Todo |
| BL-49 | P3 | Phase 6c — если `captureException` начнёт бросать, обернуть вызовы в UI в try/catch | ошибка репортёра не ломает обработку сбоя: тест «репортёр бросает → snackbar всё равно показан» | Todo |
| BL-50 | P3 | Phase 5e — полная логика streak continuity + защита от эксплойта freeze (ручное добавление через debug-меню) | серия переживает пропуск автоматически без bootstrap-эвристики; ручное добавление freeze не увеличивает баланс | Todo |
| BL-51 | P2 | Phase 5e — заморозки не входят в export/import (формат v1) и не очищаются `ResetProgress` | импорт снимка не оставляет «висячих» заморозок; сброс прогресса обнуляет `frozen_days` | Done |
| BL-53 | P3 | Phase 6c — если тестеры пожалуются на неточность напоминаний: `AndroidScheduleMode.exact` + `SCHEDULE_EXACT_ALARM` + `requestExactAlarmsPermission()` | точное время на Android 14+, инструкция по разрешению в UI | Todo |
| BL-54 | P2 | Phase 6c — миграция `flutter_tts` 4.2.5 → `stts` 1.3.4: flutter_tts применяет Kotlin Gradle Plugin, будущие версии Flutter перестанут такие плагины собирать | `flutter build apk --debug` зелёный без предупреждения KGP, `SttsTtsService`, analyze=0, тесты без изменений | Done |
| BL-55 | P3 | Если словарь вырастет: `GetTodayQueue` читает `words.getAll()` + `progress.getAll()` целиком и фильтрует в памяти | SQL-выборка с JOIN и LIMIT, замер на 10k слов | Todo |
| BL-56 | P3 | Phase 5 — кастомные категории: пользователь создаёт свои, сейчас список фиксирован (`wordCategories`) | ADR-034: таблица `user_categories` (v10) с `UNIQUE name` и 4 базовыми, `CreateUserCategory` + диалог, «+ Создать категорию» в форме слова, фильтр словаря из БД, пункт в профиле. Удаление категорий — BL-80 | Done |
| BL-57 | P2 | Export/import теряет `Word.category`: `ExportPayloadCodec` сериализует только v2-поля, формат снимка не расширен | `category` в JSON снимка + round-trip тест; при необходимости — payload schema v3 и ADR | Done |
| BL-58 | P3 | Phase 7c — TTL для кэша подсказок (например, 30 дней), чтобы ассоциации обновлялись | поле `createdAtUtc` уже есть: фильтр по возрасту в `GetWordHint` + тест на протухание | Todo |
| BL-59 | P2 | Прокси `error_hunter` не возвращает `correctWord`: клиент выводит ответ как первый вариант ≠ `wrongWord` (порядок в `options` становится контрактом) | прокси присылает `correctWord` явно; `AiClient`/VO уже читают поле, если оно есть | Done |
| BL-60 | P2 | `wrongWord` может быть фразой (`"a interesting"`), а `ErrorHunterScreen` сравнивает отдельные слова — задание не открывает выбор варианта | либо воркер нормализует `wrongWord` до одного слова, либо клиент ищет фразу по окну слов; тест на многословный `wrongWord` | Done |
| BL-61 | P2 | Онбординг не показывается автоматически при первом запуске: нужен сохранённый флаг, а это изменение схемы/настроек (правило «БД не меняется» в Phase 11) | флаг `onboardingCompleted` в `UserSettings` + миграция v4→v5, экран показывается один раз | Done |
| BL-62 | P2 | В облако уходит только `WordProgress`: `review_logs`, `daily_stats`, `frozen_days` и настройки остаются на устройстве — на новом телефоне серия, статистика и заморозки обнуляются | расширить схему облака и `CloudSyncService` на эти сущности (ADR-022, Open questions), тест на перенос серии | Todo |
| BL-63 | P3 | `pull` тянет всю таблицу целиком каждым нажатием; при росте словаря и истории это лишний трафик | инкрементальный `pull` по `updated_at_utc > since` (курсор хранить локально), замер на 10k строк | Todo |
| BL-64 | P2 | `ResetProgress` очищает только локальную БД: следующий `pull` вернёт удалённые строки из облака | удаление строк `user_progress` при сбросе (или явная пометка «облако — бэкап») + подтверждение в UI | Todo |
| BL-65 | P2 | Phase 13b — словарь не размечен по уровням: seed v1 без `level`, поэтому все 20 слов — A1, и фильтр по A2+ в словаре даёт пусто | 300–500 слов по уровням A1–B2 с полем `level` в JSON (генератор `--level=A1` и валидатор уровня уже готовы, Phase 13c) | Todo |
| BL-66 | P3 | Phase 13c — UI/text polish: типографика, переносы длинных слов в карточке, контраст в тёмной теме (бейдж уровня на `teal`/`lightGreen` фоне) | единый типографический масштаб, проверка контраста WCAG AA, golden-тесты на тёмную тему | Todo |
| BL-67 | P2 | Export/import теряет `Word.level`: `ExportPayloadCodec` пишет поля до v3 включительно, уровень в снимке отсутствует | `level` в JSON снимка + round-trip тест, при необходимости payload schema v4 и ADR | Done |
| BL-68 | P3 | Снимок v4 переносит `Word.level`, но не `UserSettings.preferredLevel`: после импорта на новом устройстве уровень пользователя откатывается к A1 | `preferredLevel` в `settings` снимка (payload v5) + тест на round-trip | Done |
| BL-69 | P3 | Phase 14 — гомонимы: `apple` (яблоко) и `Apple` (компания) нельзя завести разными словами — `findByTerm` считает их одним (ADR-024) | ADR-031: разные `Word` с одним `term` и разными `id`; `findAllByTerm`; диалог «Добавить ещё одно значение»; `partOfSpeech` в UI. `Word.senses` и UNIQUE-индекс — BL-76 | Done |
| BL-70 | P3 | Phase 15 — Smart review: очередь повторения выбирается алгоритмом (пропущенные дни, трудные слова, давно не виденные), а не только `dueAt` (ADR-026) | ADR-033: `SmartReviewItem` + `GetSmartReviewQueue` (score = lapses\*10 + давность + ease), `LessonMode.smart`, кнопка «Умное повторение (N)» на главной | Done |
| BL-71 | P3 | Phase 15 — записывать `RecordReview` после игр Word Scramble / диктанта, чтобы ответы влияли на SRS | вызов `RecordReview` после сессии с градацией «верно / неверно», тест на изменение `dueAt` | Done |
| BL-72 | P3 | Phase 15 — Error Hunter не пишет в SRS: игра про грамматику, а `RecordReview` меняет `dueAt` слова (ADR-028) | решить, что записывать: слово из задания или ничего, + тест | Todo |
| BL-74 | P3 | Phase 16 — оценить Lottie для сложных анимаций (confetti при завершении сессии, transition между экранами) | ADR keep/replace по `flutter_animate`; perf-замер на устройстве; при отказе от Lottie — запись решения в ADR-029 | Todo |
| BL-75 | P3 | Phase 16 — Streak of challenges (серия дней с выполненным ежедневным заданием) | ADR-032: таблица `challenge_streaks` (v9), `ChallengeStreak` + `UpdateChallengeStreak`, обновление при `ClaimDailyChallenge`, бейдж на карточке | Done |
| BL-76 | P3 | Phase 16 — объединить гомонимы в одной карточке (`Word.senses: List<Translation>`) | миграция v9→v10, все экраны обновлены, экспорт переносит senses, тест на round-trip | Todo |
| BL-77 | P3 | Phase 16 — достижения за прогресс | ADR-035: 9 достижений, таблица `achievements` (v11), `CheckAchievements` после `RecordReview`, экран `/achievements`, `newlyUnlockedAchievements` в `ReviewOutcome`. Тост в уроке — BL-81 | Done |
| BL-78 | P3 | Phase 16 — Smart Review v2: учитывать `grade` из review log (`last grade = again` → boost) | join с `review_logs` в `GetSmartReviewQueue` (или отдельный репозиторный метод), тест на boost и на отсутствие лога | Todo |
| BL-79 | P2 | Phase 17 — полное ревью остальных 2065 слов с `autoTranslated: true` (BL-21 закрыл только выборку 200) | warnings валидатора 2065 → 0; правки через `tools/manual_review_overrides.json`; `docs/LICENSE_CONTENT.md` обновлён | Todo |
| BL-81 | P3 | Phase 18b — тост достижения в уроке + тесты VO и экрана | `AchievementToast` через `Overlay` (slideY+fadeIn, автозакрытие 3 с, тап закрывает), показ после `RecordReview`, `achievement_test` (5), `achievements_screen_test` (2) | Done |
| BL-83 | P3 | Phase 20 — адаптивное число пар в Word Match по уровню CEFR (A1: 4 пары, C1: 12 пар) | `GenerateMemoryGame` получает `preferredLevel`; тест на границы; сетка подстраивается | Todo |
| BL-84 | P3 | Phase 20 — рекорды Word Match (лучшее число ходов/время) | таблица рекордов (схема v12) или `UserSettings`; экран рекордов; тест на обновление | Todo |
| BL-82 | P3 | Phase 19 — расширить набор достижений до 20–30 (первая сессия, 100 ответов, идеальная неделя) и убрать полный проход журнала в `perfect` | новые `AchievementType` с метриками; `perfect` считать инкрементально; тесты на каждый тип | Todo |
| BL-85 | P3 | Phase 22 — режим «60 секунд» в Typing Speed: максимум слов за минуту вместо фиксированных 10 | таймер на весь заезд, обратный отсчёт, отдельный рекорд в `typing_records`; тест на завершение по времени | Todo |
| BL-80 | P3 | Phase 17 — расширенный color picker (wheel) вместо 8 кружков + удаление категории из чипа словаря (иконка X, проверка «есть слова») | wheel или HSV-выбор цвета; чип с X для `id > 4`; подтверждение удаления; тест на запрет удаления категории со словами | Todo |

## Заметки
- Задача без критерия приёмки в бэклог не попадает.
- Долг, замеченный вне scope, добавляется сюда отдельной строкой, а не правится молча.
