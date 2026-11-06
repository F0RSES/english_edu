import 'package:english_edu/domain/repositories/challenge_streak_repository.dart';
import 'package:english_edu/domain/value_objects/challenge_streak.dart';

/// In-memory `ChallengeStreakRepository` для тестов domain и presentation.
final class FakeChallengeStreakRepository
    implements ChallengeStreakRepository {
  /// Создаёт репозиторий; первый позиционный аргумент сразу становится
  /// сохранённой серией.
  FakeChallengeStreakRepository([this._stored]);

  ChallengeStreak? _stored;

  /// Сколько раз вызывали [save] — тесты проверяют отсутствие лишних записей.
  int saveCount = 0;

  /// Ошибка, которую бросит следующий [get].
  Exception? throwOnGet;

  /// Текущее сохранённое значение; null — серии ещё нет.
  ChallengeStreak? get stored => _stored;

  @override
  Future<ChallengeStreak?> get() async {
    final failure = throwOnGet;
    if (failure != null) {
      throw failure;
    }
    return _stored;
  }

  @override
  Future<void> save(ChallengeStreak streak) async {
    saveCount++;
    _stored = streak;
  }
}
