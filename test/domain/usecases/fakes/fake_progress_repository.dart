import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// In-memory progress repository for use-case tests.
final class FakeProgressRepository implements ProgressRepository {
  /// Creates a fake seeded with [seed].
  FakeProgressRepository([Iterable<WordProgress> seed = const []])
    : _byWordId = {for (final item in seed) item.wordId: item};

  final Map<WordId, WordProgress> _byWordId;

  @override
  Future<WordProgress?> getByWordId(WordId wordId) async => _byWordId[wordId];

  @override
  Future<List<WordProgress>> getByStatus(WordStatus status) async => [
    for (final item in _byWordId.values)
      if (item.status == status) item,
  ];

  @override
  Future<List<WordProgress>> getDueBefore(DateTime utcInstant) async => [
    for (final item in _byWordId.values)
      if (!item.cardState.dueAt.isAfter(utcInstant)) item,
  ];

  @override
  Future<List<WordProgress>> getAll() async => _byWordId.values.toList();

  @override
  Future<void> upsert(WordProgress progress) async {
    _byWordId[progress.wordId] = progress;
  }

  @override
  Future<void> replaceAll(Iterable<WordProgress> items) async {
    _byWordId
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.wordId, item)));
  }
}
