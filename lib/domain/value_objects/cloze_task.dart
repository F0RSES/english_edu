import 'package:meta/meta.dart';

/// Задание «Заполни пропуск» (Phase 14a, ADR-025; Phase 26b — выбор из 5).
///
/// [sentence] содержит пропуск `___` вместо [correctWord]. Пользователь
/// выбирает один из [options] тапом: ровно 5 вариантов, содержащих
/// [correctWord] без учёта регистра; сравнение — `trim` + нижний регистр.
///
/// `fromJson` живёт здесь же, но работает только с `Map`: разбор байтов JSON
/// остаётся в data-слое (`AiClient`), `dart:convert` в domain не появляется —
/// как у `ErrorHunterTask`.
///
/// Не `const`: [options] копируется в unmodifiable (как в `ErrorHunterTask`).
@immutable
final class ClozeTask {
  /// Создаёт задание; [options] копируется.
  ClozeTask({
    required this.sentence,
    required this.correctWord,
    required List<String> options,
  }) : options = List.unmodifiable(options);

  /// Разбирает задание из декодированного JSON-объекта.
  ///
  /// Бросает [FormatException] на любом расхождении схемы: вызывающий
  /// (`AiClient`) превращает её в `AiException`, а экран показывает ошибку
  /// вместо сломанного задания.
  factory ClozeTask.fromJson(Map<String, Object?> json) {
    final sentence = _requiredString(json, 'sentence');
    final correctWord = _requiredString(json, 'correctWord');
    final rawOptions = json['options'];
    if (rawOptions is! List<Object?>) {
      throw const FormatException('options: ожидался массив');
    }
    final options = <String>[
      for (final option in rawOptions)
        if (option is String && option.trim().isNotEmpty)
          option
        else
          throw const FormatException('options[]: ожидалась непустая строка'),
    ];
    if (options.length != 5) {
      throw const FormatException('options: ожидалось ровно 5 вариантов');
    }
    final normalizedCorrect = correctWord.trim().toLowerCase();
    final containsCorrect = options.any(
      (option) => option.trim().toLowerCase() == normalizedCorrect,
    );
    if (!containsCorrect) {
      throw const FormatException('options: не содержат correctWord');
    }
    return ClozeTask(
      sentence: sentence,
      correctWord: correctWord,
      options: options,
    );
  }

  /// Предложение с пропуском `___`.
  final String sentence;

  /// Правильный вариант ответа.
  final String correctWord;

  /// Ровно 5 вариантов ответа, включая [correctWord]; порядок — как в JSON.
  final List<String> options;

  /// Возвращает копию с заменёнными полями.
  ClozeTask copyWith({
    String? sentence,
    String? correctWord,
    List<String>? options,
  }) => ClozeTask(
    sentence: sentence ?? this.sentence,
    correctWord: correctWord ?? this.correctWord,
    options: options ?? this.options,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClozeTask &&
          sentence == other.sentence &&
          correctWord == other.correctWord &&
          _sameOptions(options, other.options);

  @override
  int get hashCode =>
      Object.hash(sentence, correctWord, Object.hashAll(options));

  @override
  String toString() =>
      'ClozeTask("$sentence" → "$correctWord", options: ${options.length})';

  static bool _sameOptions(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key: ожидалась непустая строка');
    }
    return value;
  }
}
