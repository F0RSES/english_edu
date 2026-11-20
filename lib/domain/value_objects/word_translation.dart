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
    this.exampleRu,
  }) : assert(text.length > 0, 'text must not be empty');

  /// Русский перевод слова.
  final String text;

  /// Часть речи, если прокси её вернул.
  final String? partOfSpeech;

  /// Транскрипция, если прокси её вернул.
  final String? transcription;

  /// Пример употребления на английском, если прокси его вернул.
  final String? example;

  /// Русский перевод примера (Phase 51): прокси возвращает его в поле
  /// `exampleRu`; не кэшируется в `word_translations` (без миграции схемы).
  final String? exampleRu;

  /// Returns a copy with the given fields replaced.
  WordTranslation copyWith({
    String? text,
    String? partOfSpeech,
    String? transcription,
    String? example,
    String? exampleRu,
  }) => WordTranslation(
    text: text ?? this.text,
    partOfSpeech: partOfSpeech ?? this.partOfSpeech,
    transcription: transcription ?? this.transcription,
    example: example ?? this.example,
    exampleRu: exampleRu ?? this.exampleRu,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordTranslation &&
          text == other.text &&
          partOfSpeech == other.partOfSpeech &&
          transcription == other.transcription &&
          example == other.example &&
          exampleRu == other.exampleRu;

  @override
  int get hashCode =>
      Object.hash(text, partOfSpeech, transcription, example, exampleRu);

  @override
  String toString() => 'WordTranslation("$text")';
}
