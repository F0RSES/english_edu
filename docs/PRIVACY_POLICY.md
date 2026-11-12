# Privacy Policy / Политика конфиденциальности

**English Edu** — offline-first приложение для изучения английского.
Last updated / Обновлено: 2026-11-12.

---

## English

### What the app stores on your device

- **Vocabulary and progress.** Words you add, review history, daily counters,
  streaks and settings are stored locally in an SQLite database (Drift). This
  data never leaves your device unless you explicitly export it.
- **No analytics SDK.** The app contains no third-party analytics, advertising
  or tracking libraries. All statistics shown in the app are computed locally.

### What is sent over the network

- **AI associations (optional, opt-in by tap).** When you press the
  "Подсказка" (hint) button on a card, **the single word being studied** is sent
  to our proxy (`english-edu-ai.forses17.workers.dev`), which forwards it to the
  Alibaba Cloud Qwen (DashScope) model API to generate a mnemonic association.
  Nothing else is sent: no progress, no answers, no statistics, no identifiers.
  The generated association is cached locally. The proxy does not keep a
  permanent copy of the word or the answer; the model provider processes the
  request under its own terms.
- **Error Hunter game (optional, opt-in by opening the screen).** Same as above:
  one word from your dictionary is sent to generate a task.
- **Crash reports (optional).** If the build was configured with a Sentry DSN,
  crashes and errors are reported to Sentry. Reports contain the error, the stack
  trace and the app/platform version; `sendDefaultPii` is disabled, so no IP
  address, device name or user identifier is attached by the client.

### What we do not collect

- We do not collect your email address. The current version has no accounts and
  no sign-in. If an account feature is added later, this policy will be updated
  before it ships.
- We do not upload your vocabulary, review history or statistics to any server.
- We do not use advertising identifiers.

### Your control

- The app works fully offline; you can use it without any network request. AI
  features are the only network calls and they require your explicit action.
- Export creates a JSON snapshot of your data on your device — you decide where
  it goes.
- Deleting the app removes the local database.

### Contact

Questions about privacy: see the contact listed in the store page.

---

## Русский

### Что приложение хранит на устройстве

- **Словарь и прогресс.** Добавленные слова, история ответов, дневные
  счётчики, серия дней и настройки хранятся локально в базе SQLite (Drift). Эти
  данные не покидают устройство, пока вы сами не выгрузите их через экспорт.
- **Никакой аналитики.** В приложении нет сторонних аналитических,
  рекламных или трекинговых библиотек. Вся статистика на экранах считается
  локально.

### Что уходит по сети

- **AI-ассоциации (по желанию, по нажатию).** При нажатии кнопки «Подсказка»
  на карточке **единственное изучаемое слово** отправляется на наш прокси
  (`english-edu-ai.forses17.workers.dev`), который передаёт его модели
  Alibaba Cloud Qwen (DashScope) для генерации мнемонической ассоциации.
  Больше ничего не отправляется: ни прогресс, ни ответы, ни статистика,
  ни идентификаторы.
  Полученная ассоциация кэшируется локально. Прокси не хранит слово и ответ
  постоянно; обработка запроса у провайдера модели идёт по его правилам.
- **Игра «Охота на ошибки» (по желанию, при открытии экрана).** То же самое:
  одно слово из словаря отправляется для генерации задания.
- **Отчёты о сбоях (опционально).** Если сборка сконфигурирована с DSN Sentry,
  падения и ошибки уходят в Sentry. В отчёте — ошибка, стектрейс и версия
  приложения/платформы; `sendDefaultPii` выключен, поэтому клиент не прикладывает
  IP-адрес, имя устройства и идентификатор пользователя.

### Чего мы не собираем

- Мы не собираем адрес электронной почты. В текущей версии нет аккаунтов и
  входа. Если появится авторизация, политика будет обновлена до её выпуска.
- Мы не выгружаем словарь, историю ответов и статистику на серверы.
- Мы не используем рекламные идентификаторы.

### Ваш контроль

- Приложение полностью работает офлайн: им можно пользоваться без единого
  сетевого запроса. AI-функции — единственные сетевые вызовы, и они требуют
  явного действия.
- Экспорт создаёт JSON-снимок данных на устройстве — куда его отправлять,
  решаете вы.
- Удаление приложения удаляет локальную базу.

### Контакты

Вопросы по приватности: контакт указан на странице приложения в магазине.
