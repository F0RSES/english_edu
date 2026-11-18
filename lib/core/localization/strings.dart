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

  /// Заголовок секции «Обучение» на главной (Phase 34).
  static String sectionStudy(AppLanguage l) => _t('section.study', l);

  /// Заголовок секции «Тренировки» на главной (Phase 34).
  static String sectionGames(AppLanguage l) => _t('section.games', l);

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

  /// Флаг языка для кнопки в AppBar (Phase 28a).
  static String flagFor(AppLanguage l) => l == AppLanguage.ru ? '🇷🇺' : '🇬🇧';

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

  /// Название игры «Собери предложение» (Phase 35).
  static String gameSentenceBuilder(AppLanguage l) =>
      _t('game.sentenceBuilder', l);

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

  /// Tooltip кнопки «все достижения» в профиле (Phase 28a).
  static String allAchievementsTooltip(AppLanguage l) =>
      _t('profile.allAchievementsTooltip', l);

  /// Заглушка пустых достижений.
  static String noAchievements(AppLanguage l) =>
      _t('profile.noAchievements', l);

  // --- Профиль: никнейм и аватар (Phase 28c, ADR-044) ---
  /// Tooltip карандаша на аватаре и заголовок листа выбора.
  static String changeAvatar(AppLanguage l) => _t('profile.changeAvatar', l);

  /// Пункт листа: удалить фото аватара.
  static String removeAvatar(AppLanguage l) => _t('profile.removeAvatar', l);

  /// Пункт листа: выбрать фото из галереи.
  static String gallery(AppLanguage l) => _t('profile.gallery', l);

  /// Заголовок и подсказка диалога никнейма.
  static String enterNickname(AppLanguage l) => _t('profile.enterNickname', l);

  /// SnackBar после сохранения никнейма.
  static String nicknameSaved(AppLanguage l) => _t('profile.nicknameSaved', l);

  /// Кнопка сохранения никнейма в диалоге.
  static String saveNickname(AppLanguage l) => _t('profile.saveNickname', l);

  /// Tooltip единой кнопки персонализации профиля (Phase 29b).
  static String personalization(AppLanguage l) =>
      _t('profile.personalization', l);

  /// Пункт листа персонализации: смена никнейма.
  static String changeNickname(AppLanguage l) =>
      _t('profile.changeNickname', l);

  /// Заголовок листа массового добавления слов (Phase 30b).
  static String wordsInTask(AppLanguage l) => _t('bulk.wordsInTask', l);

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

  /// Чип «Все» в рядах фильтров словаря (Phase 39a).
  static String filterAll(AppLanguage l) => _t('dictionary.filterAll', l);

  /// Метка ряда категорий словаря (Phase 39a).
  static String filterCategories(AppLanguage l) =>
      _t('dictionary.filterCategories', l);

  /// Кнопка сброса фильтров словаря (Phase 39c).
  static String resetFilters(AppLanguage l) => _t('dictionary.resetFilters', l);

  /// Категория «Животные» (Phase 39a).
  static String categoryAnimals(AppLanguage l) =>
      _t('dictionary.category.animals', l);

  /// Категория «Природа» (Phase 39a).
  static String categoryNature(AppLanguage l) =>
      _t('dictionary.category.nature', l);

  /// Категория «Еда» (Phase 39a).
  static String categoryFood(AppLanguage l) =>
      _t('dictionary.category.food', l);

  /// Категория «Глаголы» (Phase 39a).
  static String categoryVerbs(AppLanguage l) =>
      _t('dictionary.category.verbs', l);

  /// Категория «Наречия» (Phase 39a).
  static String categoryAdverbs(AppLanguage l) =>
      _t('dictionary.category.adverbs', l);

  /// Категория «Прилагательные» (Phase 39a).
  static String categoryAdjectives(AppLanguage l) =>
      _t('dictionary.category.adjectives', l);

  /// Категория «Дом» (Phase 39a).
  static String categoryHome(AppLanguage l) =>
      _t('dictionary.category.home', l);

  /// Категория «Одежда» (Phase 39a).
  static String categoryClothes(AppLanguage l) =>
      _t('dictionary.category.clothes', l);

  /// Категория «Хобби» (Phase 39a).
  static String categoryHobbies(AppLanguage l) =>
      _t('dictionary.category.hobbies', l);

  /// Категория «Дата и время» (Phase 39a).
  static String categoryDatetime(AppLanguage l) =>
      _t('dictionary.category.datetime', l);

  /// Категория «Языки» (Phase 39a).
  static String categoryLanguages(AppLanguage l) =>
      _t('dictionary.category.languages', l);

  /// Категория «Страны» (Phase 39a).
  static String categoryCountries(AppLanguage l) =>
      _t('dictionary.category.countries', l);

  /// Категория «Цвета» (Phase 39a).
  static String categoryColors(AppLanguage l) =>
      _t('dictionary.category.colors', l);

  /// Категория «Транспорт» (Phase 39a).
  static String categoryTransport(AppLanguage l) =>
      _t('dictionary.category.transport', l);

  /// Категория «Компьютеры» (Phase 39a).
  static String categoryComputers(AppLanguage l) =>
      _t('dictionary.category.computers', l);

  /// Категория «Путешествия» (Phase 39a).
  static String categoryTravel(AppLanguage l) =>
      _t('dictionary.category.travel', l);

  /// Категория «Здоровье» (Phase 39a).
  static String categoryHealth(AppLanguage l) =>
      _t('dictionary.category.health', l);

  /// Категория «Тело» (Phase 39a).
  static String categoryBody(AppLanguage l) =>
      _t('dictionary.category.body', l);

  /// Категория «Погода» (Phase 39a).
  static String categoryWeather(AppLanguage l) =>
      _t('dictionary.category.weather', l);

  /// Категория «Школа» (Phase 39a).
  static String categorySchool(AppLanguage l) =>
      _t('dictionary.category.school', l);

  /// Категория «Профессии» (Phase 39a).
  static String categoryProfessions(AppLanguage l) =>
      _t('dictionary.category.professions', l);

  /// Категория «Семья» (Phase 39a).
  static String categoryFamily(AppLanguage l) =>
      _t('dictionary.category.family', l);

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

  // --- AI Word Helper (Phase 28b) ---
  /// Заголовок листа перевода слова.
  static String aiHelperTitle(AppLanguage l) => _t('aiHelper.title', l);

  /// Tooltip добавления слова в словарь.
  static String addToDictionary(AppLanguage l) => _t('aiHelper.add', l);

  /// Tooltip удаления слова из словаря.
  static String removeFromDictionary(AppLanguage l) => _t('aiHelper.remove', l);

  /// Кнопка «Не знаю слово» до ответа в игре.
  static String dontKnowWord(AppLanguage l) => _t('aiHelper.dontKnow', l);

  /// SnackBar после удаления слова из словаря.
  static String wordRemoved(AppLanguage l) => _t('aiHelper.removed', l);

  /// Заголовок подтверждения удаления слова.
  static String removeConfirmTitle(AppLanguage l) =>
      _t('aiHelper.removeTitle', l);

  /// Текст подтверждения удаления; [term] подставляется в {term}.
  static String removeConfirmBody(String term, AppLanguage l) =>
      _t('aiHelper.removeBody', l).replaceFirst('{term}', term);

  // --- Общие строки игр (Phase 31, BL-94) ---
  /// Кнопка перехода к следующему заданию.
  static String commonNextTask(AppLanguage l) => _t('common.nextTask', l);

  /// Заглушка ошибки загрузки.
  static String commonLoadFailed(AppLanguage l) => _t('common.loadFailed', l);

  /// Пустой словарь в игре.
  static String commonEmptyDictionary(AppLanguage l) =>
      _t('common.emptyDictionary', l);

  /// Кнопка повторного заезда.
  static String commonAgain(AppLanguage l) => _t('common.again', l);

  /// Кнопка выхода из игры.
  static String commonExit(AppLanguage l) => _t('common.exit', l);

  // --- Error Hunter ---
  /// Инструкция игры.
  static String errorHunterInstruction(AppLanguage l) =>
      _t('game.errorHunter.instruction', l);

  /// Заголовок листа вариантов.
  static String errorHunterHowCorrect(AppLanguage l) =>
      _t('game.errorHunter.howCorrect', l);

  /// Ошибка генерации задания.
  static String errorHunterGenerateFailed(AppLanguage l) =>
      _t('game.errorHunter.generateFailed', l);

  // --- Scramble ---
  /// Инструкция игры.
  static String scrambleInstruction(AppLanguage l) =>
      _t('game.scramble.instruction', l);

  /// Кнопка очистки ответа.
  static String scrambleClear(AppLanguage l) => _t('game.scramble.clear', l);

  /// Счётчик верных слов.
  static String scrambleCorrectCount(int n, AppLanguage l) =>
      _t('game.scramble.correctCount', l).replaceFirst('{n}', '$n');

  /// Заглушка загрузки задания.
  static String scramblePreparing(AppLanguage l) =>
      _t('game.scramble.preparing', l);

  /// Инструкция игры «Собери предложение» (Phase 35).
  static String sentenceInstruction(AppLanguage l) =>
      _t('game.sentenceBuilder.instruction', l);

  /// Название игры «Аудио-диктант предложений» (Phase 36b).
  static String gameListeningV2(AppLanguage l) => _t('game.listeningV2', l);

  /// Инструкция «Аудио-диктанта предложений».
  static String listeningInstruction(AppLanguage l) =>
      _t('game.listeningV2.instruction', l);

  /// Кнопка показа перевода-подсказки.
  static String listeningShowTranslation(AppLanguage l) =>
      _t('game.listeningV2.showTranslation', l);

  /// Подсказка поля ввода диктанта предложений.
  static String listeningHint(AppLanguage l) => _t('game.listeningV2.hint', l);

  /// Карточка после неверного ответа: показывает правильное предложение.
  static String listeningWrongAnswer(String sentence, AppLanguage l) =>
      _t('game.listeningV2.wrongAnswer', l).replaceFirst('{s}', sentence);

  // --- Dictation ---
  /// TTS недоступен.
  static String dictationTtsUnavailable(AppLanguage l) =>
      _t('game.dictation.ttsUnavailable', l);

  /// Подсказка повторного прослушивания.
  static String dictationRepeatHint(AppLanguage l) =>
      _t('game.dictation.repeatHint', l);

  /// Кнопка следующего слова.
  static String dictationNextWord(AppLanguage l) =>
      _t('game.dictation.nextWord', l);

  /// Подсказка поля ввода.
  static String dictationHint(AppLanguage l) => _t('game.dictation.hint', l);

  // --- Typing ---
  /// Ошибка сохранения рекорда.
  static String typingSaveFailed(AppLanguage l) =>
      _t('game.typing.saveFailed', l);

  /// Заголовок итогов заезда.
  static String typingRunDone(AppLanguage l) => _t('game.typing.runDone', l);

  /// Точность в процентах.
  static String typingAccuracy(int n, AppLanguage l) =>
      _t('game.typing.accuracy', l).replaceFirst('{n}', '$n');

  /// Очки заезда.
  static String typingScore(int n, AppLanguage l) =>
      _t('game.typing.score', l).replaceFirst('{n}', '$n');

  /// Скорость: WPM — аббревиатура, не переводится.
  static String typingWpm(int n, AppLanguage l) =>
      _t('game.typing.wpm', l).replaceFirst('{n}', '$n');

  /// Подсказка к переводу: «4 буквы, m...» / «4 letters, m...» (Phase 36a).
  ///
  /// Метод, а не ключ _data: формы склонения собираются на месте,
  /// как в readingWordUnit.
  static String typingLetterHint(int count, String first, AppLanguage l) {
    final unit = l == AppLanguage.ru
        ? pluralize(count, one: 'буква', few: 'буквы', many: 'букв')
        : (count == 1 ? 'letter' : 'letters');
    return '$count $unit, $first...';
  }

  // --- Memory ---
  /// Заголовок победы.
  static String memoryVictory(AppLanguage l) => _t('game.memory.victory', l);

  /// Текст победы с числом ходов.
  static String memoryVictoryBody(int n, AppLanguage l) =>
      _t('game.memory.victoryBody', l).replaceFirst('{n}', '$n');

  /// Счётчик ходов.
  static String memoryMoves(int n, AppLanguage l) =>
      _t('game.memory.moves', l).replaceFirst('{n}', '$n');

  /// Кнопка рестарта.
  static String memoryRestart(AppLanguage l) => _t('game.memory.restart', l);

  // --- Phrasebook ---
  /// Фразы не загружены.
  static String phrasebookNotLoaded(AppLanguage l) =>
      _t('game.phrasebook.notLoaded', l);

  /// Ошибка загрузки фраз.
  static String phrasebookLoadFailed(AppLanguage l) =>
      _t('game.phrasebook.loadFailed', l);

  /// Подсказка поиска.
  static String phrasebookSearch(AppLanguage l) =>
      _t('game.phrasebook.search', l);

  /// Вкладка/фильтр «Все».
  static String phrasebookAll(AppLanguage l) => _t('game.phrasebook.all', l);

  /// Ничего не найдено.
  static String phrasebookNothingFound(AppLanguage l) =>
      _t('game.phrasebook.nothingFound', l);

  // --- Reading ---
  /// Рассказы не загружены.
  static String readingNotLoaded(AppLanguage l) =>
      _t('game.reading.notLoaded', l);

  /// Ошибка загрузки рассказов.
  static String readingLoadFailed(AppLanguage l) =>
      _t('game.reading.loadFailed', l);

  /// Кнопка показа перевода.
  static String readingShowTranslation(AppLanguage l) =>
      _t('game.reading.showTranslation', l);

  /// Кнопка скрытия перевода.
  static String readingHideTranslation(AppLanguage l) =>
      _t('game.reading.hideTranslation', l);

  /// Незнакомые слова (кнопка и диалог).
  static String readingUnknownWords(AppLanguage l) =>
      _t('game.reading.unknownWords', l);

  /// Ошибка добавления слов.
  static String readingAddFailed(AppLanguage l) =>
      _t('game.reading.addFailed', l);

  /// Ошибка разбора текста.
  static String readingParseFailed(AppLanguage l) =>
      _t('game.reading.parseFailed', l);

  /// Все слова уже в словаре.
  static String readingAllInDictionary(AppLanguage l) =>
      _t('game.reading.allInDictionary', l);

  /// Единица счёта слов: ru — склонение, en — word/words.
  static String readingWordUnit(int n, AppLanguage l) => l == AppLanguage.ru
      ? pluralize(n, one: 'слово', few: 'слова', many: 'слов')
      : (n == 1 ? 'word' : 'words');

  /// SnackBar «Добавлено N слов».
  static String readingAddedWords(int n, AppLanguage l) => _t(
    'game.reading.addedWords',
    l,
  ).replaceFirst('{n}', '$n').replaceFirst('{unit}', readingWordUnit(n, l));

  /// Кнопка «Добавить N слов».
  static String readingAddWords(int n, AppLanguage l) => _t(
    'game.reading.addWords',
    l,
  ).replaceFirst('{n}', '$n').replaceFirst('{unit}', readingWordUnit(n, l));

  // --- Achievements ---
  /// Заголовок экрана достижений.
  static String achievementsTitle(AppLanguage l) => _t('achievements.title', l);

  /// Ошибка загрузки достижений.
  static String achievementsLoadFailed(AppLanguage l) =>
      _t('achievements.loadFailed', l);

  /// Заголовок секции открытых.
  static String achievementsUnlocked(int n, AppLanguage l) =>
      _t('achievements.unlocked', l).replaceFirst('{n}', '$n');

  /// Заголовок секции в процессе.
  static String achievementsInProgress(int n, AppLanguage l) =>
      _t('achievements.inProgress', l).replaceFirst('{n}', '$n');

  /// Заглушка пустой секции открытых.
  static String achievementsEmptyUnlocked(AppLanguage l) =>
      _t('achievements.emptyUnlocked', l);

  /// Все достижения открыты.
  static String achievementsAllUnlocked(AppLanguage l) =>
      _t('achievements.allUnlocked', l);

  // --- Chat ---
  /// Ошибка загрузки истории.
  static String chatHistoryLoadFailed(AppLanguage l) =>
      _t('chat.historyLoadFailed', l);

  /// Ошибка получения ответа.
  static String chatReplyFailed(AppLanguage l) => _t('chat.replyFailed', l);

  /// Заголовок подтверждения очистки.
  static String chatClearTitle(AppLanguage l) => _t('chat.clearTitle', l);

  /// Текст подтверждения очистки.
  static String chatClearBody(AppLanguage l) => _t('chat.clearBody', l);

  /// Кнопка очистки.
  static String chatClear(AppLanguage l) => _t('chat.clear', l);

  /// Кнопка очистки истории.
  static String chatClearHistory(AppLanguage l) => _t('chat.clearHistory', l);

  /// Подсказка поля ввода.
  static String chatHint(AppLanguage l) => _t('chat.hint', l);

  /// Приветствие помощника.
  static String chatGreeting(AppLanguage l) => _t('chat.greeting', l);

  // --- Onboarding ---
  /// Заголовок первого слайда.
  static String onboardingSlide1Title(AppLanguage l) =>
      _t('onboarding.slide1Title', l);

  /// Текст первого слайда.
  static String onboardingSlide1Body(AppLanguage l) =>
      _t('onboarding.slide1Body', l);

  /// Заголовок второго слайда.
  static String onboardingSlide2Title(AppLanguage l) =>
      _t('onboarding.slide2Title', l);

  /// Текст второго слайда.
  static String onboardingSlide2Body(AppLanguage l) =>
      _t('onboarding.slide2Body', l);

  /// Заголовок третьего слайда.
  static String onboardingSlide3Title(AppLanguage l) =>
      _t('onboarding.slide3Title', l);

  /// Текст третьего слайда.
  static String onboardingSlide3Body(AppLanguage l) =>
      _t('onboarding.slide3Body', l);

  /// Заголовок «Как это работает».
  static String onboardingHowItWorks(AppLanguage l) =>
      _t('onboarding.howItWorks', l);

  /// Кнопка пропуска.
  static String onboardingSkip(AppLanguage l) => _t('onboarding.skip', l);

  /// Кнопка старта.
  static String onboardingStart(AppLanguage l) => _t('onboarding.start', l);

  /// Заголовок выбора уровня.
  static String onboardingLevelTitle(AppLanguage l) =>
      _t('onboarding.levelTitle', l);

  /// Текст выбора уровня.
  static String onboardingLevelBody(AppLanguage l) =>
      _t('onboarding.levelBody', l);

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
    'section.study': {'ru': 'Обучение', 'en': 'Study'},
    'section.games': {'ru': 'Тренировки', 'en': 'Practice'},
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
    'game.errorHunter': {'ru': 'Охота на ошибки', 'en': 'Error Hunter'},
    'game.cloze': {'ru': 'Заполни пропуск', 'en': 'Gap fill'},
    'game.scramble': {'ru': 'Собери слово', 'en': 'Word Scramble'},
    'game.memory': {'ru': 'Мемори', 'en': 'Memory'},
    'game.typing': {'ru': 'Скорость печати', 'en': 'Typing Speed'},
    'game.phrasebook': {'ru': 'Разговорник', 'en': 'Phrasebook'},
    'game.dictation': {'ru': 'Аудио-диктант', 'en': 'Dictation'},
    'game.reading': {'ru': 'Чтение', 'en': 'Reading'},
    'game.sentenceBuilder': {
      'ru': 'Собери предложение',
      'en': 'Sentence Builder',
    },
    'game.listeningV2': {
      'ru': 'Аудио-диктант предложений',
      'en': 'Sentence Dictation',
    },
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
    'profile.allAchievementsTooltip': {
      'ru': 'Все достижения',
      'en': 'All achievements',
    },
    'profile.noAchievements': {
      'ru': 'Пока нет достижений. Выполняй задания!',
      'en': 'No achievements yet. Complete challenges!',
    },
    // Профиль: никнейм и аватар (Phase 28c, ADR-044).
    'profile.changeAvatar': {'ru': 'Сменить аватар', 'en': 'Change avatar'},
    'profile.removeAvatar': {'ru': 'Удалить фото', 'en': 'Remove photo'},
    'profile.gallery': {'ru': 'Галерея', 'en': 'Gallery'},
    'profile.enterNickname': {'ru': 'Введите никнейм', 'en': 'Enter nickname'},
    'profile.nicknameSaved': {'ru': 'Никнейм сохранён', 'en': 'Nickname saved'},
    'profile.saveNickname': {'ru': 'Сохранить', 'en': 'Save'},
    'profile.personalization': {
      'ru': 'Персонализация',
      'en': 'Personalization',
    },
    'profile.changeNickname': {
      'ru': 'Сменить никнейм',
      'en': 'Change nickname',
    },
    'bulk.wordsInTask': {'ru': 'Слова в задании', 'en': 'Words in the task'},
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
    'dictionary.filterAll': {'ru': 'Все', 'en': 'All'},
    'dictionary.filterCategories': {'ru': 'Категории', 'en': 'Categories'},
    'dictionary.resetFilters': {
      'ru': 'Сбросить фильтры',
      'en': 'Reset filters',
    },
    'dictionary.category.animals': {'ru': 'Животные', 'en': 'Animals'},
    'dictionary.category.nature': {'ru': 'Природа', 'en': 'Nature'},
    'dictionary.category.food': {'ru': 'Еда', 'en': 'Food'},
    'dictionary.category.verbs': {'ru': 'Глаголы', 'en': 'Verbs'},
    'dictionary.category.adverbs': {'ru': 'Наречия', 'en': 'Adverbs'},
    'dictionary.category.adjectives': {
      'ru': 'Прилагательные',
      'en': 'Adjectives',
    },
    'dictionary.category.home': {'ru': 'Дом', 'en': 'Home'},
    'dictionary.category.clothes': {'ru': 'Одежда', 'en': 'Clothes'},
    'dictionary.category.hobbies': {'ru': 'Хобби', 'en': 'Hobbies'},
    'dictionary.category.datetime': {'ru': 'Дата и время', 'en': 'Date & Time'},
    'dictionary.category.languages': {'ru': 'Языки', 'en': 'Languages'},
    'dictionary.category.countries': {'ru': 'Страны', 'en': 'Countries'},
    'dictionary.category.colors': {'ru': 'Цвета', 'en': 'Colors'},
    'dictionary.category.transport': {'ru': 'Транспорт', 'en': 'Transport'},
    'dictionary.category.computers': {'ru': 'Компьютеры', 'en': 'Computers'},
    'dictionary.category.travel': {'ru': 'Путешествия', 'en': 'Travel'},
    'dictionary.category.health': {'ru': 'Здоровье', 'en': 'Health'},
    'dictionary.category.body': {'ru': 'Тело', 'en': 'Body'},
    'dictionary.category.weather': {'ru': 'Погода', 'en': 'Weather'},
    'dictionary.category.school': {'ru': 'Школа', 'en': 'School'},
    'dictionary.category.professions': {'ru': 'Профессии', 'en': 'Professions'},
    'dictionary.category.family': {'ru': 'Семья', 'en': 'Family'},
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
    // AI Word Helper (Phase 28b).
    'aiHelper.title': {'ru': 'Помощник по слову', 'en': 'Word helper'},
    'aiHelper.add': {'ru': 'Добавить в словарь', 'en': 'Add to dictionary'},
    'aiHelper.remove': {
      'ru': 'Удалить из словаря',
      'en': 'Remove from dictionary',
    },
    'aiHelper.dontKnow': {
      'ru': 'Не знаю слово',
      'en': "I don't know this word",
    },
    'aiHelper.removed': {'ru': 'Слово удалено', 'en': 'Word removed'},
    'aiHelper.removeTitle': {'ru': 'Удалить слово?', 'en': 'Remove word?'},
    'aiHelper.removeBody': {
      'ru': 'Слово «{term}» будет удалено из словаря вместе с прогрессом.',
      'en':
          'The word "{term}" will be removed from the dictionary with its '
          'progress.',
    },
    // Общие строки игр (Phase 31, BL-94).
    'common.nextTask': {'ru': 'Следующее задание', 'en': 'Next task'},
    'common.loadFailed': {'ru': 'Не удалось загрузить', 'en': 'Failed to load'},
    'common.emptyDictionary': {
      'ru': 'Добавьте слова в словарь',
      'en': 'Add words to the dictionary',
    },
    'common.again': {'ru': 'Ещё раз', 'en': 'Again'},
    'common.exit': {'ru': 'Выйти', 'en': 'Exit'},
    // Error Hunter.
    'game.errorHunter.instruction': {
      'ru': 'Найди ошибку и нажми на слово',
      'en': 'Find the error and tap the word',
    },
    'game.errorHunter.howCorrect': {
      'ru': 'Как правильно?',
      'en': 'What is the correct form?',
    },
    'game.errorHunter.generateFailed': {
      'ru': 'Не удалось сгенерировать задание, попробуйте еще раз',
      'en': 'Failed to generate the task, please try again',
    },
    // Scramble.
    'game.scramble.instruction': {
      'ru': 'Переведи и собери слово по буквам',
      'en': 'Translate and assemble the word letter by letter',
    },
    'game.scramble.clear': {'ru': 'Очистить', 'en': 'Clear'},
    'game.scramble.correctCount': {'ru': '{n} верно', 'en': '{n} correct'},
    'game.scramble.preparing': {
      'ru': 'Готовим задание...',
      'en': 'Preparing the task...',
    },
    'game.sentenceBuilder.instruction': {
      'ru': 'Собери предложение из слов',
      'en': 'Assemble the sentence',
    },
    'game.listeningV2.instruction': {
      'ru': 'Прослушай и запиши предложение',
      'en': 'Listen and write',
    },
    'game.listeningV2.showTranslation': {
      'ru': 'Показать перевод',
      'en': 'Show translation',
    },
    'game.listeningV2.hint': {
      'ru': 'Введите предложение...',
      'en': 'Enter the sentence...',
    },
    'game.listeningV2.wrongAnswer': {
      'ru': 'Неверно. Правильно: {s}',
      'en': 'Wrong. Correct: {s}',
    },
    // Dictation.
    'game.dictation.ttsUnavailable': {
      'ru': 'Озвучка недоступна',
      'en': 'Speech is unavailable',
    },
    'game.dictation.repeatHint': {
      'ru': 'Нажми, чтобы услышать ещё раз',
      'en': 'Tap to hear it again',
    },
    'game.dictation.nextWord': {'ru': 'Следующее слово', 'en': 'Next word'},
    'game.dictation.hint': {
      'ru': 'Введите слово...',
      'en': 'Enter the word...',
    },
    // Typing.
    'game.typing.saveFailed': {
      'ru': 'Не удалось сохранить результат',
      'en': 'Failed to save the result',
    },
    'game.typing.runDone': {'ru': 'Заезд завершён', 'en': 'Run complete'},
    'game.typing.accuracy': {'ru': 'Точность: {n}%', 'en': 'Accuracy: {n}%'},
    'game.typing.score': {'ru': 'Очки: {n}', 'en': 'Score: {n}'},
    'game.typing.wpm': {'ru': 'WPM: {n}', 'en': 'WPM: {n}'},
    // Memory.
    'game.memory.victory': {'ru': 'Победа!', 'en': 'Victory!'},
    'game.memory.victoryBody': {
      'ru': 'Все пары найдены за {n} ходов.',
      'en': 'All pairs found in {n} moves.',
    },
    'game.memory.moves': {'ru': 'Ходы: {n}', 'en': 'Moves: {n}'},
    'game.memory.restart': {'ru': 'Заново', 'en': 'Restart'},
    // Phrasebook.
    'game.phrasebook.notLoaded': {
      'ru': 'Фразы не загружены',
      'en': 'Phrases not loaded',
    },
    'game.phrasebook.loadFailed': {
      'ru': 'Не удалось загрузить фразы',
      'en': 'Failed to load phrases',
    },
    'game.phrasebook.search': {'ru': 'Поиск', 'en': 'Search'},
    'game.phrasebook.all': {'ru': 'Все', 'en': 'All'},
    'game.phrasebook.nothingFound': {
      'ru': 'Ничего не найдено',
      'en': 'Nothing found',
    },
    // Reading.
    'game.reading.notLoaded': {
      'ru': 'Рассказы не загружены',
      'en': 'Stories not loaded',
    },
    'game.reading.loadFailed': {
      'ru': 'Не удалось загрузить рассказы',
      'en': 'Failed to load stories',
    },
    'game.reading.showTranslation': {
      'ru': 'Показать перевод',
      'en': 'Show translation',
    },
    'game.reading.hideTranslation': {
      'ru': 'Скрыть перевод',
      'en': 'Hide translation',
    },
    'game.reading.unknownWords': {
      'ru': 'Незнакомые слова',
      'en': 'Unknown words',
    },
    'game.reading.addFailed': {
      'ru': 'Не удалось добавить слова',
      'en': 'Failed to add the words',
    },
    'game.reading.parseFailed': {
      'ru': 'Не удалось разобрать текст',
      'en': 'Failed to parse the text',
    },
    'game.reading.allInDictionary': {
      'ru': 'Все слова в тексте уже в словаре.',
      'en': 'All words in the text are already in the dictionary.',
    },
    'game.reading.addedWords': {
      'ru': 'Добавлено {n} {unit}',
      'en': 'Added {n} {unit}',
    },
    'game.reading.addWords': {
      'ru': 'Добавить {n} {unit}',
      'en': 'Add {n} {unit}',
    },
    // Achievements.
    'achievements.title': {'ru': 'Достижения', 'en': 'Achievements'},
    'achievements.loadFailed': {
      'ru': 'Не удалось загрузить достижения',
      'en': 'Failed to load achievements',
    },
    'achievements.unlocked': {
      'ru': 'Разблокировано ({n})',
      'en': 'Unlocked ({n})',
    },
    'achievements.inProgress': {
      'ru': 'В процессе ({n})',
      'en': 'In progress ({n})',
    },
    'achievements.emptyUnlocked': {
      'ru': 'Пока пусто — начни с серии дней.',
      'en': 'Nothing yet — start with a day streak.',
    },
    'achievements.allUnlocked': {
      'ru': 'Все достижения открыты!',
      'en': 'All achievements unlocked!',
    },
    // Chat.
    'chat.historyLoadFailed': {
      'ru': 'Не удалось загрузить историю',
      'en': 'Failed to load history',
    },
    'chat.replyFailed': {
      'ru': 'Не удалось получить ответ, проверьте интернет',
      'en': 'Failed to get a reply, check your internet',
    },
    'chat.clearTitle': {'ru': 'Очистить историю?', 'en': 'Clear history?'},
    'chat.clearBody': {
      'ru': 'Все сообщения чата будут удалены.',
      'en': 'All chat messages will be deleted.',
    },
    'chat.clear': {'ru': 'Очистить', 'en': 'Clear'},
    'chat.clearHistory': {'ru': 'Очистить историю', 'en': 'Clear history'},
    'chat.hint': {
      'ru': 'Спроси про английский...',
      'en': 'Ask about English...',
    },
    'chat.greeting': {
      'ru': 'Привет! Я помогу разобраться с английским. Спроси что-нибудь.',
      'en': 'Hi! I can help you with English. Ask me anything.',
    },
    // Onboarding.
    'onboarding.slide1Title': {
      'ru': 'Учи слова легко',
      'en': 'Learn words easily',
    },
    'onboarding.slide1Body': {
      'ru':
          'Свайп вправо — «знаю», влево — «не знаю». '
          'Приложение само решает, когда показать слово снова.',
      'en':
          'Swipe right for "know", left for "don\'t know". '
          'The app decides when to show the word again.',
    },
    'onboarding.slide2Title': {'ru': 'AI-подсказки', 'en': 'AI hints'},
    'onboarding.slide2Body': {
      'ru':
          'Не запоминается слово? Нажмите «Подсказка» — ассоциацию '
          'придумает AI. Запрос уходит только по вашему нажатию.',
      'en':
          'Can\'t remember a word? Tap "Hint" and AI will come up '
          'with an association. The request is sent only on your tap.',
    },
    'onboarding.slide3Title': {
      'ru': 'Играй и запоминай',
      'en': 'Play and remember',
    },
    'onboarding.slide3Body': {
      'ru':
          '«Охота на ошибки»: найдите ошибку в предложении и выберите '
          'правильный вариант. Пять минут между делами.',
      'en':
          '"Error Hunter": find the error in a sentence and pick the '
          'correct option. Five minutes between tasks.',
    },
    'onboarding.howItWorks': {'ru': 'Как это работает', 'en': 'How it works'},
    'onboarding.skip': {'ru': 'Пропустить', 'en': 'Skip'},
    'onboarding.start': {'ru': 'Начать', 'en': 'Start'},
    'onboarding.levelTitle': {
      'ru': 'Какой у тебя уровень?',
      'en': 'What is your level?',
    },
    'onboarding.levelBody': {
      'ru':
          'Новые слова подбираются не выше выбранного уровня. '
          'Слова, которые вы уже учите, не фильтруются.',
      'en':
          'New words are picked no higher than the selected level. '
          'Words you are already learning are not filtered.',
    },
  };
}
