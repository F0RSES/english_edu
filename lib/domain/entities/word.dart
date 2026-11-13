import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:meta/meta.dart';

/// Marker used by nullable [Word.copyWith] parameters to tell "absent" from
/// an explicit null.
const _unset = _Unset();

final class _Unset {
  const _Unset();
}

String? _resolveText(Object? value, String? current) =>
    identical(value, _unset) ? current : value as String?;

/// Word — словарная статья. Состояние изучения — в WordProgress (ADR-004).
///
/// `@immutable` value object; the learning status is deliberately absent.
@immutable
final class Word {
  /// Creates a word; [term] and [translation] must be non-empty.
  const Word({
    required this.id,
    required this.term,
    required this.translation,
    this.transcription,
    this.partOfSpeech,
    this.exampleSentence,
  }) : assert(term.length > 0, 'term must not be empty'),
       assert(translation.length > 0, 'translation must not be empty');

  /// Stable identifier of the word.
  final WordId id;

  /// English term, trimmed and lower-cased by the content pipeline.
  final String term;

  /// Russian translation.
  final String translation;

  /// IPA transcription, when available.
  final String? transcription;

  /// Part of speech, when known.
  final String? partOfSpeech;

  /// Example usage in English.
  final String? exampleSentence;

  /// Returns a copy with the given fields replaced.
  ///
  /// Nullable fields are cleared by passing null explicitly; omitting them
  /// keeps the current value.
  Word copyWith({
    WordId? id,
    String? term,
    String? translation,
    Object? transcription = _unset,
    Object? partOfSpeech = _unset,
    Object? exampleSentence = _unset,
  }) => Word(
    id: id ?? this.id,
    term: term ?? this.term,
    translation: translation ?? this.translation,
    transcription: _resolveText(transcription, this.transcription),
    partOfSpeech: _resolveText(partOfSpeech, this.partOfSpeech),
    exampleSentence: _resolveText(exampleSentence, this.exampleSentence),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Word &&
          id == other.id &&
          term == other.term &&
          translation == other.translation &&
          transcription == other.transcription &&
          partOfSpeech == other.partOfSpeech &&
          exampleSentence == other.exampleSentence;

  @override
  int get hashCode => Object.hash(
    id,
    term,
    translation,
    transcription,
    partOfSpeech,
    exampleSentence,
  );

  @override
  String toString() => 'Word(${id.value}, "$term" → "$translation")';
}
