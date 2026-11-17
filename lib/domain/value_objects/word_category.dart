/// Тематическая категория слова для двойного фильтра словаря (Phase 39a).
///
/// 22 темы плюс `all` — «фильтр по категории выключен». Метки для UI живут
/// в `S` (ADR-043): domain не зависит от core/localization. Здесь — только
/// стабильный `key` и токены матчинга данных (`tokens`), включая алиасы
/// старых пользовательских категорий («IT», «Быт», «Путешествия»).
enum WordCategory {
  /// Фильтр по категории выключен: подходит любое слово.
  all(key: 'all', tokens: {}),

  /// Животные.
  animals(key: 'animals', tokens: {'животные', 'animals'}),

  /// Природа.
  nature(key: 'nature', tokens: {'природа', 'nature'}),

  /// Еда.
  food(key: 'food', tokens: {'еда', 'food'}),

  /// Глаголы: матчинг также по partOfSpeech == 'verb'.
  verbs(key: 'verbs', tokens: {'глаголы', 'verbs'}, partOfSpeech: 'verb'),

  /// Наречия: матчинг также по partOfSpeech == 'adverb'.
  adverbs(
    key: 'adverbs',
    tokens: {'наречия', 'adverbs'},
    partOfSpeech: 'adverb',
  ),

  /// Прилагательные: матчинг также по partOfSpeech == 'adjective'.
  adjectives(
    key: 'adjectives',
    tokens: {'прилагательные', 'adjectives'},
    partOfSpeech: 'adjective',
  ),

  /// Дом; алиас «Быт» — старая пользовательская категория.
  home(key: 'home', tokens: {'дом', 'home', 'быт'}),

  /// Одежда.
  clothes(key: 'clothes', tokens: {'одежда', 'clothes'}),

  /// Хобби.
  hobbies(key: 'hobbies', tokens: {'хобби', 'hobbies'}),

  /// Дата и время.
  datetime(
    key: 'datetime',
    tokens: {'дата и время', 'date & time', 'datetime'},
  ),

  /// Языки.
  languages(key: 'languages', tokens: {'языки', 'languages'}),

  /// Страны.
  countries(key: 'countries', tokens: {'страны', 'countries'}),

  /// Цвета.
  colors(key: 'colors', tokens: {'цвета', 'colors'}),

  /// Транспорт.
  transport(key: 'transport', tokens: {'транспорт', 'transport'}),

  /// Компьютеры; алиас «IT» — старая пользовательская категория.
  computers(key: 'computers', tokens: {'компьютеры', 'computers', 'it', 'ит'}),

  /// Путешествия.
  travel(key: 'travel', tokens: {'путешествия', 'travel'}),

  /// Здоровье.
  health(key: 'health', tokens: {'здоровье', 'health'}),

  /// Тело.
  body(key: 'body', tokens: {'тело', 'body'}),

  /// Погода.
  weather(key: 'weather', tokens: {'погода', 'weather'}),

  /// Школа.
  school(key: 'school', tokens: {'школа', 'school'}),

  /// Профессии.
  professions(key: 'professions', tokens: {'профессии', 'professions'}),

  /// Семья.
  family(key: 'family', tokens: {'семья', 'family'});

  const WordCategory({
    required this.key,
    required this.tokens,
    this.partOfSpeech,
  });

  /// Стабильный английский идентификатор категории.
  final String key;

  /// Токены матчинга пользовательской категории: ru/en имена и алиасы,
  /// в нижнем регистре. Сравнение — trim + lowercase.
  final Set<String> tokens;

  /// Часть речи для POS-категорий (verbs/adverbs/adjectives); у остальных
  /// null. Позволяет фильтровать seed, где `category` не размечена.
  final String? partOfSpeech;

  /// Разбирает строку категории: key, ru/en имя или алиас, без регистра.
  ///
  /// Бросает [ArgumentError] на неизвестном значении (паттерн
  /// `CefrLevel.fromLabel`): молчаливая подмена исказила бы фильтр.
  static WordCategory fromString(String value) {
    final normalized = value.trim().toLowerCase();
    for (final category in WordCategory.values) {
      if (category.key == normalized || category.tokens.contains(normalized)) {
        return category;
      }
    }
    throw ArgumentError('Unknown word category: $value');
  }

  /// Подходит ли слово под категорию.
  ///
  /// `all` — всегда. POS-категории проверяют И часть речи, И строку
  /// категории; остальные — только строку категории (key, ru/en имя, алиас).
  /// Null/пустая категория и несовпавшая часть речи — не совпадение.
  bool matches({String? category, String? partOfSpeech}) {
    if (this == WordCategory.all) {
      return true;
    }
    final pos = this.partOfSpeech;
    if (pos != null && partOfSpeech?.trim().toLowerCase() == pos) {
      return true;
    }
    final normalized = category?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    return normalized == key || tokens.contains(normalized);
  }
}
