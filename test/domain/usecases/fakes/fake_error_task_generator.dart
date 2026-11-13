import 'dart:async';

import 'package:english_edu/domain/services/error_task_generator.dart';
import 'package:english_edu/domain/value_objects/error_hunter_task.dart';

/// Генератор заданий для тестов: отдаёт готовое задание, падает или «висит».
final class FakeErrorTaskGenerator implements ErrorTaskGenerator {
  /// Создаёт генератор, возвращающий [task].
  FakeErrorTaskGenerator([this.task]);

  /// Задание, которое возвращается на каждый вызов.
  final ErrorHunterTask? task;

  /// Если задан, ответ приходит только после `complete` — для проверки loading.
  Completer<ErrorHunterTask>? pending;

  /// Заставляет генератор бросить исключение.
  bool throwOnGenerate = false;

  /// Сколько раз вызывали генератор.
  int calls = 0;

  /// Последний уровень, переданный в generateErrorTask.
  String? lastLevel;

  @override
  Future<ErrorHunterTask> generateErrorTask(
    String word, {
    required String level,
  }) {
    calls++;
    lastLevel = level;
    final waiter = pending;
    if (waiter != null) {
      return waiter.future;
    }
    if (throwOnGenerate) {
      return Future<ErrorHunterTask>.error(StateError('ai failed'));
    }
    final value = task;
    if (value == null) {
      return Future<ErrorHunterTask>.error(StateError('no task configured'));
    }
    return Future<ErrorHunterTask>.value(value);
  }
}
