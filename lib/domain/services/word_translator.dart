import 'package:english_edu/domain/value_objects/word_translation.dart';

/// Переводчик слов через AI-прокси (Phase 28b).
///
/// Контракт живёт в domain: presentation не знает про HTTP, реализация —
/// `AiClient` (паттерн ADR-019). Возвращает словарный перевод, а не
/// ассоциацию, поэтому результат можно сохранять в словарь.
abstract interface class TranslationGenerator {
  /// Переводит [word] на русский.
  ///
  /// Бросает исключение при недоступности прокси или неверном формате
  /// ответа; решение о показе принимает вызывающий UI.
  Future<WordTranslation> translate(String word);
}
