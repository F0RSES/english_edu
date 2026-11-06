import 'dart:convert';
import 'dart:math';

/// Вердикт модели по одному слову.
///
/// Отдельный тип, а не `Map`: правила разбора (в том числе «невалидный JSON —
/// это проблема») живут в одном месте и покрываются тестами без сети.
class ReviewVerdict {
  /// Создаёт вердикт.
  const ReviewVerdict({
    required this.isCorrect,
    this.issues = const [],
    this.suggestedTranslation,
    this.suggestedPartOfSpeech,
  });

  /// Проблема разбора: ответ не удалось прочитать как JSON нужной формы.
  factory ReviewVerdict.unparsable(String reason) => ReviewVerdict(
    isCorrect: false,
    issues: ['parse error: $reason'],
  );

  /// Считает ли модель слово и перевод корректными.
  final bool isCorrect;

  /// Перечень найденных проблем.
  final List<String> issues;

  /// Предложенный перевод, если модель считает текущий неверным.
  final String? suggestedTranslation;

  /// Предложенная часть речи, если текущая неверна.
  final String? suggestedPartOfSpeech;

  @override
  String toString() =>
      'ReviewVerdict(correct: $isCorrect, issues: $issues, '
      'translation: $suggestedTranslation, '
      'partOfSpeech: $suggestedPartOfSpeech)';
}

/// Проблемное слово в отчёте — то, что попадёт в ручную правку.
class ReviewProblem {
  /// Создаёт запись проблемы.
  const ReviewProblem({
    required this.id,
    required this.term,
    required this.level,
    required this.translation,
    required this.partOfSpeech,
    required this.issues,
    required this.suggestedTranslation,
    required this.suggestedPartOfSpeech,
  });

  /// Идентификатор слова в seed.
  final int id;

  /// Английский термин.
  final String term;

  /// Уровень CEFR слова.
  final String? level;

  /// Текущий перевод.
  final String translation;

  /// Текущая часть речи.
  final String? partOfSpeech;

  /// Что не так по мнению модели.
  final List<String> issues;

  /// Предложенный перевод, если есть.
  final String? suggestedTranslation;

  /// Предложенная часть речи, если есть.
  final String? suggestedPartOfSpeech;

  /// Запись в выходном JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'term': term,
    'level': level,
    'translation': translation,
    'partOfSpeech': partOfSpeech,
    'issues': issues,
    'suggestedPartOfSpeech': suggestedPartOfSpeech,
  };
}

/// Разбирает ответ модели.
///
/// Модель регулярно оборачивает JSON в ```json … ``` и добавляет текст до или
/// после — это не ошибка, а шум. А вот невалидный JSON или отсутствие
/// `isCorrect` вердиктом считать нельзя: слово уходит в список проблем с
/// причиной, чтобы человек посмотрел его руками.
ReviewVerdict parseReviewVerdict(String raw) {
  final json = _extractJsonObject(raw);
  if (json == null) {
    return ReviewVerdict.unparsable('no JSON object in response');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (error) {
    return ReviewVerdict.unparsable(error.message);
  }

  if (decoded is! Map<String, Object?>) {
    return ReviewVerdict.unparsable('response is not a JSON object');
  }

  final isCorrect = decoded['isCorrect'];
  if (isCorrect is! bool) {
    return ReviewVerdict.unparsable('isCorrect is missing or not a bool');
  }

  return ReviewVerdict(
    isCorrect: isCorrect,
    issues: _stringList(decoded['issues']),
    suggestedTranslation: _stringOrNull(decoded['suggestedTranslation']),
    suggestedPartOfSpeech: _stringOrNull(decoded['suggestedPartOfSpeech']),
  );
}

/// Отбирает слова для проверки: фильтр по уровням и случайная выборка.
///
/// [levels] — метки CEFR без учёта регистра; null или пустое множество
/// означают «все уровни». [sample] ограничивает выборку уже после фильтра,
/// [random] инжектится, чтобы тесты были детерминированными.
List<Map<String, Object?>> selectWords(
  List<Map<String, Object?>> words, {
  Set<String>? levels,
  int? sample,
  Random? random,
}) {
  final normalizedLevels = levels
      ?.map((level) => level.trim().toUpperCase())
      .where((level) => level.isNotEmpty)
      .toSet();

  final filtered = [
    for (final word in words)
      if (normalizedLevels == null ||
          normalizedLevels.isEmpty ||
          normalizedLevels.contains((word['level'] as String?)?.toUpperCase()))
        word,
  ];

  if (sample == null || sample >= filtered.length) {
    return filtered;
  }
  if (sample <= 0) {
    return const [];
  }

  // Перемешиваем копию: порядок входного файла не должен влиять на выборку.
  final shuffled = [...filtered]..shuffle(random ?? Random());
  return shuffled.take(sample).toList();
}

/// Собирает выходной отчёт.
Map<String, Object?> buildReviewReport({
  required DateTime reviewedAt,
  required int totalWords,
  required int checkedCount,
  required List<ReviewProblem> problems,
}) => {
  'reviewedAt': reviewedAt.toUtc().toIso8601String(),
  'totalWords': totalWords,
  'checkedCount': checkedCount,
  'problemsFound': problems.length,
  'problems': [for (final problem in problems) problem.toJson()],
};

/// Доля проблем в процентах; 0 при пустой выборке.
double problemRate({required int checkedCount, required int problemsFound}) =>
    checkedCount == 0 ? 0 : problemsFound * 100 / checkedCount;

/// Строка итога для stdout.
String formatSummary({required int checkedCount, required int problemsFound}) {
  final rate = problemRate(
    checkedCount: checkedCount,
    problemsFound: problemsFound,
  );
  return 'Checked $checkedCount words, '
      'found $problemsFound problems (${rate.toStringAsFixed(1)}%)';
}

String? _extractJsonObject(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) {
    return null;
  }
  return raw.substring(start, end + 1);
}

List<String> _stringList(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
];


/// Результат применения ручных правок к словарю.
class OverrideResult {
  /// Создаёт результат.
  const OverrideResult({required this.applied, required this.missingTerms});

  /// Сколько правок применено.
  final int applied;

  /// Термины из файла правок, которых не оказалось в словаре.
  final List<String> missingTerms;
}

/// Применяет ручные правки к словам (BL-21).
///
/// Правки живут отдельным файлом, а не в `words_v2.json`: слитый словарь —
/// производный артефакт, и `merge_seeds` перезаписывает его целиком. Отдельный
/// файл переживает пересборку, поэтому ручной труд не теряется.
///
/// Совпадение по `term` без учёта регистра и пробелов по краям. Меняются
/// только поля, которые есть в правке: остальное остаётся как было.
/// Термин, которого нет в словаре, — не ошибка, а повод предупредить: словарь
/// мог измениться, и молча терять правку нельзя.
OverrideResult applyManualOverrides(
  List<Map<String, Object?>> words,
  List<Map<String, Object?>> overrides,
) {
  final byTerm = <String, List<Map<String, Object?>>>{};
  for (final word in words) {
    final term = _normalizeTerm(word['term']);
    if (term.isEmpty) {
      continue;
    }
    (byTerm[term] ??= []).add(word);
  }

  var applied = 0;
  final missing = <String>[];

  for (final override in overrides) {
    final term = _normalizeTerm(override['term']);
    if (term.isEmpty) {
      continue;
    }

    final matches = byTerm[term];
    if (matches == null || matches.isEmpty) {
      missing.add(term);
      continue;
    }

    for (final word in matches) {
      _copyIfPresent(override, word, 'translation');
      _copyIfPresent(override, word, 'partOfSpeech');
      _copyIfPresent(override, word, 'autoTranslated');
    }
    applied++;
  }

  return OverrideResult(applied: applied, missingTerms: missing);
}

String _normalizeTerm(Object? value) =>
    value is String ? value.trim().toLowerCase() : '';

void _copyIfPresent(
  Map<String, Object?> source,
  Map<String, Object?> target,
  String key,
) {
  if (source.containsKey(key)) {
    target[key] = source[key];
  }
}

String? _stringOrNull(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty || trimmed == 'null' ? null : trimmed;
}
