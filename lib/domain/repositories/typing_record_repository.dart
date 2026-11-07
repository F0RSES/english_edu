import 'package:english_edu/domain/value_objects/typing_record.dart';

/// Хранилище рекордов «Typing Speed» (ADR-037).
///
/// Записи только добавляются: история нужна для топа и лучшего результата,
/// а перезапись скрыла бы прогресс.
abstract interface class TypingRecordRepository {
  /// Лучший результат по очкам или null, если записей нет.
  Future<TypingRecord?> getBest();

  /// Топ результатов по очкам.
  Future<List<TypingRecord>> getTop({int limit = 10});

  /// Сохраняет запись и возвращает её с присвоенным id.
  Future<TypingRecord> save(TypingRecord record);
}
