import 'package:meta/meta.dart';

/// Задание «Заполни пропуск» (Phase 14a, ADR-025).
///
/// [sentence] содержит пропуск `___` вместо [answer]. Сравнение ответа идёт по
/// нормализованному значению (`trim` + нижний регистр), поэтому регистр и
/// пробелы по краям не важны.
///
/// `fromJson` живёт здесь же, но работает только с `Map`: разбор байтов JSON
/// остаётся в data-слое (`AiClient`), `dart:convert` в domain не появляется —
/// как у `ErrorHunterTask`.
@immutable
final class ClozeTask {
  /// Создаёт задание из готовых строк.
  const ClozeTask({required this.sentence, required this.answer});

  /// Разбирает задание из декодированного JSON-объекта.
  ///
  /// Бросает [FormatException] на любом расхождении схемы: вызывающий
  /// (`AiClient`) превращает её в `AiException`, а экран показывает ошибку
  /// вместо пустого задания.
  factory ClozeTask.fromJson(Map<String, Object?> json) => ClozeTask(
    sentence: _requiredString(json, 'sentence'),
    answer: _requiredString(json, 'answer'),
  );

  /// Предложение с пропуском `___`.
  final String sentence;

  /// Слово, которое нужно вписать.
  final String answer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClozeTask &&
          sentence == other.sentence &&
          answer == other.answer;

  @override
  int get hashCode => Object.hash(sentence, answer);

  @override
  String toString() => 'ClozeTask("$sentence" → "$answer")';

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key: ожидалась непустая строка');
    }
    return value;
  }
}
