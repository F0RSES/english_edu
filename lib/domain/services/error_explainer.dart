/// Доменный контракт объяснения ошибки в мини-играх (ADR-042).
///
/// Контракт живёт в domain: use case не должен знать, что реализация ходит по
/// HTTP. Реализация — `AiClient` (data), поэтому `domain` не импортирует
/// `package:http` (паттерн `HintGenerator`, ADR-019).
abstract interface class ErrorExplainer {
  /// Объясняет ошибку в игре [gameType] по контексту [context].
  ///
  /// [gameType] — идентификатор игры ('cloze_test', 'error_hunter',
  /// 'word_scramble', 'listening', 'typing'); [context] описывает, что было
  /// и что ответил пользователь. Бросает исключение при недоступности
  /// провайдера или неверном формате ответа.
  Future<String> explain({required String gameType, required String context});
}
