import 'package:english_edu/core/text/plural.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';
import 'package:english_edu/domain/value_objects/app_language.dart';
import 'package:english_edu/domain/value_objects/daily_challenge_type.dart';

/// Простые строки для локализации. Ключ → перевод.
///
/// При добавлении новой строки — обязательный перевод на оба языка.
/// Неизвестный ключ возвращается как есть — fallback для отладки.
/// Параметризованные строки хранятся с плейсхолдерами (`{n}`, `{a}`, `{b}`
/// и именными) и подставляются в методах, а не конкатенацией в UI.
final class S {
  const S._();

  static String _t(String key, AppLanguage lang) =>
      _data[key]?[lang.code] ?? key;

  // --- Общие ---
  /// Вкладка и заголовок «Главная».
  static String home(AppLanguage l) => _t('home', l);

  /// Вкладка и заголовок «Словарь».
  static String dictionary(AppLanguage l) => _t('dictionary', l);

  /// Вкладка и заголовок «Профиль».
  static String profile(AppLanguage l) => _t('profile', l);

  /// Заголовок настроек и tooltip шестерёнки.
  static String settings(AppLanguage l) => _t('settings', l);

  /// Tooltip кнопки «Назад».
  static String back(AppLanguage l) => _t('back', l);

  /// Надпись кнопки старта урока.
  static String startLesson(AppLanguage l) => _t('startLesson', l);

  /// Слово «слов» в строках счётчиков.
  static String words(AppLanguage l) => _t('words', l);

  /// Заголовок секции игр.
  static String games(AppLanguage l) => _t('games', l);

  /// Кнопка «Проверить».
  static String check(AppLanguage l) => _t('check', l);

  /// Кнопка «Далее».
  static String next(AppLanguage l) => _t('next', l);

  /// Сообщение «Неверно».
  static String incorrect(AppLanguage l) => _t('incorrect', l);

  /// Сообщение «Верно!».
  static String correct(AppLanguage l) => _t('correct', l);

  /// Заголовок листа помощника.
  static String explain(AppLanguage l) => _t('explain', l);

  /// Кнопка «Отмена».
  static String cancel(AppLanguage l) => _t('cancel', l);

  /// Кнопка «Повторить».
  static String retry(AppLanguage l) => _t('retry', l);

  /// Плейсхолдер загрузки.
  static String loading(AppLanguage l) => _t('loading', l);

  /// Ошибка сохранения настроек.
  static String saveFailed(AppLanguage l) => _t('saveFailed', l);

  /// Tooltip кнопки выбора языка.
  static String language(AppLanguage l) => _t('language', l);

  /// Tooltip селектора уровня.
  static String levelTooltip(AppLanguage l) => _t('levelTooltip', l);

  /// Надпись «Помощник» (FAB и профиль).
  static String assistant(AppLanguage l) => _t('assistant', l);

  // --- Главная ---
  /// Кнопка «Сложные (N)».
  static String weakWords(int count, AppLanguage l) =>
      _t('weakWords', l).replaceFirst('{n}', '$count');

  /// Кнопка «Smart (N)».
  static String smartReview(int count, AppLanguage l) =>
      _t('smartReview', l).replaceFirst('{n}', '$count');

  /// Подзаголовок кнопки при пустой очереди.
  static String allWordsLearned(AppLanguage l) => _t('allWordsLearned', l);

  /// Счётчик «N слов» с плюрализацией.
  static String wordCount(int count, AppLanguage l) =>
      '$count ${_wordForm(count, l)}';

  /// Название плитки игры по ключу.
  static String gameTitle(String game, AppLanguage l) => _t('game.$game', l);

  // --- Серия ---
  /// Призыв начать серию при нуле.
  static String streakStart(AppLanguage l) => _t('streak.start', l);

  /// «N дней подряд» с плюрализацией.
  static String daysInARow(int count, AppLanguage l) =>
      '${_dayForm(count, l)} ${_t('streak.inARow', l)}';

  /// Поздравление с 7 днями.
  static String milestone7(AppLanguage l) => _t('streak.milestone7', l);

  /// «🔥 N дней! Огонь» для вех 30/100.
  static String milestoneFire(int days, AppLanguage l) =>
      _t('streak.milestoneFire', l).replaceFirst('{n}', '$days');

  /// Поздравление с годом серии.
  static String milestone365(AppLanguage l) => _t('streak.milestone365', l);

  /// Остаток до первой вехи.
  static String untilMilestone(int remaining, AppLanguage l) => _t(
    'streak.until',
    l,
  ).replaceFirst('{n}', '$remaining ${_dayForm(remaining, l)}');

  /// Бейдж использованной заморозки.
  static String freezeUsed(AppLanguage l) => _t('streak.freezeUsed', l);

  // --- Дневная цель ---
  /// «A / B слов сегодня».
  static String wordsToday(int done, int total, AppLanguage l) => _t(
    'goal.wordsToday',
    l,
  ).replaceFirst('{a}', '$done').replaceFirst('{b}', '$total');

  // --- Ежедневное задание ---
  /// Текст задания дня по типу.
  static String challengeLabel(DailyChallengeType type, AppLanguage l) =>
      _t('challenge.${type.name}', l);

  /// Кнопка «Забрать +N XP».
  static String claimReward(int xp, AppLanguage l) =>
      _t('challenge.claim', l).replaceFirst('{n}', '$xp');

  /// Отметка выполненного задания.
  static String challengeDone(AppLanguage l) => _t('challenge.done', l);

  /// Ошибка получения награды.
  static String claimFailed(AppLanguage l) => _t('challenge.claimFailed', l);

  /// «Серия: N дней».
  static String challengeStreak(int days, AppLanguage l) => _t(
    'challenge.streak',
    l,
  ).replaceFirst('{n}', '$days ${_dayForm(days, l)}');

  /// «Лучший: N».
  static String bestStreak(int days, AppLanguage l) =>
      _t('challenge.best', l).replaceFirst('{n}', '$days');

  /// SnackBar «+N XP».
  static String xpGained(int xp, AppLanguage l) =>
      _t('xp.gained', l).replaceFirst('{n}', '$xp');

  // --- Профиль ---
  /// Подпись профиля по умолчанию.
  static String learner(AppLanguage l) => _t('profile.learner', l);

  /// «Уровень: X» в профиле.
  static String levelLabel(String level, AppLanguage l) =>
      _t('profile.level', l).replaceFirst('{level}', level);

  /// Метрика «Серия».
  static String statStreak(AppLanguage l) => _t('profile.streak', l);

  /// Метрика «Слов».
  static String statWords(AppLanguage l) => _t('profile.words', l);

  /// Метрика «XP».
  static String statXp(AppLanguage l) => _t('profile.xp', l);

  /// «Достижения (A/B)».
  static String achievementsHeader(int unlocked, int total, AppLanguage l) =>
      _t(
        'profile.achievements',
        l,
      ).replaceFirst('{a}', '$unlocked').replaceFirst('{b}', '$total');

  /// Ссылка «Все >».
  static String allAchievements(AppLanguage l) => _t('profile.all', l);

  /// Заглушка пустых достижений.
  static String noAchievements(AppLanguage l) =>
      _t('profile.noAchievements', l);

  /// Название достижения по ключу.
  static String achievementTitle(AchievementType type, AppLanguage l) =>
      _t('achievement.${type.key}', l);

  /// Описание достижения по ключу.
  static String achievementDescription(AchievementType type, AppLanguage l) =>
      _t('achievementDesc.${type.key}', l);

  // --- Аналитика ---
  /// Ошибка загрузки аналитики.
  static String analyticsFailed(AppLanguage l) => _t('analytics.failed', l);

  /// Плитка «Всего».
  static String metricTotal(AppLanguage l) => _t('analytics.total', l);

  /// Плитка «Выучено».
  static String metricMastered(AppLanguage l) => _t('analytics.mastered', l);

  /// Плитка «Изучаю».
  static String metricLearning(AppLanguage l) => _t('analytics.learning', l);

  /// Плитка «Новые».
  static String metricNew(AppLanguage l) => _t('analytics.new', l);

  /// Заголовок графика за неделю.
  static String last7Days(AppLanguage l) => _t('analytics.last7', l);

  /// Заголовок списка трудных слов.
  static String hardWords(AppLanguage l) => _t('analytics.hard', l);

  /// Заглушка отсутствия провалов.
  static String noLapses(AppLanguage l) => _t('analytics.noLapses', l);

  /// «N провалов» с плюрализацией.
  static String lapsesCount(int count, AppLanguage l) =>
      '$count ${_lapseForm(count, l)}';

  /// Прогноз без даты.
  static String projectionNone(AppLanguage l) =>
      _t('analytics.projectionNone', l);

  /// Прогноз с датой DD.MM.YYYY.
  static String projectionDate(String date, AppLanguage l) =>
      _t('analytics.projection', l).replaceFirst('{d}', date);

  /// Короткое имя дня недели (1–7).
  static String weekday(int weekday, AppLanguage l) =>
      _t('weekday.$weekday', l);

  // --- Настройки ---
  /// Секция дневных лимитов.
  static String dailyLimits(AppLanguage l) => _t('settings.dailyLimits', l);

  /// Лимит новых слов.
  static String newPerDay(AppLanguage l) => _t('settings.newPerDay', l);

  /// Лимит повторений.
  static String reviewsPerDay(AppLanguage l) => _t('settings.reviewsPerDay', l);

  /// Секция озвучки.
  static String ttsSection(AppLanguage l) => _t('settings.tts', l);

  /// Выбор голоса.
  static String voice(AppLanguage l) => _t('settings.voice', l);

  /// Скорость речи.
  static String speechRate(AppLanguage l) => _t('settings.speechRate', l);

  /// Ошибка озвучки.
  static String ttsFailed(AppLanguage l) => _t('settings.ttsFailed', l);

  /// Секция резервной копии.
  static String backupSection(AppLanguage l) => _t('settings.backup', l);

  /// Пункт «Достижения».
  static String achievementsTile(AppLanguage l) =>
      _t('settings.achievements', l);

  /// Подпись пункта достижений.
  static String achievementsSubtitle(AppLanguage l) =>
      _t('settings.achievementsSubtitle', l);

  /// Пункт управления категориями.
  static String categoriesTile(AppLanguage l) => _t('settings.categories', l);

  /// Подпись пункта категорий.
  static String categoriesSubtitle(AppLanguage l) =>
      _t('settings.categoriesSubtitle', l);

  /// SnackBar создания категории.
  static String categoryCreated(String name, AppLanguage l) =>
      _t('settings.categoryCreated', l).replaceFirst('{name}', name);

  /// Пункт «Экспорт».
  static String exportTile(AppLanguage l) => _t('settings.export', l);

  /// Подпись экспорта.
  static String exportSubtitle(AppLanguage l) =>
      _t('settings.exportSubtitle', l);

  /// Пункт «Импорт».
  static String importTile(AppLanguage l) => _t('settings.import', l);

  /// Подпись импорта.
  static String importSubtitle(AppLanguage l) =>
      _t('settings.importSubtitle', l);

  /// SnackBar успешного импорта.
  static String importDone(AppLanguage l) => _t('settings.importDone', l);

  /// Секция синхронизации.
  static String cloudSection(AppLanguage l) => _t('settings.cloud', l);

  /// Синхронизация без ключей.
  static String cloudUnavailable(AppLanguage l) =>
      _t('settings.cloudUnavailable', l);

  /// Подпись об отсутствии ключей.
  static String cloudNoKeys(AppLanguage l) => _t('settings.cloudNoKeys', l);

  /// Кнопка входа по email.
  static String signIn(AppLanguage l) => _t('settings.signIn', l);

  /// Подпись кнопки входа.
  static String signInSubtitle(AppLanguage l) =>
      _t('settings.signInSubtitle', l);

  /// Кнопка синхронизации.
  static String syncNow(AppLanguage l) => _t('settings.syncNow', l);

  /// Tooltip выхода из облака.
  static String signOut(AppLanguage l) => _t('settings.signOut', l);

  /// Итог синхронизации «Отправлено A, получено B».
  static String syncResult(int pushed, int pulled, AppLanguage l) => _t(
    'settings.syncResult',
    l,
  ).replaceFirst('{a}', '$pushed').replaceFirst('{b}', '$pulled');

  /// Ошибка синхронизации.
  static String syncFailed(AppLanguage l) => _t('settings.syncFailed', l);

  /// Magic link отправлен.
  static String linkSent(String email, AppLanguage l) =>
      _t('settings.linkSent', l).replaceFirst('{email}', email);

  /// Ошибка отправки ссылки.
  static String linkFailed(AppLanguage l) => _t('settings.linkFailed', l);

  /// Секция опасных действий.
  static String dangerZone(AppLanguage l) => _t('settings.dangerZone', l);

  /// Пункт сброса прогресса.
  static String resetTile(AppLanguage l) => _t('settings.reset', l);

  /// Подпись сброса.
  static String resetSubtitle(AppLanguage l) => _t('settings.resetSubtitle', l);

  /// Заголовок подтверждения сброса.
  static String resetConfirmTitle(AppLanguage l) =>
      _t('settings.resetConfirmTitle', l);

  /// Текст подтверждения сброса.
  static String resetConfirmBody(AppLanguage l) =>
      _t('settings.resetConfirmBody', l);

  /// Кнопка подтверждения сброса.
  static String resetConfirm(AppLanguage l) => _t('settings.resetConfirm', l);

  /// SnackBar успешного сброса.
  static String resetDone(AppLanguage l) => _t('settings.resetDone', l);

  /// Ошибка сброса.
  static String resetFailed(AppLanguage l) => _t('settings.resetFailed', l);

  /// Пункт онбординга.
  static String howItWorks(AppLanguage l) => _t('settings.howItWorks', l);

  /// Подпись пункта онбординга.
  static String onboardingTile(AppLanguage l) => _t('settings.onboarding', l);

  /// Секция аналитики.
  static String analyticsSection(AppLanguage l) => _t('settings.analytics', l);

  /// Секция напоминаний.
  static String remindersSection(AppLanguage l) => _t('settings.reminders', l);

  /// Переключатель напоминаний.
  static String remindersToggle(AppLanguage l) =>
      _t('settings.remindersToggle', l);

  /// «Ежедневно в HH:MM».
  static String remindersDaily(String time, AppLanguage l) =>
      _t('settings.remindersDaily', l).replaceFirst('{time}', time);

  /// Напоминания выключены.
  static String remindersOff(AppLanguage l) => _t('settings.remindersOff', l);

  /// Пункт времени напоминания.
  static String reminderTime(AppLanguage l) => _t('settings.reminderTime', l);

  /// Ошибка обновления напоминания.
  static String reminderFailed(AppLanguage l) =>
      _t('settings.reminderFailed', l);

  /// Ошибка загрузки настроек.
  static String settingsLoadFailed(AppLanguage l) =>
      _t('settings.loadFailed', l);

  /// Заголовок email-диалога.
  static String emailTitle(AppLanguage l) => _t('email.title', l);

  /// Поле email.
  static String emailLabel(AppLanguage l) => _t('email.label', l);

  /// Ошибка формата email.
  static String emailCheck(AppLanguage l) => _t('email.check', l);

  /// Кнопка отправки ссылки.
  static String emailSend(AppLanguage l) => _t('email.send', l);

  // --- Словарь ---
  /// Плейсхолдер поиска.
  static String searchHint(AppLanguage l) => _t('dictionary.search', l);

  /// Tooltip добавления слова.
  static String addWordTooltip(AppLanguage l) => _t('dictionary.add', l);

  /// SnackBar добавления.
  static String wordAdded(AppLanguage l) => _t('dictionary.added', l);

  /// Вкладка «Все».
  static String tabAll(AppLanguage l) => _t('dictionary.all', l);

  /// Вкладка «Изучаю».
  static String tabLearning(AppLanguage l) => _t('dictionary.learning', l);

  /// Вкладка «Выучено».
  static String tabMastered(AppLanguage l) => _t('dictionary.mastered', l);

  /// Чип «Все категории».
  static String allCategories(AppLanguage l) =>
      _t('dictionary.allCategories', l);

  /// Чип «Все уровни».
  static String allLevels(AppLanguage l) => _t('dictionary.allLevels', l);

  /// Пустой результат поиска.
  static String emptySearch(AppLanguage l) => _t('dictionary.emptySearch', l);

  /// Пустая категория.
  static String emptyCategory(AppLanguage l) =>
      _t('dictionary.emptyCategory', l);

  /// Пустой уровень.
  static String emptyLevel(AppLanguage l) => _t('dictionary.emptyLevel', l);

  /// Пустая вкладка.
  static String emptyTab(AppLanguage l) => _t('dictionary.emptyTab', l);

  /// Пустой словарь.
  static String emptyDictionary(AppLanguage l) => _t('dictionary.empty', l);

  /// Ошибка загрузки словаря.
  static String dictionaryLoadFailed(AppLanguage l) =>
      _t('dictionary.loadFailed', l);

  /// Чип статуса «новое».
  static String statusNew(AppLanguage l) => _t('wordStatus.new', l);

  /// Чип статуса «изучаю».
  static String statusLearning(AppLanguage l) => _t('wordStatus.learning', l);

  /// Чип статуса «выучено».
  static String statusMastered(AppLanguage l) => _t('wordStatus.mastered', l);

  /// Нет примера употребления.
  static String noExample(AppLanguage l) => _t('word.noExample', l);

  /// Подпись «Без категории».
  static String noCategory(AppLanguage l) => _t('noCategory', l);

  // --- Диалог добавления слова ---
  /// Заголовок диалога добавления.
  static String addWordTitle(AppLanguage l) => _t('addWord.title', l);

  /// Поле «Слово».
  static String fieldTerm(AppLanguage l) => _t('addWord.term', l);

  /// Поле «Перевод».
  static String fieldTranslation(AppLanguage l) => _t('addWord.translation', l);

  /// Поле «Транскрипция».
  static String fieldTranscription(AppLanguage l) =>
      _t('addWord.transcription', l);

  /// Поле «Часть речи».
  static String fieldPartOfSpeech(AppLanguage l) =>
      _t('addWord.partOfSpeech', l);

  /// Поле «Категория».
  static String fieldCategory(AppLanguage l) => _t('addWord.category', l);

  /// Поле «Уровень».
  static String fieldLevel(AppLanguage l) => _t('addWord.level', l);

  /// Поле «Пример».
  static String fieldExample(AppLanguage l) => _t('addWord.example', l);

  /// Кнопка «Добавить».
  static String addWordAction(AppLanguage l) => _t('addWord.add', l);

  /// Ошибка пустого слова.
  static String enterTerm(AppLanguage l) => _t('addWord.enterTerm', l);

  /// Ошибка пустого перевода.
  static String enterTranslation(AppLanguage l) =>
      _t('addWord.enterTranslation', l);

  /// Ошибка сохранения слова.
  static String wordSaveFailed(AppLanguage l) => _t('addWord.saveFailed', l);

  /// Заголовок диалога гомонима.
  static String wordExists(String term, AppLanguage l) =>
      _t('addWord.exists', l).replaceFirst('{term}', term);

  /// Подпись существующих значений.
  static String existingSenses(AppLanguage l) =>
      _t('addWord.existingSenses', l);

  /// Вопрос о новом значении.
  static String addAnotherSense(AppLanguage l) => _t('addWord.addAnother', l);

  /// Кнопка «Добавить как новое».
  static String addAsNew(AppLanguage l) => _t('addWord.addAsNew', l);

  /// Пункт создания категории.
  static String createCategoryOption(AppLanguage l) =>
      _t('addWord.createCategory', l);

  // --- Экспорт / импорт ---
  /// SnackBar копирования.
  static String copiedToClipboard(AppLanguage l) => _t('export.copied', l);

  /// Ошибка копирования.
  static String copyFailed(AppLanguage l) => _t('export.copyFailed', l);

  /// Кнопка «Закрыть».
  static String close(AppLanguage l) => _t('export.close', l);

  /// Кнопка «Скопировать».
  static String copy(AppLanguage l) => _t('export.copy', l);

  /// Ошибка сборки снимка.
  static String exportBuildFailed(AppLanguage l) => _t('export.buildFailed', l);

  /// Ошибка разбора JSON.
  static String invalidJson(String message, AppLanguage l) =>
      _t('import.invalidJson', l).replaceFirst('{msg}', message);

  /// Неподдерживаемая версия снимка.
  static String unsupportedVersion(int version, AppLanguage l) =>
      _t('import.unsupportedVersion', l).replaceFirst('{n}', '$version');

  /// Подтверждение замены данных.
  static String importConfirmBody(AppLanguage l) => _t('import.confirmBody', l);

  /// Кнопка «Продолжить».
  static String importContinue(AppLanguage l) => _t('import.continue', l);

  /// Подпись поля вставки.
  static String importPaste(AppLanguage l) => _t('import.paste', l);

  /// Кнопка «Импортировать».
  static String importAction(AppLanguage l) => _t('import.action', l);

  /// Ошибка импорта.
  static String importFailed(AppLanguage l) => _t('import.failed', l);

  // --- Диалог категории ---
  /// Заголовок диалога категории.
  static String newCategory(AppLanguage l) => _t('category.new', l);

  /// Поле названия.
  static String categoryName(AppLanguage l) => _t('category.name', l);

  /// Подпись выбора цвета.
  static String categoryColor(AppLanguage l) => _t('category.color', l);

  /// Кнопка «Создать».
  static String categoryCreate(AppLanguage l) => _t('category.create', l);

  /// Ошибка дубля категории.
  static String categoryExists(AppLanguage l) => _t('category.exists', l);

  /// Ошибка создания категории.
  static String categoryCreateFailed(AppLanguage l) =>
      _t('category.createFailed', l);

  // --- Урок ---
  /// Заголовок урока.
  static String lessonTitle(AppLanguage l) => _t('lesson.title', l);

  /// Заголовок режима сложных слов.
  static String lessonWeak(AppLanguage l) => _t('lesson.weak', l);

  /// Заголовок умного повторения.
  static String lessonSmart(AppLanguage l) => _t('lesson.smart', l);

  /// Заголовок подтверждения выхода.
  static String exitTitle(AppLanguage l) => _t('lesson.exitTitle', l);

  /// Текст подтверждения выхода.
  static String exitBody(AppLanguage l) => _t('lesson.exitBody', l);

  /// Кнопка «Выйти».
  static String exitAction(AppLanguage l) => _t('lesson.exit', l);

  /// Ошибка сохранения ответа.
  static String answerSaveFailed(AppLanguage l) => _t('lesson.saveFailed', l);

  /// Ошибка загрузки очереди.
  static String queueLoadFailed(AppLanguage l) => _t('lesson.queueFailed', l);

  /// Очередь на сегодня пуста.
  static String allDoneForToday(AppLanguage l) => _t('lesson.allDone', l);

  /// Кнопка «Не знаю».
  static String dontKnow(AppLanguage l) => _t('lesson.dontKnow', l);

  /// Кнопка «Знаю».
  static String know(AppLanguage l) => _t('lesson.know', l);

  // --- Итоги сессии и тост ---
  /// Заголовок итогов.
  static String sessionDone(AppLanguage l) => _t('session.done', l);

  /// «Верно: A из B».
  static String sessionCorrect(int correct, int total, AppLanguage l) => _t(
    'session.correct',
    l,
  ).replaceFirst('{a}', '$correct').replaceFirst('{b}', '$total');

  /// «XP: N».
  static String sessionXp(int xp, AppLanguage l) =>
      _t('session.xp', l).replaceFirst('{n}', '$xp');

  /// Кнопка «Готово».
  static String sessionFinish(AppLanguage l) => _t('session.finish', l);

  /// Шапка тоста достижения.
  static String achievementToast(AppLanguage l) => _t('toast.achievement', l);

  // --- Карточка слова и помощник ---
  /// Подсказка до раскрытия карточки.
  static String tapToReveal(AppLanguage l) => _t('wordCard.tapToReveal', l);

  /// Tooltip озвучки.
  static String speakTooltip(AppLanguage l) => _t('wordCard.speak', l);

  /// Кнопка AI-подсказки.
  static String hint(AppLanguage l) => _t('wordCard.hint', l);

  /// Ошибка загрузки подсказки.
  static String hintFailed(AppLanguage l) => _t('wordCard.hintFailed', l);

  /// Tooltip кнопки помощника.
  static String askAssistant(AppLanguage l) => _t('helper.ask', l);

  /// Кнопка «Понятно».
  static String gotIt(AppLanguage l) => _t('helper.gotIt', l);

  /// Ошибка получения объяснения.
  static String explainFailed(AppLanguage l) => _t('helper.failed', l);

  // --- Плюрализация ---
  static String _dayForm(int count, AppLanguage l) => pluralize(
    count,
    one: _t('day.one', l),
    few: _t('day.few', l),
    many: _t('day.many', l),
  );

  static String _wordForm(int count, AppLanguage l) => pluralize(
    count,
    one: _t('word.one', l),
    few: _t('word.few', l),
    many: _t('word.many', l),
  );

  static String _lapseForm(int count, AppLanguage l) => pluralize(
    count,
    one: _t('lapse.one', l),
    few: _t('lapse.few', l),
    many: _t('lapse.many', l),
  );

  static const _data = <String, Map<String, String>>{
    // Общие.
    'home': {'ru': 'Главная', 'en': 'Home'},
    'dictionary': {'ru': 'Словарь', 'en': 'Dictionary'},
    'profile': {'ru': 'Профиль', 'en': 'Profile'},
    'settings': {'ru': 'Настройки', 'en': 'Settings'},
    'back': {'ru': 'Назад', 'en': 'Back'},
    'startLesson': {'ru': 'Начать урок', 'en': 'Start lesson'},
    'words': {'ru': 'слов', 'en': 'words'},
    'games': {'ru': 'Игры', 'en': 'Games'},
    'check': {'ru': 'Проверить', 'en': 'Check'},
    'next': {'ru': 'Далее', 'en': 'Next'},
    'incorrect': {'ru': 'Неверно', 'en': 'Wrong'},
    'correct': {'ru': 'Верно!', 'en': 'Correct!'},
    'explain': {'ru': 'Помощник объясняет', 'en': 'Assistant explains'},
    'cancel': {'ru': 'Отмена', 'en': 'Cancel'},
    'retry': {'ru': 'Повторить', 'en': 'Retry'},
    'loading': {'ru': 'Загрузка…', 'en': 'Loading…'},
    'saveFailed': {
      'ru': 'Не удалось сохранить настройки',
      'en': 'Failed to save settings',
    },
    'language': {'ru': 'Язык', 'en': 'Language'},
    'levelTooltip': {'ru': 'Уровень английского', 'en': 'English level'},
    'assistant': {'ru': 'Помощник', 'en': 'Assistant'},
    // Главная.
    'weakWords': {'ru': 'Сложные ({n})', 'en': 'Weak ({n})'},
    'smartReview': {'ru': 'Smart ({n})', 'en': 'Smart ({n})'},
    'allWordsLearned': {'ru': 'Все слова изучены', 'en': 'All words learned'},
    'word.one': {'ru': 'слово', 'en': 'word'},
    'word.few': {'ru': 'слова', 'en': 'words'},
    'word.many': {'ru': 'слов', 'en': 'words'},
    'game.errorHunter': {'ru': 'Error Hunter', 'en': 'Error Hunter'},
    'game.cloze': {'ru': 'Пропуск', 'en': 'Gap fill'},
    'game.scramble': {'ru': 'Собери слово', 'en': 'Word Scramble'},
    'game.memory': {'ru': 'Memory', 'en': 'Memory'},
    'game.typing': {'ru': 'Typing', 'en': 'Typing'},
    'game.phrasebook': {'ru': 'Разговорник', 'en': 'Phrasebook'},
    'game.dictation': {'ru': 'Диктант', 'en': 'Dictation'},
    'game.reading': {'ru': 'Чтение', 'en': 'Reading'},
    // Серия.
    'streak.start': {
      'ru': 'Начни серию сегодня',
      'en': 'Start your streak today',
    },
    'streak.inARow': {'ru': 'подряд', 'en': 'in a row'},
    'day.one': {'ru': 'день', 'en': 'day'},
    'day.few': {'ru': 'дня', 'en': 'days'},
    'day.many': {'ru': 'дней', 'en': 'days'},
    'streak.milestone7': {
      'ru': '🎉 7 дней! Молодец',
      'en': '🎉 7 days! Well done',
    },
    'streak.milestoneFire': {
      'ru': '🔥 {n} дней! Огонь',
      'en': '🔥 {n} days! On fire',
    },
    'streak.milestone365': {
      'ru': '🎉 365 дней подряд!',
      'en': '🎉 365 days in a row!',
    },
    'streak.until': {'ru': 'До 7 дней: {n}', 'en': '{n} to 7 days'},
    'streak.freezeUsed': {'ru': 'Freeze использован', 'en': 'Freeze used'},
    // Дневная цель.
    'goal.wordsToday': {
      'ru': '{a} / {b} слов сегодня',
      'en': '{a} / {b} words today',
    },
    // Ежедневное задание.
    'challenge.review20': {'ru': 'Повтори 20 слов', 'en': 'Review 20 words'},
    'challenge.streak10': {
      'ru': 'Серия из 10 верных',
      'en': '10 correct in a row',
    },
    'challenge.new5': {'ru': 'Выучи 5 новых слов', 'en': 'Learn 5 new words'},
    'challenge.noMistakes': {
      'ru': '10 без ошибок',
      'en': '10 without mistakes',
    },
    'challenge.claim': {'ru': 'Забрать +{n} XP', 'en': 'Claim +{n} XP'},
    'challenge.done': {'ru': '✓ Выполнено', 'en': '✓ Completed'},
    'challenge.claimFailed': {
      'ru': 'Не удалось забрать награду',
      'en': 'Failed to claim reward',
    },
    'challenge.streak': {'ru': 'Серия: {n}', 'en': 'Streak: {n}'},
    'challenge.best': {'ru': 'Лучший: {n}', 'en': 'Best: {n}'},
    'xp.gained': {'ru': '+{n} XP', 'en': '+{n} XP'},
    // Профиль.
    'profile.learner': {'ru': 'Learner', 'en': 'Learner'},
    'profile.level': {'ru': 'Уровень: {level}', 'en': 'Level: {level}'},
    'profile.streak': {'ru': 'Серия', 'en': 'Streak'},
    'profile.words': {'ru': 'Слов', 'en': 'Words'},
    'profile.xp': {'ru': 'XP', 'en': 'XP'},
    'profile.achievements': {
      'ru': 'Достижения ({a}/{b})',
      'en': 'Achievements ({a}/{b})',
    },
    'profile.all': {'ru': 'Все >', 'en': 'All >'},
    'profile.noAchievements': {
      'ru': 'Пока нет достижений. Выполняй задания!',
      'en': 'No achievements yet. Complete challenges!',
    },
    // Достижения (ключи AchievementType.key).
    'achievement.streak_7': {'ru': '7 дней подряд', 'en': '7-day streak'},
    'achievement.streak_30': {'ru': '30 дней подряд', 'en': '30-day streak'},
    'achievement.streak_100': {'ru': '100 дней!', 'en': '100 days!'},
    'achievement.words_100': {'ru': '100 слов', 'en': '100 words'},
    'achievement.words_500': {'ru': '500 слов', 'en': '500 words'},
    'achievement.words_1000': {'ru': '1000 слов!', 'en': '1000 words!'},
    'achievement.perfect_10': {
      'ru': '10 верных подряд',
      'en': '10 correct in a row',
    },
    'achievement.perfect_50': {
      'ru': '50 верных подряд',
      'en': '50 correct in a row',
    },
    'achievement.daily_7': {'ru': '7 челленджей', 'en': '7 challenges'},
    'achievement.first_lesson': {'ru': 'Первый урок', 'en': 'First lesson'},
    'achievement.answers_100': {'ru': '100 ответов', 'en': '100 answers'},
    'achievement.answers_500': {'ru': '500 ответов', 'en': '500 answers'},
    'achievement.answers_1000': {'ru': '1000 ответов', 'en': '1000 answers'},
    'achievement.answers_5000': {'ru': '5000 ответов', 'en': '5000 answers'},
    'achievement.correct_100': {'ru': '100 верных', 'en': '100 correct'},
    'achievement.correct_500': {'ru': '500 верных', 'en': '500 correct'},
    'achievement.streak_14': {'ru': '14 дней подряд', 'en': '14-day streak'},
    'achievement.streak_60': {'ru': '60 дней подряд', 'en': '60-day streak'},
    'achievement.streak_365': {'ru': '365 дней!', 'en': '365 days!'},
    'achievement.words_2000': {'ru': '2000 слов', 'en': '2000 words'},
    'achievement.words_5000': {'ru': '5000 слов!', 'en': '5000 words!'},
    'achievement.perfect_100': {
      'ru': '100 верных подряд',
      'en': '100 correct in a row',
    },
    'achievement.daily_30': {'ru': '30 челленджей', 'en': '30 challenges'},
    'achievement.xp_1000': {'ru': '1000 XP', 'en': '1000 XP'},
    'achievement.xp_5000': {'ru': '5000 XP', 'en': '5000 XP'},
    'achievement.xp_10000': {'ru': '10000 XP!', 'en': '10000 XP!'},
    'achievement.chat_10': {'ru': '10 сообщений', 'en': '10 messages'},
    'achievement.chat_50': {'ru': '50 сообщений', 'en': '50 messages'},
    'achievement.chat_100': {'ru': '100 сообщений', 'en': '100 messages'},
    'achievement.typing_10': {'ru': '10 заездов', 'en': '10 runs'},
    // Описания достижений (тост; ключи AchievementType.key).
    'achievementDesc.streak_7': {
      'ru': 'Заходил 7 дней подряд',
      'en': 'Visited 7 days in a row',
    },
    'achievementDesc.streak_30': {
      'ru': 'Месяц без пропусков',
      'en': 'A month without skips',
    },
    'achievementDesc.streak_100': {'ru': 'Легенда', 'en': 'Legend'},
    'achievementDesc.words_100': {
      'ru': 'Изучил 100 слов',
      'en': 'Learned 100 words',
    },
    'achievementDesc.words_500': {
      'ru': 'Половина пути до 1000',
      'en': 'Halfway to 1000',
    },
    'achievementDesc.words_1000': {
      'ru': 'Мастер словаря',
      'en': 'Vocabulary master',
    },
    'achievementDesc.perfect_10': {'ru': 'Без ошибок', 'en': 'No mistakes'},
    'achievementDesc.perfect_50': {
      'ru': 'Идеальная серия',
      'en': 'Perfect streak',
    },
    'achievementDesc.daily_7': {
      'ru': 'Неделя челленджей',
      'en': 'A week of challenges',
    },
    'achievementDesc.first_lesson': {
      'ru': 'Начало пути',
      'en': 'The journey begins',
    },
    'achievementDesc.answers_100': {
      'ru': 'Сотня позади',
      'en': 'A hundred behind you',
    },
    'achievementDesc.answers_500': {
      'ru': 'Полтысячи!',
      'en': 'Half a thousand!',
    },
    'achievementDesc.answers_1000': {
      'ru': 'Тысяча слов сказано',
      'en': 'A thousand words said',
    },
    'achievementDesc.answers_5000': {'ru': 'Неудержимый', 'en': 'Unstoppable'},
    'achievementDesc.correct_100': {
      'ru': 'Сотня правильных',
      'en': 'A hundred correct',
    },
    'achievementDesc.correct_500': {
      'ru': 'Меткий стрелок',
      'en': 'Sharpshooter',
    },
    'achievementDesc.streak_14': {
      'ru': 'Две недели без пропусков',
      'en': 'Two weeks without skips',
    },
    'achievementDesc.streak_60': {'ru': 'Два месяца!', 'en': 'Two months!'},
    'achievementDesc.streak_365': {'ru': 'Целый год', 'en': 'A whole year'},
    'achievementDesc.words_2000': {'ru': 'Две тысячи!', 'en': 'Two thousand!'},
    'achievementDesc.words_5000': {'ru': 'Полиглот', 'en': 'Polyglot'},
    'achievementDesc.perfect_100': {'ru': 'Безупречно', 'en': 'Flawless'},
    'achievementDesc.daily_30': {
      'ru': 'Месяц заданий',
      'en': 'A month of challenges',
    },
    'achievementDesc.xp_1000': {
      'ru': 'Первая тысяча опыта',
      'en': 'First thousand XP',
    },
    'achievementDesc.xp_5000': {
      'ru': 'Опытный боец',
      'en': 'Experienced fighter',
    },
    'achievementDesc.xp_10000': {'ru': 'Легенда опыта', 'en': 'XP legend'},
    'achievementDesc.chat_10': {'ru': 'Первый диалог', 'en': 'First dialogue'},
    'achievementDesc.chat_50': {'ru': 'Общительный', 'en': 'Chatty'},
    'achievementDesc.chat_100': {
      'ru': 'Душа компании',
      'en': 'Life of the party',
    },
    'achievementDesc.typing_10': {'ru': 'Быстрые пальцы', 'en': 'Fast fingers'},
    // Аналитика.
    'analytics.failed': {
      'ru': 'Не удалось загрузить аналитику',
      'en': 'Failed to load analytics',
    },
    'analytics.total': {'ru': 'Всего', 'en': 'Total'},
    'analytics.mastered': {'ru': 'Выучено', 'en': 'Mastered'},
    'analytics.learning': {'ru': 'Изучаю', 'en': 'Learning'},
    'analytics.new': {'ru': 'Новые', 'en': 'New'},
    'analytics.last7': {'ru': 'За 7 дней', 'en': 'Last 7 days'},
    'analytics.hard': {'ru': 'Трудные слова', 'en': 'Hard words'},
    'analytics.noLapses': {'ru': 'Пока нет провалов', 'en': 'No lapses yet'},
    'lapse.one': {'ru': 'провал', 'en': 'lapse'},
    'lapse.few': {'ru': 'провала', 'en': 'lapses'},
    'lapse.many': {'ru': 'провалов', 'en': 'lapses'},
    'analytics.projectionNone': {
      'ru': 'Прогноз mastery: —',
      'en': 'Mastery projection: —',
    },
    'analytics.projection': {
      'ru': 'Все слова mastered к {d}',
      'en': 'All words mastered by {d}',
    },
    'weekday.1': {'ru': 'Пн', 'en': 'Mon'},
    'weekday.2': {'ru': 'Вт', 'en': 'Tue'},
    'weekday.3': {'ru': 'Ср', 'en': 'Wed'},
    'weekday.4': {'ru': 'Чт', 'en': 'Thu'},
    'weekday.5': {'ru': 'Пт', 'en': 'Fri'},
    'weekday.6': {'ru': 'Сб', 'en': 'Sat'},
    'weekday.7': {'ru': 'Вс', 'en': 'Sun'},
    // Настройки.
    'settings.dailyLimits': {'ru': 'Дневные лимиты', 'en': 'Daily limits'},
    'settings.newPerDay': {
      'ru': 'Новых слов в день',
      'en': 'New words per day',
    },
    'settings.reviewsPerDay': {
      'ru': 'Повторений в день',
      'en': 'Reviews per day',
    },
    'settings.tts': {'ru': 'Озвучка', 'en': 'TTS'},
    'settings.voice': {'ru': 'Голос', 'en': 'Voice'},
    'settings.speechRate': {'ru': 'Скорость речи', 'en': 'Speech rate'},
    'settings.ttsFailed': {'ru': 'Озвучка недоступна', 'en': 'TTS unavailable'},
    'settings.backup': {'ru': 'Резервная копия', 'en': 'Backup'},
    'settings.achievements': {'ru': 'Достижения', 'en': 'Achievements'},
    'settings.achievementsSubtitle': {
      'ru': 'Серии, слова, идеальные ответы',
      'en': 'Streaks, words, perfect answers',
    },
    'settings.categories': {
      'ru': 'Управление категориями',
      'en': 'Manage categories',
    },
    'settings.categoriesSubtitle': {
      'ru': 'Создать свою категорию',
      'en': 'Create your own category',
    },
    'settings.categoryCreated': {
      'ru': 'Категория «{name}» создана',
      'en': 'Category "{name}" created',
    },
    'settings.export': {'ru': 'Экспорт', 'en': 'Export'},
    'settings.exportSubtitle': {
      'ru': 'JSON в буфер обмена',
      'en': 'JSON to clipboard',
    },
    'settings.import': {'ru': 'Импорт', 'en': 'Import'},
    'settings.importSubtitle': {
      'ru': 'Вставить JSON из буфера',
      'en': 'Paste JSON from clipboard',
    },
    'settings.importDone': {
      'ru': 'Данные импортированы',
      'en': 'Data imported',
    },
    'settings.cloud': {'ru': 'Синхронизация', 'en': 'Cloud sync'},
    'settings.cloudUnavailable': {
      'ru': 'Синхронизация недоступна',
      'en': 'Sync unavailable',
    },
    'settings.cloudNoKeys': {
      'ru': 'Ключи Supabase не переданы при сборке',
      'en': 'Supabase keys were not provided at build time',
    },
    'settings.signIn': {'ru': 'Войти через Email', 'en': 'Sign in with Email'},
    'settings.signInSubtitle': {
      'ru': 'Пришлём ссылку для входа',
      'en': 'We will send a sign-in link',
    },
    'settings.syncNow': {'ru': 'Синхронизировать сейчас', 'en': 'Sync now'},
    'settings.signOut': {'ru': 'Выйти', 'en': 'Sign out'},
    'settings.syncResult': {
      'ru': 'Отправлено {a}, получено {b}',
      'en': 'Sent {a}, received {b}',
    },
    'settings.syncFailed': {
      'ru': 'Не удалось синхронизироваться',
      'en': 'Sync failed',
    },
    'settings.linkSent': {
      'ru': 'Ссылка отправлена на {email}',
      'en': 'Link sent to {email}',
    },
    'settings.linkFailed': {
      'ru': 'Не удалось отправить ссылку',
      'en': 'Failed to send link',
    },
    'settings.dangerZone': {'ru': 'Опасная зона', 'en': 'Danger zone'},
    'settings.reset': {'ru': 'Сбросить прогресс', 'en': 'Reset progress'},
    'settings.resetSubtitle': {
      'ru': 'Словарь и настройки останутся',
      'en': 'Dictionary and settings will stay',
    },
    'settings.resetConfirmTitle': {
      'ru': 'Сбросить прогресс?',
      'en': 'Reset progress?',
    },
    'settings.resetConfirmBody': {
      'ru':
          'Словарь останется, прогресс, логи и статистика будут удалены. '
          'Продолжить?',
      'en':
          'The dictionary will stay; progress, logs and stats will be '
          'deleted. Continue?',
    },
    'settings.resetConfirm': {'ru': 'Сбросить', 'en': 'Reset'},
    'settings.resetDone': {'ru': 'Прогресс сброшен', 'en': 'Progress reset'},
    'settings.resetFailed': {
      'ru': 'Не удалось сбросить прогресс',
      'en': 'Failed to reset progress',
    },
    'settings.howItWorks': {'ru': 'Как это работает', 'en': 'How it works'},
    'settings.onboarding': {
      'ru': 'Короткий онбординг',
      'en': 'Quick onboarding',
    },
    'settings.analytics': {'ru': 'Аналитика', 'en': 'Analytics'},
    'settings.reminders': {'ru': 'Напоминания', 'en': 'Reminders'},
    'settings.remindersToggle': {
      'ru': 'Включить напоминания',
      'en': 'Enable reminders',
    },
    'settings.remindersDaily': {
      'ru': 'Ежедневно в {time}',
      'en': 'Daily at {time}',
    },
    'settings.remindersOff': {'ru': 'Выключены', 'en': 'Off'},
    'settings.reminderTime': {'ru': 'Время напоминания', 'en': 'Reminder time'},
    'settings.reminderFailed': {
      'ru': 'Не удалось обновить напоминание',
      'en': 'Failed to update reminder',
    },
    'settings.loadFailed': {
      'ru': 'Не удалось загрузить настройки',
      'en': 'Failed to load settings',
    },
    'email.title': {'ru': 'Вход по email', 'en': 'Email sign-in'},
    'email.label': {'ru': 'Email', 'en': 'Email'},
    'email.check': {'ru': 'Проверьте адрес', 'en': 'Check the address'},
    'email.send': {'ru': 'Отправить', 'en': 'Send'},
    // Словарь.
    'dictionary.search': {'ru': 'Поиск...', 'en': 'Search...'},
    'dictionary.add': {'ru': 'Добавить слово', 'en': 'Add word'},
    'dictionary.added': {'ru': 'Добавлено', 'en': 'Added'},
    'dictionary.all': {'ru': 'Все', 'en': 'All'},
    'dictionary.learning': {'ru': 'Изучаю', 'en': 'Learning'},
    'dictionary.mastered': {'ru': 'Выучено', 'en': 'Mastered'},
    'dictionary.allCategories': {'ru': 'Все категории', 'en': 'All categories'},
    'dictionary.allLevels': {'ru': 'Все уровни', 'en': 'All levels'},
    'dictionary.emptySearch': {
      'ru': 'Ничего не найдено',
      'en': 'Nothing found',
    },
    'dictionary.emptyCategory': {
      'ru': 'В этой категории пока пусто',
      'en': 'This category is empty so far',
    },
    'dictionary.emptyLevel': {
      'ru': 'Для этого уровня пока пусто',
      'en': 'This level is empty so far',
    },
    'dictionary.emptyTab': {
      'ru': 'В этой вкладке пока пусто',
      'en': 'This tab is empty so far',
    },
    'dictionary.empty': {
      'ru': 'Словарь пуст — добавьте первое слово',
      'en': 'The dictionary is empty — add your first word',
    },
    'dictionary.loadFailed': {
      'ru': 'Не удалось загрузить словарь',
      'en': 'Failed to load the dictionary',
    },
    'wordStatus.new': {'ru': 'новое', 'en': 'new'},
    'wordStatus.learning': {'ru': 'изучаю', 'en': 'learning'},
    'wordStatus.mastered': {'ru': 'выучено', 'en': 'mastered'},
    'word.noExample': {'ru': 'Пример отсутствует', 'en': 'No example'},
    'noCategory': {'ru': 'Без категории', 'en': 'No category'},
    // Диалог добавления слова.
    'addWord.title': {'ru': 'Новое слово', 'en': 'New word'},
    'addWord.term': {'ru': 'Слово', 'en': 'Word'},
    'addWord.translation': {'ru': 'Перевод', 'en': 'Translation'},
    'addWord.transcription': {'ru': 'Транскрипция', 'en': 'Transcription'},
    'addWord.partOfSpeech': {'ru': 'Часть речи', 'en': 'Part of speech'},
    'addWord.category': {'ru': 'Категория', 'en': 'Category'},
    'addWord.level': {'ru': 'Уровень', 'en': 'Level'},
    'addWord.example': {'ru': 'Пример', 'en': 'Example'},
    'addWord.add': {'ru': 'Добавить', 'en': 'Add'},
    'addWord.enterTerm': {'ru': 'Введите слово', 'en': 'Enter a word'},
    'addWord.enterTranslation': {
      'ru': 'Введите перевод',
      'en': 'Enter a translation',
    },
    'addWord.saveFailed': {
      'ru': 'Не удалось сохранить слово',
      'en': 'Failed to save the word',
    },
    'addWord.exists': {
      'ru': '«{term}» уже есть в словаре',
      'en': '"{term}" is already in the dictionary',
    },
    'addWord.existingSenses': {
      'ru': 'Существующие значения:',
      'en': 'Existing senses:',
    },
    'addWord.addAnother': {
      'ru': 'Добавить ещё одно значение?',
      'en': 'Add another sense?',
    },
    'addWord.addAsNew': {'ru': 'Добавить как новое', 'en': 'Add as new'},
    'addWord.createCategory': {
      'ru': '+ Создать категорию…',
      'en': '+ Create category…',
    },
    // Экспорт / импорт.
    'export.copied': {
      'ru': 'Скопировано в буфер обмена',
      'en': 'Copied to clipboard',
    },
    'export.copyFailed': {
      'ru': 'Не удалось скопировать',
      'en': 'Failed to copy',
    },
    'export.close': {'ru': 'Закрыть', 'en': 'Close'},
    'export.copy': {'ru': 'Скопировать', 'en': 'Copy'},
    'export.buildFailed': {
      'ru': 'Не удалось собрать данные',
      'en': 'Failed to build the data',
    },
    'import.invalidJson': {
      'ru': 'Невалидный JSON: {msg}',
      'en': 'Invalid JSON: {msg}',
    },
    'import.unsupportedVersion': {
      'ru': 'Неподдерживаемая версия схемы: {n}',
      'en': 'Unsupported schema version: {n}',
    },
    'import.confirmBody': {
      'ru': 'Все данные будут заменены. Продолжить?',
      'en': 'All data will be replaced. Continue?',
    },
    'import.continue': {'ru': 'Продолжить', 'en': 'Continue'},
    'import.paste': {
      'ru': 'Вставьте JSON резервной копии:',
      'en': 'Paste the backup JSON:',
    },
    'import.action': {'ru': 'Импортировать', 'en': 'Import'},
    'import.failed': {
      'ru': 'Не удалось импортировать данные',
      'en': 'Failed to import the data',
    },
    // Диалог категории.
    'category.new': {'ru': 'Новая категория', 'en': 'New category'},
    'category.name': {'ru': 'Название', 'en': 'Name'},
    'category.color': {'ru': 'Цвет', 'en': 'Color'},
    'category.create': {'ru': 'Создать', 'en': 'Create'},
    'category.exists': {
      'ru': 'Категория уже существует',
      'en': 'Category already exists',
    },
    'category.createFailed': {
      'ru': 'Не удалось создать категорию',
      'en': 'Failed to create the category',
    },
    // Урок.
    'lesson.title': {'ru': 'Урок', 'en': 'Lesson'},
    'lesson.weak': {'ru': 'Сложные слова', 'en': 'Weak words'},
    'lesson.smart': {'ru': 'Умное повторение', 'en': 'Smart review'},
    'lesson.exitTitle': {'ru': 'Завершить сессию?', 'en': 'End the session?'},
    'lesson.exitBody': {
      'ru':
          'Прогресс текущей сессии сохранён. '
          'Недоделанные карточки вернутся в очередь.',
      'en':
          'Current session progress is saved. '
          'Unfinished cards will return to the queue.',
    },
    'lesson.exit': {'ru': 'Выйти', 'en': 'Exit'},
    'lesson.saveFailed': {
      'ru': 'Не удалось сохранить ответ',
      'en': 'Failed to save the answer',
    },
    'lesson.queueFailed': {
      'ru': 'Не удалось загрузить очередь',
      'en': 'Failed to load the queue',
    },
    'lesson.allDone': {'ru': 'На сегодня всё', 'en': 'All done for today'},
    'lesson.dontKnow': {'ru': 'Не знаю', 'en': "Don't know"},
    'lesson.know': {'ru': 'Знаю', 'en': 'Know'},
    // Итоги сессии и тост.
    'session.done': {'ru': 'Сессия завершена', 'en': 'Session complete'},
    'session.correct': {'ru': 'Верно: {a} из {b}', 'en': 'Correct: {a} of {b}'},
    'session.xp': {'ru': 'XP: {n}', 'en': 'XP: {n}'},
    'session.finish': {'ru': 'Готово', 'en': 'Done'},
    'toast.achievement': {'ru': '🏆 ДОСТИЖЕНИЕ!', 'en': '🏆 ACHIEVEMENT!'},
    // Карточка слова и помощник.
    'wordCard.tapToReveal': {
      'ru': 'Нажмите, чтобы увидеть перевод',
      'en': 'Tap to see the translation',
    },
    'wordCard.speak': {'ru': 'Озвучить', 'en': 'Speak'},
    'wordCard.hint': {'ru': 'Подсказка', 'en': 'Hint'},
    'wordCard.hintFailed': {
      'ru': 'Не удалось загрузить подсказку',
      'en': 'Failed to load the hint',
    },
    'helper.ask': {'ru': 'Спросить у помощника', 'en': 'Ask the assistant'},
    'helper.gotIt': {'ru': 'Понятно', 'en': 'Got it'},
    'helper.failed': {
      'ru': 'Не удалось получить объяснение',
      'en': 'Failed to get the explanation',
    },
  };
}
