import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Кэш заданий «Заполни пропуск» (Phase 14a, ADR-025).
///
/// Одна запись на слово: сгенерированное задание переиспользуется, поэтому
/// сеть нужна только при первом показе слова. Время приходит снаружи —
/// data-слой системные часы не читает.
abstract interface class ClozeTaskRepository {
  /// Возвращает сохранённое задание для [wordId] или null.
  Future<ClozeTask?> getByWordId(WordId wordId);

  /// Сохраняет [task] для [wordId]; повторная запись заменяет предыдущую.
  ///
  /// [now] должен быть в UTC: локальное время в БД не хранится.
  Future<void> save(WordId wordId, ClozeTask task, DateTime now);
}
