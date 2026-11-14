import 'package:meta/meta.dart';

/// Словарный перевод слова от AI-прокси (type: translate_word, Phase 28b).
///
/// В отличие от ассоциации (`HintGenerator`), это перевод, пригодный для
/// сохранения в словарь как `Word.translation`.
@immutable
final class WordTranslation {
  /// Создаёт перевод; [text] должен быть непустым.
  const WordTranslation({
    required this.text,
    this.partOfSpeech,
    this.transcription,
    this.example,
  }) : assert(text.length > 0, 'text must not be empty');

  /// Русский перевод слова.
  final String text;

  /// Часть речи, если прокси её вернул.
  final String? partOfSpeech;

  /// Транскрипция, если прокси её вернул.
  final String? transcription;

  /// Пример употребления, если прокси его вернул.
  final String? example;

  /// Returns a copy with the given fields replaced.
  WordTranslation copyWith({
    String? text,
    String? partOfSpeech,
    String? transcription,
    String? example,
  }) => WordTranslation(
    text: text ?? this.text,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    transcription: transcription ?? this.transcription,
    example: example ?? this.example,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordTranslation &&
          text == other.text &&
          partOfSpeech == other.partOfSpeech &&
          transcription == other.transcription &&
          example == other.example;

  @override
  int get hashCode => Object.hash(text, partOfSpeech, transcription, example);

  @override
  String toString() => 'WordTranslation("$text")';
}
