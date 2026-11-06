/// Генератор подсказок к слову.
///
/// Контракт живёт в domain: use case не должен знать, что реализация ходит по
/// HTTP. Реализация — `AiClient` (data), поэтому `domain` не импортирует
/// `package:http` (ADR-019).
abstract interface class HintGenerator {
  /// Возвращает ассоциацию для [word].
  ///
  /// Бросает исключение при недоступности провайдера: решение о кэшировании
  /// принимает вызывающий use case, ошибки не сохраняются.
  Future<String> generate(String word);
}
