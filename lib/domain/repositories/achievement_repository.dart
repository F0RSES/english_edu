import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';

/// Хранилище достижений (ADR-035).
///
/// Одна строка на тип: прогресс перезаписывается, история не нужна — она
/// выводится из журнала ответов и статистики.
abstract interface class AchievementRepository {
  /// Все сохранённые достижения (только те, что уже встречались).
  Future<List<Achievement>> getAll();

  /// Состояние конкретного достижения или null, если его ещё не считали.
  Future<Achievement?> getByType(AchievementType type);

  /// Сохраняет состояние; повторная запись заменяет предыдущую.
  Future<void> save(Achievement achievement);
}
