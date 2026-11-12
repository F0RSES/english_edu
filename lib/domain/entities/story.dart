import 'package:english_edu/domain/value_objects/cefr_level.dart';
import 'package:meta/meta.dart';

/// Рассказ для Reading Mode (ADR-039): связный текст, а не учебная карточка.
///
/// Прогресса и статуса здесь нет: чтение не влияет на SRS и статистику.
@immutable
final class Story {
  /// Создаёт рассказ.
  const Story({
    required this.id,
    required this.title,
    required this.text,
    required this.translation,
    required this.level,
  });

  /// Идентификатор в БД.
  final int id;

  /// Заголовок.
  final String title;

  /// Английский текст.
  final String text;

  /// Русский перевод.
  final String translation;

  /// Уровень CEFR.
  final CefrLevel level;

  /// Число слов в тексте (разделитель — пробельные символы).
  int get wordCount => text.split(RegExp(r'\s+')).length;

  /// Returns a copy with the given fields replaced.
  Story copyWith({
    int? id,
    String? title,
    String? text,
    String? translation,
    CefrLevel? level,
  }) => Story(
    id: id ?? this.id,
    title: title ?? this.title,
    text: text ?? this.text,
    translation: translation ?? this.translation,
    level: level ?? this.level,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Story &&
          id == other.id &&
          title == other.title &&
          text == other.text &&
          translation == other.translation &&
          level == other.level;

  @override
  int get hashCode => Object.hash(id, title, text, translation, level);

  @override
  String toString() => 'Story($id, "$title", ${level.label})';
}
