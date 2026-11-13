import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/cloze_task_repository.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// `ClozeTaskRepository` поверх Drift (ADR-025).
///
/// Время генерации приходит из домена и только проверяется здесь: системные
/// часы в data-слое не читаются, иначе тесты стали бы недетерминированными.
/// Варианты хранятся JSON-массивом в колонке `options` (schema v16); колонка
/// `answer` исторически хранит правильный вариант (`correctWord` в домене).
final class DriftClozeTaskRepository implements ClozeTaskRepository {
  /// Создаёт репозиторий поверх открытой базы.
  const DriftClozeTaskRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ClozeTask?> getByWordId(WordId wordId) async {
    final row =
        await (_db.select(_db.clozeTasks)
              ..where((t) => t.wordId.equals(wordId.value))
              ..limit(1))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final rawOptions = row.options;
    if (rawOptions == null) {
      // Запись до v16: без вариантов задание неиграбельно — кэш инвалидируем,
      // GetClozeTask перегенерирует его через AI.
      return null;
    }
    final options = _decodeOptions(rawOptions);
    if (options == null) {
      return null;
    }
    return ClozeTask(
      sentence: row.sentence,
      correctWord: row.answer,
      options: options,
    );
  }

  @override
  Future<void> save(WordId wordId, ClozeTask task, DateTime now) async {
    // Проверка дублирует контракт: в release assert вырезан, а локальное время
    // в БД испортило бы сравнения и экспорт.
    if (!now.isUtc) {
      throw ArgumentError.value(now, 'now', 'must be UTC');
    }
    await _db
        .into(_db.clozeTasks)
        .insertOnConflictUpdate(
          ClozeTasksCompanion.insert(
            wordId: Value(wordId.value),
            sentence: task.sentence,
            answer: task.correctWord,
            options: Value(jsonEncode(task.options)),
            createdAtUtc: now.millisecondsSinceEpoch,
          ),
        );
  }

  /// Разбирает JSON-массив вариантов; null — повреждённый или старый кэш.
  List<String>? _decodeOptions(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! List<Object?> || decoded.length != 5) {
      return null;
    }
    final options = <String>[];
    for (final option in decoded) {
      if (option is! String) {
        return null;
      }
      options.add(option);
    }
    return options;
  }
}
