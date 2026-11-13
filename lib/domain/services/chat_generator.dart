/// Генератор ответов чата с AI-помощником (ADR-041).
///
/// Контракт живёт в domain: use case не должен знать, что реализация ходит по
/// HTTP. Реализация — `AiClient` (data), поэтому `domain` не импортирует
/// `package:http` (паттерн ADR-019).
abstract interface class ChatGenerator {
  /// Отправляет контекст [messages] (хронологически, от старых к новым)
  /// и уровень пользователя [level] (метка CEFR, например 'A2').
  ///
  /// Возвращает текст ответа помощника. Бросает исключение при недоступности
  /// провайдера или неверном формате ответа; решение о сохранении принимает
  /// вызывающий use case.
  Future<String> sendChat({
    required List<({String role, String content})> messages,
    required String level,
  });
}
