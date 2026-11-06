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
