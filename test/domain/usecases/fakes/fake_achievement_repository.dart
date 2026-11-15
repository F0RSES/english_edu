import 'package:english_edu/domain/repositories/achievement_repository.dart';
import 'package:english_edu/domain/value_objects/achievement.dart';
import 'package:english_edu/domain/value_objects/achievement_type.dart';

/// Достижения в памяти: провайдеры и экраны проверяются без БД.
final class FakeAchievementRepository implements AchievementRepository {
  /// Создаёт фейк; [seed] — уже сохранённые достижения.
  FakeAchievementRepository([Iterable<Achievement> seed = const []]) {
    for (final item in seed) {
      _items[item.type.key] = item;
    }
  }

  final Map<String, Achievement> _items = {};

  @override
  Future<List<Achievement>> getAll() async => _items.values.toList();

  @override
  Future<Achievement?> getByType(AchievementType type) async =>
      _items[type.key];

  @override
  Future<void> save(Achievement achievement) async {
    _items[achievement.type.key] = achievement;
  }
}
