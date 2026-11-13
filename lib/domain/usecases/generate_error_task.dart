import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/services/error_task_generator.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';

/// Генерирует задание «Охоты на ошибки» с повторными попытками (Phase 26a).
///
/// Прокси иногда возвращает предложение без ошибки (`wrongWord` совпадает
/// с `correctWord`): такое задание отбраковывается валидацией `fromJson`
/// и генерируется заново. Ретраятся и сетевые сбои — до трёх попыток.
final class GenerateErrorTask {
  /// Создаёт use case; генератор и настройки внедряются.
  const GenerateErrorTask({
    required ErrorTaskGenerator generator,
    required SettingsRepository settings,
  }) : _generator = generator,
       _settings = settings;

  final ErrorTaskGenerator _generator;
  final SettingsRepository _settings;

  /// Сколько попыток делается до понятной ошибки.
  static const _maxAttempts = 3;

  /// Сообщение после исчерпания попыток: показывается экраном.
  static const _failureMessage =
      'Не удалось сгенерировать задание, попробуйте еще раз';

  /// Возвращает задание для [word], повторяя генерацию при сбое.
  ///
  /// Уровень пользователя передаётся генератору (Phase 27a).
  /// Бросает [StateError] с понятным сообщением после трёх неудач.
  Future<ErrorHunterTask> call(String word) async {
    final level = (await _settings.get()).preferredLevel.label;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await _generator.generateErrorTask(word, level: level);
      } on Object catch (_) {
        if (attempt == _maxAttempts) {
          throw StateError(_failureMessage);
        }
      }
    }
    throw StateError(_failureMessage);
  }
}
