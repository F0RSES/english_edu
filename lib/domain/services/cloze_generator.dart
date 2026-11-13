import 'package:english_edu/domain/value_objects/cloze_task.dart';

/// Генератор заданий «Заполни пропуск» (Phase 14a, ADR-025).
///
/// Контракт в domain по той же причине, что `HintGenerator` и
/// `ErrorTaskGenerator`: presentation не должен знать про HTTP, а `AiClient` —
/// единственное место с сетью и JSON.
abstract interface class ClozeGenerator {
  /// Возвращает задание для [word] уровня [level] (метка CEFR, например 'A1').
  ///
  /// Бросает исключение, если прокси недоступен или ответ не соответствует
  /// схеме: экран показывает состояние ошибки с кнопкой «Повторить».
  Future<ClozeTask> generateCloze(String word, {required String level});
}
