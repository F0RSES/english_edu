import 'package:english_edu/domain/entities/word.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:meta/meta.dart';

/// Пара «слово + его текущий прогресс» для словаря.
///
/// [status] равен `null`, когда прогресса ещё нет: слово в базе есть, но
/// пользователь его не открывал. Вкладки «Изучаю» и «Выучено» такие слова не
/// показывают — они видны только во «Все».
@immutable
final class DictionaryEntry {
  /// Создаёт запись словаря.
  const DictionaryEntry({required this.word, this.status});

  /// Словарная статья.
  final Word word;

  /// Статус изучения или `null`, если прогресса нет.
  final WordStatus? status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryEntry && word == other.word && status == other.status;

  @override
  int get hashCode => Object.hash(word, status);

  @override
  String toString() => 'DictionaryEntry(${word.id.value}, status=$status)';
}
