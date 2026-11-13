import 'dart:convert';

import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// JSON-представление снимка состояния, схема v1.
///
/// Формат принадлежит data-слою (см. `ExportPayload`): домен знает только
/// структуру, а сериализация живёт рядом с остальными преобразованиями.
/// Все моменты времени пишутся в UTC ISO-8601 — локальное время в файл не
/// попадает, иначе импорт в другом часовом поясе сдвинул бы расписание.
final class ExportPayloadCodec {
  /// Создаёт кодек.
  const ExportPayloadCodec();

  /// Сериализует [payload] в компактный JSON.
  String encode(ExportPayload payload) => jsonEncode({
    'schemaVersion': payload.schemaVersion,
    'exportedAt': payload.exportedAt.toUtc().toIso8601String(),
    'settings': _settingsToJson(payload.settings),
    'words': [for (final word in payload.words) _wordToJson(word)],
    'progress': [for (final item in payload.progress) _progressToJson(item)],
    'logs': [for (final log in payload.logs) _logToJson(log)],
    'stats': [for (final stats in payload.stats) _statsToJson(stats)],
  });

  Map<String, Object?> _settingsToJson(UserSettings settings) => {
    'dailyNewLimit': settings.dailyNewLimit,
    'dailyReviewLimit': settings.dailyReviewLimit,
    'remindersEnabled': settings.remindersEnabled,
    'reminderHour': settings.reminderHour,
    'reminderMinute': settings.reminderMinute,
    'ttsVoice': settings.ttsVoice,
    'ttsSpeed': settings.ttsSpeed,
  };

  Map<String, Object?> _wordToJson(Word word) => {
    'id': word.id.value,
    'term': word.term,
    'translation': word.translation,
    'transcription': word.transcription,
    'partOfSpeech': word.partOfSpeech,
    'exampleSentence': word.exampleSentence,
  };

  Map<String, Object?> _progressToJson(WordProgress progress) => {
    'wordId': progress.wordId.value,
    'cardState': _cardStateToJson(progress.cardState),
    'status': progress.status.name,
    'firstSeenAt': progress.firstSeenAt.toIso8601String(),
    'lastReviewedAt': progress.lastReviewedAt?.toIso8601String(),
  };

  Map<String, Object?> _cardStateToJson(CardState state) => {
    'easePermille': state.easePermille,
    'intervalDays': state.intervalDays,
    'repetitions': state.repetitions,
    'lapses': state.lapses,
    'dueAt': state.dueAt.toIso8601String(),
  };

  Map<String, Object?> _logToJson(ReviewLog log) => {
    'id': log.id.value,
    'wordId': log.wordId.value,
    'reviewedAt': log.reviewedAt.toIso8601String(),
    'grade': log.grade.name,
    'previousCardState': _cardStateToJson(log.previousCardState),
    'newCardState': _cardStateToJson(log.newCardState),
  };

  Map<String, Object?> _statsToJson(DailyStats stats) => {
    'date': stats.date.daysSinceEpoch,
    'newWordsStudied': stats.newWordsStudied,
    'reviewsCompleted': stats.reviewsCompleted,
    'xpGained': stats.xpGained,
    'correctAnswers': stats.correctAnswers,
  };

  /// Разбирает JSON, созданный [encode].
  ///
  /// Бросает [FormatException], если структура не соответствует схеме v1:
  /// диалог импорта показывает текст ошибки, а не stack trace.
  ExportPayload decode(String source) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Некорректный JSON: ${error.message}');
    }
    final root = _asMap(raw, 'корень');
    return ExportPayload(
      schemaVersion: _int(root, 'schemaVersion'),
      exportedAt: _date(root, 'exportedAt'),
      settings: _settingsFromJson(_asMap(root['settings'], 'settings')),
      words: [
        for (final item in _list(root, 'words'))
          _wordFromJson(_asMap(item, 'words[]')),
      ],
      progress: [
        for (final item in _list(root, 'progress'))
          _progressFromJson(_asMap(item, 'progress[]')),
      ],
      logs: [
        for (final item in _list(root, 'logs'))
          _logFromJson(_asMap(item, 'logs[]')),
      ],
      stats: [
        for (final item in _list(root, 'stats'))
          _statsFromJson(_asMap(item, 'stats[]')),
      ],
    );
  }

  UserSettings _settingsFromJson(Map<String, Object?> map) => UserSettings(
    dailyNewLimit: _int(map, 'dailyNewLimit'),
    dailyReviewLimit: _int(map, 'dailyReviewLimit'),
    remindersEnabled: _bool(map, 'remindersEnabled'),
    reminderHour: _int(map, 'reminderHour'),
    reminderMinute: _int(map, 'reminderMinute'),
    ttsVoice: _str(map, 'ttsVoice'),
    ttsSpeed: _double(map, 'ttsSpeed'),
  );

  Word _wordFromJson(Map<String, Object?> map) => Word(
    id: WordId(_int(map, 'id')),
    term: _str(map, 'term'),
    translation: _str(map, 'translation'),
    transcription: _strOrNull(map, 'transcription'),
    partOfSpeech: _strOrNull(map, 'partOfSpeech'),
    exampleSentence: _strOrNull(map, 'exampleSentence'),
  );

  WordProgress _progressFromJson(Map<String, Object?> map) => WordProgress(
    wordId: WordId(_int(map, 'wordId')),
    cardState: _cardStateFromJson(_asMap(map['cardState'], 'cardState')),
    status: _status(_str(map, 'status')),
    firstSeenAt: _date(map, 'firstSeenAt'),
    lastReviewedAt: _strOrNull(map, 'lastReviewedAt') == null
        ? null
        : _date(map, 'lastReviewedAt'),
  );

  CardState _cardStateFromJson(Map<String, Object?> map) => CardState(
    easePermille: _int(map, 'easePermille'),
    intervalDays: _int(map, 'intervalDays'),
    repetitions: _int(map, 'repetitions'),
    lapses: _int(map, 'lapses'),
    dueAt: _date(map, 'dueAt'),
  );

  ReviewLog _logFromJson(Map<String, Object?> map) => ReviewLog(
    id: ReviewLogId(_int(map, 'id')),
    wordId: WordId(_int(map, 'wordId')),
    reviewedAt: _date(map, 'reviewedAt'),
    grade: _grade(_str(map, 'grade')),
    previousCardState: _cardStateFromJson(
      _asMap(map['previousCardState'], 'previous'),
    ),
    newCardState: _cardStateFromJson(_asMap(map['newCardState'], 'next')),
  );

  DailyStats _statsFromJson(Map<String, Object?> map) => DailyStats(
    date: LocalDate(_int(map, 'date')),
    newWordsStudied: _int(map, 'newWordsStudied'),
    reviewsCompleted: _int(map, 'reviewsCompleted'),
    xpGained: _int(map, 'xpGained'),
    correctAnswers: _int(map, 'correctAnswers'),
  );
}

/// Разбор вспомогательных значений: любое расхождение — [FormatException].
Map<String, Object?> _asMap(Object? value, String name) {
  if (value is Map<String, Object?>) {
    return value;
  }
  throw FormatException('$name: ожидался объект');
}

List<Object?> _list(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is List<Object?>) {
    return value;
  }
  throw FormatException('$key: ожидался массив');
}

int _int(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('$key: ожидалось целое число');
}

double _double(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('$key: ожидалось число');
}

bool _bool(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is bool) {
    return value;
  }
  throw FormatException('$key: ожидалось true/false');
}

String _str(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String) {
    return value;
  }
  throw FormatException('$key: ожидалась строка');
}

String? _strOrNull(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('$key: ожидалась строка или null');
}

DateTime _date(Map<String, Object?> map, String key) {
  final value = _str(map, key);
  final parsed = DateTime.parse(value);
  return parsed.toUtc();
}

WordStatus _status(String name) => WordStatus.values.firstWhere(
  (value) => value.name == name,
  orElse: () => throw FormatException('status: неизвестное значение $name'),
);

ReviewGrade _grade(String name) => ReviewGrade.values.firstWhere(
  (value) => value.name == name,
  orElse: () => throw FormatException('grade: неизвестное значение $name'),
);
