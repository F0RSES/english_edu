import 'package:english_edu/domain/entities/review_log.dart';
import 'package:english_edu/domain/repositories/review_log_repository.dart';
import 'package:english_edu/domain/value_objects/review_log_id.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// In-memory review log repository for use-case tests.
final class FakeReviewLogRepository implements ReviewLogRepository {
  /// Creates a fake seeded with [seed].
  FakeReviewLogRepository([Iterable<ReviewLog> seed = const []])
      : _entries = [...seed];

  final List<ReviewLog> _entries;

  @override
  Future<void> append(ReviewLog log) async {
    _entries.add(log);
  }

  @override
  Future<List<ReviewLog>> getByWordId(WordId wordId) async => [
        for (final entry in _entries)
          if (entry.wordId == wordId) entry,
      ];

  @override
  Future<List<ReviewLog>> getAll() async => List.of(_entries);

  @override
  Future<List<ReviewLog>> getByDateRange(
    DateTime fromUtc,
    DateTime toUtc,
  ) async =>
      [
        for (final entry in _entries)
          if (!entry.reviewedAt.isBefore(fromUtc) &&
              entry.reviewedAt.isBefore(toUtc))
            entry,
      ];

  @override
  Future<void> replaceAll(Iterable<ReviewLog> logs) async {
    _entries
      ..clear()
      ..addAll(logs);
  }

  @override
  Future<void> delete(ReviewLogId id) async {
    _entries.removeWhere((entry) => entry.id == id);
  }
}
