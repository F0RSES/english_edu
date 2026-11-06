import 'package:english_edu/domain/repositories/cloze_task_repository.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Кэш заданий в памяти для тестов use case (ADR-025).
final class FakeClozeTaskRepository implements ClozeTaskRepository {
  /// Создаёт фейк с необязательной начальной записью.
  FakeClozeTaskRepository({WordId? wordId, ClozeTask? task}) {
    if (wordId != null && task != null) {
      _byWordId[wordId] = task;
    }
  }

  final Map<WordId, ClozeTask> _byWordId = {};
  int saveCalls = 0;
  DateTime? lastSavedAt;

  @override
  Future<ClozeTask?> getByWordId(WordId wordId) async => _byWordId[wordId];

  @override
  Future<void> save(WordId wordId, ClozeTask task, DateTime now) async {
    saveCalls++;
    lastSavedAt = now;
    _byWordId[wordId] = task;
  }
}
