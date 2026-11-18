import 'package:english_edu/domain/entities/word_progress.dart';
import 'package:english_edu/domain/repositories/app_meta_repository.dart';
import 'package:english_edu/domain/repositories/progress_repository.dart';
import 'package:english_edu/domain/repositories/word_repository.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';

/// Ручное управление статусом слова из словаря (Phase 39e).
///
/// Статус живёт в `WordProgress` (ADR-004), поэтому use case работает через
/// [ProgressRepository], а не `WordRepository`. Перевод в `mastered` —
/// явное действие пользователя и обходит порог мастерства SRS
/// (reps ≥ 5 && interval ≥ 21): ручное управление важнее автоматики.
///
/// Сброс (`newWord`) различает seed и кастомные слова по `seed_max_id` из
/// `app_meta` (пишет seed loader): кастомное слово (id > max) удаляется
/// целиком (прогресс уносится FK-cascade), seed-слово теряет строку
/// прогресса и снова становится «новым». Если `seed_max_id` отсутствует,
/// слово считается seed-словом: консервативный сброс вместо удаления.
final class UpdateWordStatus {
  /// Creates the use case.
  const UpdateWordStatus({
    required WordRepository words,
    required ProgressRepository progress,
    required AppMetaRepository meta,
    required DateTime Function() clock,
  }) : _words = words,
       _progress = progress,
       _meta = meta,
       _clock = clock;

  final WordRepository _words;
  final ProgressRepository _progress;
  final AppMetaRepository _meta;
  final DateTime Function() _clock;

  /// Переводит слово [wordId] в статус [target].
  ///
  /// `learning`/`mastered` сохраняют существующую карточку SRS; `newWord`
  /// сбрасывает прогресс (или удаляет кастомное слово).
  Future<void> call(WordId wordId, WordStatus target) async {
    if (target == WordStatus.newWord) {
      await _reset(wordId);
      return;
    }
    final now = _clock().toUtc();
    final existing = await _progress.getByWordId(wordId);
    await _progress.upsert(
      existing == null
          ? WordProgress(
              wordId: wordId,
              cardState: CardState.initial(now),
              status: target,
              firstSeenAt: now,
            )
          : existing.copyWith(status: target),
    );
  }

  /// Сброс: кастомное слово удаляется, seed-слово теряет прогресс.
  Future<void> _reset(WordId wordId) async {
    final raw = await _meta.getValue(AppMetaRepository.seedMaxIdKey);
    final seedMaxId = raw == null ? null : int.tryParse(raw);
    if (seedMaxId != null && wordId.value > seedMaxId) {
      await _words.delete(wordId);
      return;
    }
    await _progress.deleteByWordId(wordId);
  }
}
