import 'package:drift/drift.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/domain/repositories/cloze_task_repository.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// `ClozeTaskRepository` поверх Drift (ADR-025).
///
/// Время генерации приходит из домена и только проверяется здесь: системные
/// часы в data-слое не читаются, иначе тесты стали бы недетерминированными.
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
    return ClozeTask(sentence: row.sentence, answer: row.answer);
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
            answer: task.answer,
            createdAtUtc: now.millisecondsSinceEpoch,
          ),
        );
  }
}
