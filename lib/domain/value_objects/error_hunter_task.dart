import 'package:meta/meta.dart';

/// Задание мини-игры «Охота на ошибки» (Phase 8).
///
/// [sentence] содержит ровно одну ошибку — [wrongWord]; правильный вариант
/// лежит в [correctWord] и обязательно присутствует в [options] (иначе
/// проверить ответ нечем, и задание считается некорректным).
///
/// Прокси пока **не** присылает `correctWord` (проверено на живом ответе:
/// `{"sentence": …, "wrongWord": "readed", "options": ["readed", "read",
/// "reading"]}`). Поэтому поле выводится: первый вариант, отличный от
/// [wrongWord]. Явное поле из JSON имеет приоритет — когда прокси его добавит,
/// клиент подхватит его без правок (BL-59).
///
/// Не `const`: [options] копируется в unmodifiable (как в `TodayQueue`).
/// `fromJson` живёт здесь же, но работает только с `Map`: разбор байтов JSON
/// остаётся в data-слое (`AiClient`), `dart:convert` в domain не появляется.
@immutable
final class ErrorHunterTask {
  /// Создаёт задание; [options] копируется.
  ErrorHunterTask({
    required this.sentence,
    required this.wrongWord,
    required this.correctWord,
    required List<String> options,
  }) : options = List.unmodifiable(options);

  /// Разбирает задание из декодированного JSON-объекта.
  ///
  /// Бросает [FormatException] на любом расхождении схемы: вызывающий
  /// (`AiClient`) превращает её в `AiException`, а экран показывает ошибку
  /// вместо сломанной игры.
  factory ErrorHunterTask.fromJson(Map<String, Object?> json) {
    final sentence = _requiredString(json, 'sentence');
    final wrongWord = _requiredString(json, 'wrongWord');
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
    if (options.isEmpty) {
      throw const FormatException('options: пустой список');
    }
    final correctWord = _resolveCorrectWord(json, options, wrongWord);
    // Предложение без ошибки: ИИ иногда присылает wrongWord == correctWord.
    // Такое задание неиграбельно — отбраковываем, вызывающий сделает retry.
    if (wrongWord.trim().toLowerCase() == correctWord.trim().toLowerCase()) {
      throw const FormatException(
        'correctWord: совпадает с wrongWord — предложение без ошибки',
      );
    }
    return ErrorHunterTask(
      sentence: sentence,
      wrongWord: wrongWord,
      correctWord: correctWord,
      options: options,
    );
  }

  /// Предложение с одной ошибкой.
  final String sentence;

  /// Ошибочное слово в [sentence].
  final String wrongWord;

  /// Правильная замена [wrongWord].
  final String correctWord;

  /// Варианты ответа; содержит [correctWord].
  final List<String> options;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorHunterTask &&
          sentence == other.sentence &&
          wrongWord == other.wrongWord &&
          correctWord == other.correctWord &&
          _sameOptions(options, other.options);

  @override
  int get hashCode =>
      Object.hash(sentence, wrongWord, correctWord, Object.hashAll(options));

  @override
  String toString() =>
      'ErrorHunterTask("$wrongWord" → "$correctWord", '
      'options: ${options.length})';

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

  /// Явное поле `correctWord`, иначе первый вариант, отличный от [wrongWord].
  ///
  /// Прокси (на 2026-11-06) поле не присылает; как только появится — оно
  /// используется напрямую, поэтому вывод не мешает контракту (BL-59).
  static String _resolveCorrectWord(
    Map<String, Object?> json,
    List<String> options,
    String wrongWord,
  ) {
    final explicit = json['correctWord'];
    if (explicit != null) {
      if (explicit is! String || !options.contains(explicit)) {
        throw const FormatException('correctWord: отсутствует в options');
      }
      return explicit;
    }
    for (final option in options) {
      if (option != wrongWord) {
        return option;
      }
    }
    throw const FormatException(
      'options: нет варианта, отличного от wrongWord',
    );
  }

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('$key: ожидалась непустая строка');
    }
    return value;
  }
}
