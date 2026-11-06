import 'package:english_edu/domain/repositories/cloze_task_repository.dart';
import 'package:english_edu/domain/services/cloze_generator.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';

/// Отдаёт задание «Заполни пропуск»: кэш → AI → кэш (ADR-025).
///
/// Сначала смотрит в БД. Ошибка генератора **не** кэшируется: исключение
/// пробрасывается до записи, поэтому следующий вызов снова попробует сеть.
/// Это важно для офлайн-режима: без сети экран показывает ошибку, а задание
/// появится, как только сеть вернётся.
final class GetClozeTask {
  /// Создаёт use case.
  const GetClozeTask({
    required ClozeTaskRepository tasks,
    required ClozeGenerator generator,
    required DateTime Function() clock,
  }) : _tasks = tasks,
       _generator = generator,
       _clock = clock;

  final ClozeTaskRepository _tasks;
  final ClozeGenerator _generator;
  final DateTime Function() _clock;

  /// Возвращает задание для [wordId] с английским написанием [term].
  ///
  /// Бросает исключение генератора, если кэша нет и прокси недоступен.
  Future<ClozeTask> call(WordId wordId, String term) async {
    final cached = await _tasks.getByWordId(wordId);
    if (cached != null) {
      return cached;
    }

    final generated = await _generator.generateCloze(term);
    await _tasks.save(wordId, generated, _clock().toUtc());
    return generated;
  }
}
