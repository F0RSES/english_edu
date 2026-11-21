import 'package:meta/meta.dart';

/// Разбор предложения от AI-прокси (type: analyze_sentence, Phase 54c).
///
/// Перевод предложения и грамматическое время. Оба поля обязательны:
/// прокси возвращает их вместе, пустой ответ считается ошибкой.
@immutable
final class SentenceAnalysis {
  /// Создаёт разбор; [translation] и [tense] должны быть непустыми.
  const SentenceAnalysis({required this.translation, required this.tense})
    : assert(translation.length > 0, 'translation must not be empty'),
      assert(tense.length > 0, 'tense must not be empty');

  /// Русский перевод предложения.
  final String translation;

  /// Грамматическое время (например, «Present Simple»).
  final String tense;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SentenceAnalysis &&
          translation == other.translation &&
          tense == other.tense;

  @override
  int get hashCode => Object.hash(translation, tense);

  @override
  String toString() => 'SentenceAnalysis("$tense")';
}
