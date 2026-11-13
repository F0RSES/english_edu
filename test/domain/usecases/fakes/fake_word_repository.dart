import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// In-memory word repository for use-case tests.
final class FakeWordRepository implements WordRepository {
  /// Creates a fake seeded with [seed].
  FakeWordRepository([Iterable<Word> seed = const []])
    : _byId = {for (final word in seed) word.id: word};

  /// Хук, который выполняется перед `getAll`.
  ///
  /// Нужен экранам, которые показывают состояние загрузки или ошибки: тест
  /// придерживает чтение через `Completer` или бросает исключение.
  Future<void> Function()? beforeGetAll;

  /// Хук перед `getByLevel`: игры читают словарь по уровню (Phase 27a),
  /// поэтому loading/error-тестам нужен отдельный хук, а не `beforeGetAll`.
  Future<void> Function()? beforeGetByLevel;

  final Map<WordId, Word> _byId;

  @override
  Future<Word?> getById(WordId id) async => _byId[id];

  @override
  Future<List<Word>> getByIds(Iterable<WordId> ids) async => [
    for (final id in ids)
      if (_byId[id] case final word?) word,
  ];

  @override
  Future<List<Word>> getAll() async {
    await beforeGetAll?.call();
    return _byId.values.toList();
  }

  @override
  Future<List<Word>> getByLevel(CefrLevel level) async {
    await beforeGetByLevel?.call();
    return [
      for (final word in _byId.values)
        if (word.level == level) word,
    ];
  }

  @override
  Future<int> count() async => _byId.length;

  @override
  Future<WordId> nextId() async {
    var maxId = 0;
    for (final id in _byId.keys) {
      if (id.value > maxId) {
        maxId = id.value;
      }
    }
    return WordId(maxId + 1);
  }

  @override
  Future<Word?> findByTerm(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final word in _byId.values) {
      if (word.term.trim().toLowerCase() == normalized) {
        return word;
      }
    }
    return null;
  }

  @override
  Future<List<Word>> findAllByTerm(String term) async {
    final normalized = term.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }
    return [
      for (final word in _byId.values)
        if (word.term.trim().toLowerCase() == normalized) word,
    ];
  }

  @override
  Future<List<Word>> search(String query) async {
    final needle = query.trim().toLowerCase();
    return [
      for (final word in _byId.values)
        if (word.term.toLowerCase().contains(needle) ||
            word.translation.toLowerCase().contains(needle))
          word,
    ];
  }

  @override
  Future<void> upsert(Word word) async {
    _byId[word.id] = word;
  }

  @override
  Future<void> insertMany(Iterable<Word> words) async {
    for (final word in words) {
      if (_byId.containsKey(word.id)) {
        throw StateError('Duplicate word id: ${word.id.value}');
      }
      _byId[word.id] = word;
    }
  }

  @override
  Future<void> delete(WordId id) async {
    _byId.remove(id);
  }

  @override
  Future<void> replaceAll(Iterable<Word> words) async {
    _byId
      ..clear()
      ..addEntries(words.map((word) => MapEntry(word.id, word)));
  }
}
