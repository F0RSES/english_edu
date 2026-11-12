import 'package:english_edu/domain/repositories/daily_challenge_repository.dart';
import 'package:english_edu/domain/value_objects/daily_challenge.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// In-memory `DailyChallengeRepository` для тестов domain и presentation.
///
/// Позволяет подсунуть сбой чтения или записи: так проверяется, что ответ
/// записывается даже при поломанном хранилище задания (ADR-030).
final class FakeDailyChallengeRepository implements DailyChallengeRepository {
  /// Создаёт репозиторий; [seed] сразу становится заданием своего дня.
  FakeDailyChallengeRepository([DailyChallenge? seed])
    : _byDate = {if (seed != null) seed.date: seed};

  final Map<LocalDate, DailyChallenge> _byDate;

  /// Сколько раз вызывали [save] — тесты проверяют отсутствие лишних записей.
  int saveCount = 0;

  /// Ошибка, которую бросит следующий [getForDate].
  Exception? throwOnGet;

  /// Ошибка, которую бросит следующий [save].
  Exception? throwOnSave;

  /// Единственное сохранённое задание; null — хранилище пусто.
  DailyChallenge? get stored =>
      _byDate.values.isEmpty ? null : _byDate.values.first;

  @override
  Future<DailyChallenge?> getForDate(LocalDate date) async {
    final failure = throwOnGet;
    if (failure != null) {
      throw failure;
    }
    return _byDate[date];
  }

  @override
  Future<void> save(DailyChallenge challenge) async {
    final failure = throwOnSave;
    if (failure != null) {
      throw failure;
    }
    saveCount++;
    _byDate[challenge.date] = challenge;
  }
}
