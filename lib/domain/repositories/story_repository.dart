import 'package:english_edu/domain/entities/story.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';

/// Рассказы для чтения (ADR-039).
///
/// Только чтение: контент приходит из ассетов, пользователь его не правит —
/// поэтому ни `save`, ни `delete` в контракте нет.
abstract interface class StoryRepository {
  /// Все рассказы в порядке `id`.
  Future<List<Story>> getAll();

  /// Рассказы выбранного уровня CEFR.
  Future<List<Story>> getByLevel(CefrLevel level);

  /// Сколько рассказов загружено.
  Future<int> count();

  /// Атомарно вставляет рассказы (загрузка seed).
  Future<void> insertMany(Iterable<Story> stories);
}
