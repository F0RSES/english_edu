/// Части речи, допустимые в seed-файле.
const allowedPartsOfSpeech = <String>{
  'article',
  'verb',
  'preposition',
  'conjunction',
  'pronoun',
  'adverb',
  'adjective',
  'noun',
  'interjection',
  'numeral',
};

/// Приводит `partOfSpeech` из ответа модели к одному значению из списка.
///
/// Модель регулярно отвечает `noun|adjective`, `verb, noun` или `adv/adj`,
/// а формат ждёт ровно одно значение. Берём первую часть, которая входит в
/// [allowedPartsOfSpeech]; если ни одна не подходит — `null`.
///
/// `null` вместо ошибки: поле необязательное, слово без части речи полезнее
/// выброшенного слова. Функция живёт в общей библиотеке инструментов, а не в
/// генераторе, чтобы правило покрывалось тестами без CLI и сети.
String? sanitizePartOfSpeech(String? raw) {
  if (raw == null) {
    return null;
  }
  for (final part in raw.split(RegExp('[|,/]'))) {
    final normalized = part.trim().toLowerCase();
    if (allowedPartsOfSpeech.contains(normalized)) {
      return normalized;
    }
  }
  return null;
}

/// Уровни CEFR, допустимые в seed-файле (ADR-023).
///
/// Список дублирует `CefrLevel.label` из приложения: tools не импортируют
/// `lib/`, иначе валидатор тянул бы за собой domain ради семи строк. Расхождение
/// ловится тестом на shipped-файл.
const allowedCefrLevels = <String>{'A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};

/// Результат проверки seed-файла.
final class SeedValidationResult {
  /// Создаёт результат проверки.
  SeedValidationResult({
    required this.errors,
    required this.warnings,
    required this.wordCount,
    required this.sourceCount,
  });

  /// Блокирующие ошибки; при непустом списке файл не принимается.
  final List<String> errors;

  /// Некритичные замечания.
  final List<String> warnings;

  /// Число слов в файле.
  final int wordCount;

  /// Число источников в файле.
  final int sourceCount;

  /// Истина, когда блокирующих ошибок нет.
  bool get isValid => errors.isEmpty;
}

/// Проверяет разобранный seed-файл и возвращает результат.
///
/// Чистая функция: без I/O и без сторонних пакетов. Ошибки собираются все
/// сразу, чтобы автор контента видел полный список проблем.
SeedValidationResult validateSeed(Object? json) {
  final errors = <String>[];
  final warnings = <String>[];

  if (json is! Map<String, Object?>) {
    return SeedValidationResult(
      errors: ['root must be a JSON object'],
      warnings: warnings,
      wordCount: 0,
      sourceCount: 0,
    );
  }

  final schemaVersion = json['schemaVersion'];
  if (schemaVersion != 1) {
    errors.add('schemaVersion must be 1, got $schemaVersion');
  }

  final sourceIds = _validateSources(json['sources'], errors);
  final wordCount = _validateWords(json['words'], sourceIds, errors, warnings);

  return SeedValidationResult(
    errors: errors,
    warnings: warnings,
    wordCount: wordCount,
    sourceCount: sourceIds.length,
  );
}

Set<String> _validateSources(Object? raw, List<String> errors) {
  if (raw is! List || raw.isEmpty) {
    errors.add('sources must be a non-empty array');
    return <String>{};
  }
  final ids = <String>{};
  for (var index = 0; index < raw.length; index++) {
    final item = raw[index];
    final path = 'sources[$index]';
    if (item is! Map<String, Object?>) {
      errors.add('$path must be an object');
      continue;
    }
    final id = item['id'];
    if (id is! String || id.trim().isEmpty) {
      errors.add('$path.id must be a non-empty string');
    } else if (!ids.add(id)) {
      errors.add('$path.id is a duplicate: $id');
    }
    if (!_isNonEmptyText(item['name'])) {
      errors.add('$path.name must be a non-empty string');
    }
    if (!_isNonEmptyText(item['license'])) {
      errors.add('$path.license must be a non-empty string');
    }
  }
  return ids;
}

int _validateWords(
  Object? raw,
  Set<String> sourceIds,
  List<String> errors,
  List<String> warnings,
) {
  if (raw is! List || raw.isEmpty) {
    errors.add('words must be a non-empty array');
    return 0;
  }
  final ids = <int>{};
  final terms = <String>{};
  var count = 0;

  for (var index = 0; index < raw.length; index++) {
    final item = raw[index];
    final path = 'words[$index]';
    if (item is! Map<String, Object?>) {
      errors.add('$path must be an object');
      continue;
    }
    count++;
    _validateWord(item, path, sourceIds, errors, warnings);

    final id = item['id'];
    if (id is int && !ids.add(id)) {
      errors.add('$path.id is a duplicate: $id');
    }
    final term = item['term'];
    if (term is String && !terms.add(term)) {
      warnings.add('$path.term is a duplicate: $term');
    }
  }
  return count;
}

void _validateWord(
  Map<String, Object?> word,
  String path,
  Set<String> sourceIds,
  List<String> errors,
  List<String> warnings,
) {
  final id = word['id'];
  if (id is! int || id <= 0) {
    errors.add('$path.id must be a positive integer');
  }

  final term = word['term'];
  if (term is! String || term.trim().isEmpty) {
    errors.add('$path.term must be a non-empty string');
  } else if (term != term.trim() || term != term.toLowerCase()) {
    errors.add('$path.term must be trimmed and lower-case: $term');
  }

  if (!_isNonEmptyText(word['translation'])) {
    errors.add('$path.translation must be a non-empty string');
  }

  final sourceId = word['sourceId'];
  if (sourceId is! String || !sourceIds.contains(sourceId)) {
    errors.add('$path.sourceId is not declared in sources: $sourceId');
  }

  final rank = word['frequencyRank'];
  if (rank != null && (rank is! int || rank < 0)) {
    // frequencyRank — informational: уникальность имеет смысл только внутри
    // одного sourceId, глобальных предупреждений о пересечении рангов нет.
    errors.add('$path.frequencyRank must be a non-negative integer');
  }

  final partOfSpeech = word['partOfSpeech'];
  if (partOfSpeech != null &&
      (partOfSpeech is! String ||
          !allowedPartsOfSpeech.contains(partOfSpeech))) {
    errors.add('$path.partOfSpeech is not allowed: $partOfSpeech');
  }

  final transcription = word['transcription'];
  if (transcription != null) {
    final wrapped =
        transcription is String &&
        transcription.length > 1 &&
        transcription.startsWith('/') &&
        transcription.endsWith('/');
    if (!wrapped) {
      errors.add('$path.transcription must be wrapped in slashes');
    }
  }

  final autoTranslated = word['autoTranslated'];
  if (autoTranslated != null && autoTranslated is! bool) {
    errors.add('$path.autoTranslated must be a boolean');
  } else if (autoTranslated == true) {
    warnings.add('$path.autoTranslated is true: pending review');
  }

  final level = word['level'];
  if (level == null) {
    // A1 — дефолт приложения, а не ошибка формата: предупреждаем, чтобы автор
    // контента видел неразмеченные слова (Phase 13b, BL-65).
    warnings.add('$path.level is missing: defaults to A1');
  } else if (level is! String) {
    errors.add('$path.level must be a string: $level');
  } else if (!allowedCefrLevels.contains(level.toUpperCase())) {
    errors.add('$path.level is not a valid CEFR level: $level');
  }

  final example = word['exampleSentence'];
  if (example != null && !_isNonEmptyText(example)) {
    errors.add('$path.exampleSentence must be a non-empty string');
  }
}

bool _isNonEmptyText(Object? value) =>
    value is String && value.trim().isNotEmpty;
