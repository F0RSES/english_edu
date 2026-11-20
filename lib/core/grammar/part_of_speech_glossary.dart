/// Пояснение части речи для шторки разбора слова (Phase 51, ADR-049).
///
/// Данные, а не UI-строки: виджет сам выбирает язык приложения.
/// Ключи — нормализованные названия частей речи из прокси/seed.
final class PartOfSpeechEntry {
  /// Создаёт пояснение части речи.
  const PartOfSpeechEntry({
    required this.key,
    required this.enName,
    required this.ruName,
    required this.enDefinition,
    required this.ruDefinition,
    required this.example,
  });

  /// Нормализованный ключ ('noun').
  final String key;

  /// Название по-английски ('Noun').
  final String enName;

  /// Название по-русски ('Существительное').
  final String ruName;

  /// Определение по-английски (1–2 предложения).
  final String enDefinition;

  /// Определение по-русски.
  final String ruDefinition;

  /// Примеры слов.
  final String example;
}

/// Глоссарий частей речи: поиск пояснения по нормализованному ключу.
final class PartOfSpeechGlossary {
  const PartOfSpeechGlossary._();

  /// Все поддерживаемые части речи.
  static const Map<String, PartOfSpeechEntry> entries = {
    'noun': PartOfSpeechEntry(
      key: 'noun',
      enName: 'Noun',
      ruName: 'Существительное',
      enDefinition: 'A word that names a person, place, thing, or idea.',
      ruDefinition:
          'Слово, которое называет человека, место, предмет или идею.',
      example: 'book, teacher, London',
    ),
    'verb': PartOfSpeechEntry(
      key: 'verb',
      enName: 'Verb',
      ruName: 'Глагол',
      enDefinition: 'A word that describes an action, state, or occurrence.',
      ruDefinition:
          'Слово, которое обозначает действие, состояние или событие.',
      example: 'run, think, is',
    ),
    'adjective': PartOfSpeechEntry(
      key: 'adjective',
      enName: 'Adjective',
      ruName: 'Прилагательное',
      enDefinition: 'A word that describes a noun or pronoun.',
      ruDefinition: 'Слово, которое описывает существительное или местоимение.',
      example: 'happy, blue, quick',
    ),
    'adverb': PartOfSpeechEntry(
      key: 'adverb',
      enName: 'Adverb',
      ruName: 'Наречие',
      enDefinition:
          'A word that modifies a verb, adjective, or another adverb, '
          'often telling how, when, or where.',
      ruDefinition:
          'Слово, которое поясняет глагол, прилагательное или другое '
          'наречие: как, когда или где.',
      example: 'quickly, very, yesterday',
    ),
    'pronoun': PartOfSpeechEntry(
      key: 'pronoun',
      enName: 'Pronoun',
      ruName: 'Местоимение',
      enDefinition: 'A word used instead of a noun to avoid repetition.',
      ruDefinition:
          'Слово, которое заменяет существительное, чтобы избежать повтора.',
      example: 'I, she, they',
    ),
    'preposition': PartOfSpeechEntry(
      key: 'preposition',
      enName: 'Preposition',
      ruName: 'Предлог',
      enDefinition:
          'A word that shows the relationship between a noun and other '
          'words, such as direction, time, or place.',
      ruDefinition:
          'Слово, которое показывает связь существительного с другими '
          'словами: направление, время или место.',
      example: 'in, on, at',
    ),
    'conjunction': PartOfSpeechEntry(
      key: 'conjunction',
      enName: 'Conjunction',
      ruName: 'Союз',
      enDefinition: 'A word that connects words, phrases, or clauses.',
      ruDefinition:
          'Слово, которое соединяет слова, фразы или части предложения.',
      example: 'and, but, because',
    ),
    'interjection': PartOfSpeechEntry(
      key: 'interjection',
      enName: 'Interjection',
      ruName: 'Междометие',
      enDefinition: 'A short exclamation that expresses emotion.',
      ruDefinition: 'Короткое восклицание, которое выражает эмоцию.',
      example: 'oh, wow, ouch',
    ),
    'article': PartOfSpeechEntry(
      key: 'article',
      enName: 'Article',
      ruName: 'Артикль',
      enDefinition:
          'A word placed before a noun to define it as specific or '
          'unspecific.',
      ruDefinition:
          'Слово перед существительным, которое указывает на его '
          'определённость или неопределённость.',
      example: 'a, an, the',
    ),
    'numeral': PartOfSpeechEntry(
      key: 'numeral',
      enName: 'Numeral',
      ruName: 'Числительное',
      enDefinition: 'A word that expresses a number or quantity.',
      ruDefinition: 'Слово, которое обозначает число или количество.',
      example: 'one, two, first',
    ),
  };

  /// Пояснение для [partOfSpeech]; null — часть речи неизвестна или пуста.
  static PartOfSpeechEntry? lookup(String? partOfSpeech) {
    final key = (partOfSpeech ?? '').trim().toLowerCase();
    return entries[key];
  }
}
