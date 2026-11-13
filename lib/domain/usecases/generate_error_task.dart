import 'package:english_edu/domain/services/error_task_generator.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';

/// Генерирует задание «Охоты на ошибки» с повторными попытками (Phase 26a).
///
/// Прокси иногда возвращает предложение без ошибки (`wrongWord` совпадает
/// с `correctWord`): такое задание отбраковывается валидацией `fromJson`
/// и генерируется заново. Ретраятся и сетевые сбои — до трёх попыток.
final class GenerateErrorTask {
  /// Создаёт use case; генератор внедряется.
  const GenerateErrorTask({required ErrorTaskGenerator generator})
    : _generator = generator;

  final ErrorTaskGenerator _generator;

  /// Сколько попыток делается до понятной ошибки.
  static const _maxAttempts = 3;

  /// Сообщение после исчерпания попыток: показывается экраном.
  static const _failureMessage =
      'Не удалось сгенерировать задание, попробуйте еще раз';

  /// Возвращает задание для [word], повторяя генерацию при сбое.
  ///
  /// Бросает [StateError] с понятным сообщением после трёх неудач.
  Future<ErrorHunterTask> call(String word) async {
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _generator.generateErrorTask(word);
      } on Object catch (_) {
        if (attempt == _maxAttempts) {
          throw StateError(_failureMessage);
        }
      }
    }
    throw StateError(_failureMessage);
  }
}
