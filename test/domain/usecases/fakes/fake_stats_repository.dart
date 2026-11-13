import 'package:english_edu/domain/entities/daily_stats.dart';
import 'package:english_edu/domain/repositories/stats_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// In-memory stats repository for use-case tests.
final class FakeStatsRepository implements StatsRepository {
  /// Creates a fake seeded with [seed], keyed by date.
  FakeStatsRepository([Iterable<DailyStats> seed = const []])
      : _byDate = {for (final stats in seed) stats.date: stats};

  final Map<LocalDate, DailyStats> _byDate;

  @override
  Future<DailyStats?> getForDate(LocalDate date) async => _byDate[date];

  @override
  Future<List<DailyStats>> getRange(LocalDate from, LocalDate to) async => [
        for (final entry in _byDate.entries)
          if (entry.key.compareTo(from) >= 0 && entry.key.compareTo(to) <= 0)
            entry.value,
      ];

  @override
  Future<LocalDate?> getLastActiveDate() async {
    LocalDate? latest;
    for (final entry in _byDate.entries) {
      if (entry.value.totalAnswers == 0) {
        continue;
      }
      if (latest == null || entry.key.compareTo(latest) > 0) {
        latest = entry.key;
      }
    }
    return latest;
  }

  @override
  Future<void> upsert(DailyStats stats) async {
    _byDate[stats.date] = stats;
  }

  @override
  Future<List<DailyStats>> getAll() async => _byDate.values.toList();

  @override
  Future<void> replaceAll(Iterable<DailyStats> items) async {
    _byDate
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.date, item)));
  }
}
