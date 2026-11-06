import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:meta/meta.dart';

/// Сохранённая AI-подсказка к слову (ADR-019).
///
/// [term] хранится рядом с подсказкой, чтобы инвалидировать кэш при
/// редактировании слова: ассоциация сгенерирована для конкретного написания.
///
/// Не `const`: assert на [createdAtUtc].isUtc не является
/// potentially-constant выражением (та же причина, что у `ReviewLog`).
@immutable
final class WordHint {
  /// Создаёт подсказку; [createdAtUtc] обязан быть в UTC.
  WordHint({
    required this.wordId,
    required this.term,
    required this.hintText,
    required this.createdAtUtc,
  }) : assert(createdAtUtc.isUtc, 'createdAtUtc must be UTC');

  /// Слово, к которому относится подсказка.
  final WordId wordId;

  /// Написание слова на момент генерации — ключ инвалидации.
  final String term;

  /// Текст подсказки.
  final String hintText;

  /// Момент сохранения, UTC.
  final DateTime createdAtUtc;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordHint &&
          wordId == other.wordId &&
          term == other.term &&
          hintText == other.hintText &&
          createdAtUtc == other.createdAtUtc;

  @override
  int get hashCode => Object.hash(wordId, term, hintText, createdAtUtc);

  @override
  String toString() =>
      'WordHint(${wordId.value}, "$term", ${hintText.length} chars)';
}
