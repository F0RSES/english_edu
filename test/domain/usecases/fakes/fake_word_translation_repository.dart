import 'package:english_edu/domain/repositories/word_translation_repository.dart';
import 'package:english_edu/domain/value_objects/word_translation.dart';

/// In-memory translation cache for use-case tests.
final class FakeWordTranslationRepository implements WordTranslationRepository {
  /// Creates a fake seeded with [seed] keyed by term.
  FakeWordTranslationRepository([Map<String, WordTranslation> seed = const {}])
    : _byTerm = Map.of(seed);

  final Map<String, WordTranslation> _byTerm;

  /// Every upsert in order — lets tests assert that AI errors do not cache.
  final List<(String, WordTranslation, DateTime)> saved = [];

  @override
  Future<WordTranslation?> findByTerm(String term) async => _byTerm[term];

  @override
  Future<void> upsert(
    String term,
    WordTranslation translation, {
    required DateTime createdAtUtc,
  }) async {
    _byTerm[term] = translation;
    saved.add((term, translation, createdAtUtc));
  }
}
