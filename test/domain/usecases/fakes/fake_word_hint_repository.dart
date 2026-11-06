import 'package:english_edu/domain/repositories/word_hint_repository.dart';
import 'package:english_edu/domain/value_objects/word_hint.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// In-memory hint repository for use-case tests.
final class FakeWordHintRepository implements WordHintRepository {
  /// Creates a fake seeded with [seed].
  FakeWordHintRepository([Iterable<WordHint> seed = const []])
    : _byWordId = {for (final hint in seed) hint.wordId: hint};

  final Map<WordId, WordHint> _byWordId;

  /// Every saved hint in order — lets tests assert that AI errors do not cache.
  final List<WordHint> saved = [];

  @override
  Future<WordHint?> getByWordId(WordId wordId) async => _byWordId[wordId];

  @override
  Future<void> upsert(WordHint hint) async {
    _byWordId[hint.wordId] = hint;
    saved.add(hint);
  }
}
