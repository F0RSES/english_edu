import 'package:english_edu/domain/value_objects/error_hunter_task.dart';

/// Генератор заданий для мини-игры «Охота на ошибки» (Phase 8).
///
/// Контракт живёт в domain по той же причине, что и `HintGenerator`:
/// presentation не должен зависеть от data-слоя, а `AiClient` — единственное
/// место, где есть HTTP и JSON.
abstract interface class ErrorTaskGenerator {
  /// Возвращает задание для [word] уровня [level] (метка CEFR, например 'A1').
  ///
  /// Бросает исключение, если прокси недоступен или ответ не соответствует
  /// схеме: экран показывает состояние ошибки с кнопкой «Повторить».
  Future<ErrorHunterTask> generateErrorTask(
    String word, {
    required String level,
  });
}
