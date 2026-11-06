import 'dart:convert';

import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/entities/user_settings.dart';
import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/export_payload.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';
import 'package:english_edu/domain/value_objects/review_grade.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Первая версия снимка, в которой появился `frozenDays`.
const _frozenDaysSinceVersion = 2;

/// Первая версия снимка, в которой появился `Word.category`.
const _categorySinceVersion = 3;

/// Первая версия снимка, в которой появился `Word.level` (ADR-023).
const _levelSinceVersion = 4;

/// Первая версия снимка, в которой появился `UserSettings.preferredLevel`
/// (BL-68).
const _preferredLevelSinceVersion = 5;

/// JSON-представление снимка состояния, схема v4 (v1–v3 читаются).
///
/// Версии и поля слов:
///
/// | Версия | Что появилось |
/// |---|---|
/// | v1 | базовая схема |
/// | v2 | `frozenDays` |
/// | v3 | `Word.category` |
/// | v4 | `Word.level` |
/// | v5 | `UserSettings.preferredLevel` |
///
/// Старший снимок читается с дефолтами: `frozenDays` пустой, `category` null,
/// `level` A1, `preferredLevel` A1.
///
/// Формат принадлежит data-слою (см. `ExportPayload`): домен знает только
/// структуру, а сериализация живёт рядом с остальными преобразованиями.
/// Все моменты времени пишутся в UTC ISO-8601 — локальное время в файл не
/// попадает, иначе импорт в другом часовом поясе сдвинул бы расписание.
final class ExportPayloadCodec {
  /// Создаёт кодек.
  const ExportPayloadCodec();

  /// Сериализует [payload] в компактный JSON.
  ///
  /// Версия берётся из payload: кодек не подменяет её, иначе объект в памяти и
  /// JSON расходились бы. `frozenDays` пишется всегда — в v1-снимке он пуст.
  String encode(ExportPayload payload) => jsonEncode({
    'schemaVersion': payload.schemaVersion,
    'exportedAt': payload.exportedAt.toUtc().toIso8601String(),
    'settings': _settingsToJson(
      payload.settings,
      version: payload.schemaVersion,
    ),
    'words': [
      for (final word in payload.words)
        _wordToJson(word, version: payload.schemaVersion),
    ],
    'progress': [for (final item in payload.progress) _progressToJson(item)],
    'logs': [for (final log in payload.logs) _logToJson(log)],
    'stats': [for (final stats in payload.stats) _statsToJson(stats)],
    'frozenDays': [for (final date in payload.frozenDays) date.daysSinceEpoch],
  });

  Map<String, Object?> _settingsToJson(
    UserSettings settings, {
    required int version,
  }) => {
    'dailyNewLimit': settings.dailyNewLimit,
    'dailyReviewLimit': settings.dailyReviewLimit,
    'remindersEnabled': settings.remindersEnabled,
    'reminderHour': settings.reminderHour,
    'reminderMinute': settings.reminderMinute,
    'ttsVoice': settings.ttsVoice,
    'ttsSpeed': settings.ttsSpeed,
    // В снимках v1–v4 уровня пользователя не было (BL-68).
    if (version >= _preferredLevelSinceVersion)
      'preferredLevel': settings.preferredLevel.label,
  };

  Map<String, Object?> _wordToJson(Word word, {required int version}) => {
    'id': word.id.value,
    'term': word.term,
    'translation': word.translation,
    'transcription': word.transcription,
    'partOfSpeech': word.partOfSpeech,
    'exampleSentence': word.exampleSentence,
    // В снимках v1/v2 поля не было: не пишем его и для обратной совместимости.
    if (version >= _categorySinceVersion) 'category': word.category,
    // Метка, а не индекс enum: снимок должен читаться после перестановки
    // значений в коде (ADR-023).
    if (version >= _levelSinceVersion) 'level': word.level.label,
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
  /// Бросает [FormatException], если структура не соответствует схеме или
  /// версия неизвестна: диалог импорта показывает текст ошибки, а не stack
  /// trace. Обратная совместимость: снимок v1 читается с пустым `frozenDays`,
  /// v1–v3 — со всеми словами уровня A1.
  ExportPayload decode(String source) {
    final Object? raw;
    try {
      raw = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Некорректный JSON: ${error.message}');
    }
    final root = _asMap(raw, 'корень');
    final version = _int(root, 'schemaVersion');
    if (version < 1 || version > ExportPayload.currentSchemaVersion) {
      throw FormatException('schemaVersion: неподдерживаемая версия $version');
    }
    return ExportPayload(
      schemaVersion: version,
      exportedAt: _date(root, 'exportedAt'),
      settings: _settingsFromJson(
        _asMap(root['settings'], 'settings'),
        version,
      ),
      words: [
        for (final item in _list(root, 'words'))
          _wordFromJson(_asMap(item, 'words[]'), version),
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
      frozenDays: _frozenDaysFromJson(root, version),
    );
  }

  /// Заморозки: появились в v2, в v1 их не было.
  Set<LocalDate> _frozenDaysFromJson(Map<String, Object?> root, int version) {
    if (version < _frozenDaysSinceVersion) {
      return const <LocalDate>{};
    }
    return {
      for (final item in _list(root, 'frozenDays'))
        LocalDate(_asInt(item, 'frozenDays[]')),
    };
  }

  UserSettings _settingsFromJson(Map<String, Object?> map, int version) =>
      UserSettings(
        dailyNewLimit: _int(map, 'dailyNewLimit'),
        dailyReviewLimit: _int(map, 'dailyReviewLimit'),
        remindersEnabled: _bool(map, 'remindersEnabled'),
        reminderHour: _int(map, 'reminderHour'),
        reminderMinute: _int(map, 'reminderMinute'),
        ttsVoice: _str(map, 'ttsVoice'),
        ttsSpeed: _double(map, 'ttsSpeed'),
        preferredLevel: _preferredLevelFromJson(map, version),
      );

  /// Уровень пользователя из снимка; в v1–v4 поля не было — получаем A1.
  CefrLevel _preferredLevelFromJson(Map<String, Object?> map, int version) {
    if (version < _preferredLevelSinceVersion) {
      return CefrLevel.a1;
    }
    final label = _str(map, 'preferredLevel');
    for (final level in CefrLevel.values) {
      if (level.label.toLowerCase() == label.toLowerCase()) {
        return level;
      }
    }
    throw FormatException('preferredLevel: неизвестное значение $label');
  }

  Word _wordFromJson(Map<String, Object?> map, int version) => Word(
    id: WordId(_int(map, 'id')),
    term: _str(map, 'term'),
    translation: _str(map, 'translation'),
    transcription: _strOrNull(map, 'transcription'),
    partOfSpeech: _strOrNull(map, 'partOfSpeech'),
    exampleSentence: _strOrNull(map, 'exampleSentence'),
    // В v1/v2 категории не было — читаем только из снимков v3+.
    category: version >= _categorySinceVersion
        ? _strOrNull(map, 'category')
        : null,
    level: _levelFromJson(map, version),
  );

  /// Уровень слова из снимка; в v1–v3 поля не было — получаем A1.
  ///
  /// Неизвестная метка — [FormatException], а не `ArgumentError` из
  /// `CefrLevel.fromLabel`: импорт сообщает о плохом файле, а не падает.
  CefrLevel _levelFromJson(Map<String, Object?> map, int version) {
    if (version < _levelSinceVersion) {
      return CefrLevel.a1;
    }
    final label = _str(map, 'level');
    for (final level in CefrLevel.values) {
      if (level.label.toLowerCase() == label.toLowerCase()) {
        return level;
      }
    }
    throw FormatException('level: неизвестное значение $label');
  }

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

/// Целое из элемента массива: любое расхождение — [FormatException].
int _asInt(Object? value, String name) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('$name: ожидалось целое число');
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
