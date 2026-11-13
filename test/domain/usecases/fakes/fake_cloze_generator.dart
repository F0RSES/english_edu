import 'package:english_edu/domain/services/cloze_generator.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';

/// Генератор заданий без сети.
///
/// Считает вызовы: тест проверяет, что кэш реально экономит запрос, а не
/// просто возвращает тот же текст.
final class FakeClozeGenerator implements ClozeGenerator {
  /// Создаёт фейк; [task] — что вернуть, [error] — что бросить.
  FakeClozeGenerator({ClozeTask? task, this.error})
    : task =
          task ??
          ClozeTask(
            sentence: 'I ___ it.',
            correctWord: 'like',
            options: const ['like', 'likes', 'liked', 'liking', 'liken'],
          );

  /// Задание, которое вернёт генератор.
  final ClozeTask task;

  /// Ошибка вместо задания; null — успех.
  final Exception? error;

  /// Сколько раз вызывали генератор.
  int calls = 0;

  /// Последний уровень, переданный в generateCloze.
  String? lastLevel;

  @override
  Future<ClozeTask> generateCloze(String word, {required String level}) async {
    calls++;
    lastLevel = level;
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return task;
  }
}
