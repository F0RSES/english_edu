/// Достижение: долгосрочная цель, которую видит пользователь (ADR-035).
///
/// Ключ ([key]) — то, что лежит в БД. Он не выводится из имени значения: enum
/// можно переименовать, а данные в базе останутся прежними.
enum AchievementType {
  /// Семь дней подряд.
  streak7(
    key: 'streak_7',
    title: '7 дней подряд',
    description: 'Заходил 7 дней подряд',
    icon: '🔥',
    goal: 7,
  ),

  /// Тридцать дней подряд.
  streak30(
    key: 'streak_30',
    title: '30 дней подряд',
    description: 'Месяц без пропусков',
    icon: '🌟',
    goal: 30,
  ),

  /// Сто дней подряд.
  streak100(
    key: 'streak_100',
    title: '100 дней!',
    description: 'Легенда',
    icon: '👑',
    goal: 100,
  ),

  /// Сто выученных слов.
  words100(
    key: 'words_100',
    title: '100 слов',
    description: 'Изучил 100 слов',
    icon: '📚',
    goal: 100,
  ),

  /// Пятьсот выученных слов.
  words500(
    key: 'words_500',
    title: '500 слов',
    description: 'Половина пути до 1000',
    icon: '📖',
    goal: 500,
  ),

  /// Тысяча выученных слов.
  words1000(
    key: 'words_1000',
    title: '1000 слов!',
    description: 'Мастер словаря',
    icon: '🎓',
    goal: 1000,
  ),

  /// Десять верных ответов подряд.
  perfect10(
    key: 'perfect_10',
    title: '10 верных подряд',
    description: 'Без ошибок',
    icon: '🎯',
    goal: 10,
  ),

  /// Пятьдесят верных ответов подряд.
  perfect50(
    key: 'perfect_50',
    title: '50 верных подряд',
    description: 'Идеальная серия',
    icon: '💎',
    goal: 50,
  ),

  /// Семь выполненных заданий дня подряд.
  daily7(
    key: 'daily_7',
    title: '7 челленджей',
    description: 'Неделя челленджей',
    icon: '🏅',
    goal: 7,
  ),

  /// Первый урок завершён.
  firstLesson(
    key: 'first_lesson',
    title: 'Первый урок',
    description: 'Начало пути',
    icon: '🌱',
    goal: 1,
  ),

  /// Сто ответов всего.
  answers100(
    key: 'answers_100',
    title: '100 ответов',
    description: 'Сотня позади',
    icon: '💬',
    goal: 100,
  ),

  /// Пятьсот ответов всего.
  answers500(
    key: 'answers_500',
    title: '500 ответов',
    description: 'Полтысячи!',
    icon: '🗣️',
    goal: 500,
  ),

  /// Тысяча ответов всего.
  answers1000(
    key: 'answers_1000',
    title: '1000 ответов',
    description: 'Тысяча слов сказано',
    icon: '🏆',
    goal: 1000,
  ),

  /// Пять тысяч ответов всего.
  answers5000(
    key: 'answers_5000',
    title: '5000 ответов',
    description: 'Неудержимый',
    icon: '⚡',
    goal: 5000,
  ),

  /// Сто верных ответов всего.
  correct100(
    key: 'correct_100',
    title: '100 верных',
    description: 'Сотня правильных',
    icon: '✅',
    goal: 100,
  ),

  /// Пятьсот верных ответов всего.
  correct500(
    key: 'correct_500',
    title: '500 верных',
    description: 'Меткий стрелок',
    icon: '🎯',
    goal: 500,
  ),

  /// Четырнадцать дней подряд.
  streak14(
    key: 'streak_14',
    title: '14 дней подряд',
    description: 'Две недели без пропусков',
    icon: '🔥',
    goal: 14,
  ),

  /// Шестьдесят дней подряд.
  streak60(
    key: 'streak_60',
    title: '60 дней подряд',
    description: 'Два месяца!',
    icon: '💪',
    goal: 60,
  ),

  /// Год подряд.
  streak365(
    key: 'streak_365',
    title: '365 дней!',
    description: 'Целый год',
    icon: '🏅',
    goal: 365,
  ),

  /// Две тысячи выученных слов.
  words2000(
    key: 'words_2000',
    title: '2000 слов',
    description: 'Две тысячи!',
    icon: '📚',
    goal: 2000,
  ),

  /// Пять тысяч выученных слов.
  words5000(
    key: 'words_5000',
    title: '5000 слов!',
    description: 'Полиглот',
    icon: '🌍',
    goal: 5000,
  ),

  /// Сто верных ответов подряд.
  perfect100(
    key: 'perfect_100',
    title: '100 верных подряд',
    description: 'Безупречно',
    icon: '💎',
    goal: 100,
  ),

  /// Тридцать челленджей (лучшая серия).
  daily30(
    key: 'daily_30',
    title: '30 челленджей',
    description: 'Месяц заданий',
    icon: '🏅',
    goal: 30,
  ),

  /// Тысяча XP заработано.
  xp1000(
    key: 'xp_1000',
    title: '1000 XP',
    description: 'Первая тысяча опыта',
    icon: '⭐',
    goal: 1000,
  ),

  /// Пять тысяч XP заработано.
  xp5000(
    key: 'xp_5000',
    title: '5000 XP',
    description: 'Опытный боец',
    icon: '🌟',
    goal: 5000,
  ),

  /// Десять тысяч XP заработано.
  xp10000(
    key: 'xp_10000',
    title: '10000 XP!',
    description: 'Легенда опыта',
    icon: '👑',
    goal: 10000,
  ),

  /// Десять сообщений в чате.
  chat10(
    key: 'chat_10',
    title: '10 сообщений',
    description: 'Первый диалог',
    icon: '💬',
    goal: 10,
  ),

  /// Пятьдесят сообщений в чате.
  chat50(
    key: 'chat_50',
    title: '50 сообщений',
    description: 'Общительный',
    icon: '🗨️',
    goal: 50,
  ),

  /// Сто сообщений в чате.
  chat100(
    key: 'chat_100',
    title: '100 сообщений',
    description: 'Душа компании',
    icon: '🎙️',
    goal: 100,
  ),

  /// Десять заездов Typing Speed.
  typing10(
    key: 'typing_10',
    title: '10 заездов',
    description: 'Быстрые пальцы',
    icon: '⌨️',
    goal: 10,
  );

  const AchievementType({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.goal,
  });

  /// Ключ в БД.
  final String key;

  /// Заголовок для карточки и тоста.
  final String title;

  /// Пояснение, за что достижение.
  final String description;

  /// Эмодзи-иконка.
  final String icon;

  /// Порог метрики, при котором достижение открывается.
  final int goal;

  /// Восстанавливает тип по ключу из БД; null — ключ неизвестен.
  ///
  /// Неизвестный ключ — не ошибка: приложение могло обновиться и убрать
  /// достижение, а строка в базе осталась.
  static AchievementType? fromKey(String key) {
    for (final type in AchievementType.values) {
      if (type.key == key) {
        return type;
      }
    }
    return null;
  }
}
