# English Edu

Offline-first мобильное приложение для изучения английского
через интервальные повторения (SM-2).

## Status

**Phase 23 — Reading Mode** (6 игр + разговорник + чтение; 2071 слово,
209 фраз, 34 рассказа). APK собирается, iOS — нет. 836 тестов, analyze=0.

## Features

- Интервальные повторения (SM-2) с реальной моделью памяти
- Streak (серия дней)
- Swipe-карточки с TTS
- Личный словарь с поиском, добавлением и фильтром по уровню CEFR (A0–C2)
- 2071 слово по уровням A1–C1 в комплекте; новые слова подбираются по уровню
- Export/Import через clipboard
- Crash reporting (Sentry, опционально)
- Ежедневные локальные напоминания (точность ±5–15 минут)
- Уровень пользователя: новые слова подбираются не выше выбранного A0–C2
- Reading Mode: 34 рассказа A1/A2/B1, перевод по кнопке, незнакомые слова — в словарь
- Phrasebook: 209 фраз по категориям, поиск
- Typing Speed: тренировка печати, WPM и точность, локальные рекорды
- Achievements: 9 достижений за прогресс
- Daily Challenge: ежедневное задание и серия челленджей
- Smart Review: умное повторение трудных и давно не виденных слов
- Cloud Sync: Supabase, opt-in, ручной push/pull прогресса
- Полностью offline-first

## Environment

- Flutter 3.47.9 (stable)
- Dart 3.13.7
- Android minSdk 26 / compileSdk 36
- iOS deployment target 15.0 (SPM, CocoaPods не поддерживается)
- TTS: stts 1.3.4 (без Kotlin Gradle Plugin)

## How to run

    flutter pub get
    flutter run                # device/emulator
    flutter test               # 836 passed
    bash scripts/ci.sh         # CI

## Sentry (опционально)

DSN через --dart-define. Без DSN — NoOp.

    flutter build apk --dart-define=SENTRY_DSN=<url>

IP-адрес: отключить в Sentry Project Settings → Security & Privacy.

## Release build (Google Play)

### 1. Keystore (один раз)

```bash
keytool -genkey -v -keystore android/upload-keystore.jks \
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Пароли и путь **не коммитятся**: `android/key.properties` и `*.jks` добавлены в
`.gitignore`.

### 2. `android/key.properties`

Файл уже создан локально с плейсхолдерами — замените их:

```properties
storePassword=<пароль хранилища>
keyPassword=<пароль ключа>
keyAlias=upload
storeFile=../upload-keystore.jks
```

`storeFile` считается от `android/app/`, поэтому `../upload-keystore.jks` —
это `android/upload-keystore.jks`. Если храните файл в другом месте, укажите
абсолютный путь.

### 3. Сборка

```bash
flutter build appbundle --release   # AAB для Google Play
flutter build apk --release         # APK для внутренней беты
```

Без keystore сборка не падает: `build.gradle.kts` подставляет debug-ключ, чтобы
клонированный проект собирался без чужих секретов. Для магазина нужен реальный
ключ — подпись видна в `jarsigner -verify -verbose -certs`.

### 4. Иконки и splash

- `assets/icon.png` — 1024×1024; сейчас там сгенерированная заглушка («EE»),
  её нужно заменить настоящей квадратной картинкой.
- `dart run flutter_launcher_icons` — иконки Android/iOS.
- `dart run flutter_native_splash:create` — splash цвета `#E0F2F1`.

### 5. Privacy Policy

`docs/PRIVACY_POLICY.md` (EN + RU) — текст для страницы приложения в Play.

## AI Features

Подсказка-ассоциация к слову на карточке урока (ADR-019). Кнопка
«Подсказка» появляется после раскрытия перевода.

- Запрос идёт только по нажатию — урок, повторение и прогресс остаются офлайн.
- Прокси: `https://english-edu-ai.forses17.workers.dev/`; ключ модели живёт на
  сервере, в APK его нет.
- Без сети или при ошибке прокси — SnackBar «Не удалось загрузить подсказку»,
  карточка продолжает работать.
- На прокси уходит только само слово: ни прогресс, ни ответы, ни статистика.

## Error Hunter

Мини-игра «Охота на ошибки» (Phase 8): AI возвращает предложение с одной
ошибкой, пользователь находит слово и выбирает правильный вариант.

- Открывается с главного экрана кнопкой «Играть в Error Hunter».
- Неверный ответ не закрывает задание (красный SnackBar), верный — зелёный
  «Верно!» и кнопка «Следующее задание».
- Нет сети или прокси вернул мусор — состояние ошибки с кнопкой «Повторить».
- На прокси уходит только слово из словаря; прогресс не отправляется.

## Cloud sync (Supabase, опционально)

Локальная Drift-база остаётся источником истины: Supabase хранит копию
прогресса для бэкапа и переноса между устройствами (ADR-022). Без ключей
приложение работает офлайн, а в профиле секция «Синхронизация» честно пишет
«недоступна».

### 1. Таблица и RLS

Создайте проект в [Supabase](https://supabase.com) и выполните в SQL Editor:

```sql
create table public.user_progress (
  user_id uuid references auth.users not null,
  word_id integer not null,
  ease_permille integer not null,
  interval_days integer not null,
  repetitions integer not null,
  lapses integer not null,
  due_at_utc bigint not null,
  status text not null,
  first_seen_at_utc bigint not null,
  last_reviewed_at_utc bigint,
  updated_at_utc bigint not null,
  primary key (user_id, word_id)
);

alter table public.user_progress enable row level security;

create policy "own progress: select" on public.user_progress
  for select using (auth.uid() = user_id);
create policy "own progress: insert" on public.user_progress
  for insert with check (auth.uid() = user_id);
create policy "own progress: update" on public.user_progress
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own progress: delete" on public.user_progress
  for delete using (auth.uid() = user_id);
```

Время хранится в UTC как миллисекунды epoch (`bigint`): часовые пояса не
разъезжаются между устройствами.

### 2. Вход по email и возврат в приложение

1. Authentication → Providers → Email: включите.
2. Authentication → URL Configuration → Redirect URLs: добавьте
   `io.supabase.englishedu://login-callback/`.
3. Приложение уже объявляет эту схему в `AndroidManifest.xml`; SDK сам
   перехватывает ссылку и завершает вход.

### 3. Сборка с ключами

```bash
flutter build apk --debug \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

Ключи не попадают в репозиторий: anon key публичный по дизайну Supabase, но
привязан к проекту, поэтому передаётся только флагом сборки.

### 4. Поведение синхронизации

- `push` отправляет все локальные записи, `pull` забирает облачные и применяет
  только те, что новее локальных; `sync` делает оба шага.
- Конфликты разрешаются по времени изменения: побеждает более позднее
  `updated_at_utc`, равные метки не перезаписываются.
- Синхронизация ручная: кнопка «Синхронизировать сейчас» в профиле. Фоновой
  синхронизации нет — учебный цикл остаётся офлайновым.

## Architecture

- Presentation (Flutter) → Domain (pure Dart) → Data (Drift)
- 40 ADR + архитектурные решения — docs/DECISIONS.md
- Contracts — docs/ARCHITECTURE.md
- Dependency versions — ADR-007

## Roadmap

- [x] Phase 1–6: architecture, data, LessonScreen, TTS,
      dictionary, settings, Sentry, freeze, reminders.
- [x] Phase 6 APK build (debug собирается на Android SDK 36).
- [ ] Phase 6 iOS build (нужен macOS).
- [ ] Phase 7: публикация (Google Play, App Store).
- [x] Phase 8: AI-помощник (DeepSeek proxy).
- [x] Phase 12: облачная синхронизация прогресса (Supabase, опционально).

## Тестирование беты

### Как сообщить о баге

1. Воспроизведите сценарий.
2. Сделайте screenshot или screen recording.
3. Отправьте: <your-email>.

### Известные ограничения

- Напоминания неточные: ±5–15 минут (inexact alarm, BL-53).
- Release-APK не подписан: используется debug-ключ.
- iOS не собран (нет macOS).

### Что тестировать

- Пройти 10 карточек в уроке (свайп / кнопки).
- Добавить слово в словарь вручную.
- Export → сбросить прогресс → Import.
- Проверить streak (зайти 2 дня подряд).
- Сменить скорость TTS в ProfileScreen.

## License

Code: <не выбрана — BL-08>. Seed data: см. docs/LICENSE_CONTENT.md.
