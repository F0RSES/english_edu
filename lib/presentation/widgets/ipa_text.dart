import 'package:flutter/material.dart';

/// IPA-транскрипция без обрамляющих слэшей (Phase 52a).
///
/// Seed и ответы ИИ хранят транскрипцию в нотации `/…/` — этого требует
/// валидатор seed (tools/validate_seed_lib.dart). На экране слэши — визуальный
/// шум, поэтому нормализация выполняется только при отображении: данные
/// в БД и seed не меняются.
class IpaText extends StatelessWidget {
  /// Создаёт текст транскрипции со стилем [style].
  const IpaText(this.transcription, {this.style, super.key});

  /// Транскрипция как хранится, возможно в обрамляющих слэшах.
  final String transcription;

  /// Стиль текста; null — стиль темы по умолчанию.
  final TextStyle? style;

  /// Убирает обрамляющие слэши и пробелы по краям IPA-строки.
  ///
  /// Содержимое между слэшами не меняется: знаки ударения и символы IPA
  /// значимы. Строка без парных обрамляющих слэшей возвращается как есть
  /// (с trim по краям).
  static String stripSlashes(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('/') &&
        trimmed.endsWith('/')) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) =>
      Text(stripSlashes(transcription), style: style);
}
