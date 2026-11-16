import 'package:english_edu/domain/value_objects/sentence_puzzle.dart';

/// Генератор заданий «Собери предложение» через AI-прокси (Phase 35).
///
/// Контракт живёт в domain: реализация — `AiClient` (паттерн ADR-019).
/// Вызывается только когда у слова нет `exampleSentence`: офлайн-путь
/// строит задание из словаря без сети.
///
/// Метод назван `generateSentencePuzzle`, а не `generate`: `AiClient` уже
/// реализует `HintGenerator.generate(String)`, перегрузки в Dart нет.
abstract interface class SentenceGenerator {
  /// Составляет предложение с [word] уровня [level] и возвращает задание.
  ///
  /// Бросает исключение при недоступности прокси или неверном формате
  /// ответа; решение о показе принимает вызывающий UI.
  Future<SentencePuzzle> generateSentencePuzzle(
    String word, {
    required String level,
  });
}
