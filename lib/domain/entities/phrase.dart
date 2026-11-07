import 'package:meta/meta.dart';

/// Фраза разговорника: справочная единица, а не учебная карточка (ADR-038).
///
/// Не `const`: у фразы есть `copyWith`, но нет UTC-полей — конструктор остаётся
/// non-const ради единообразия с `Word`/`WordProgress` и будущих полей.
@immutable
final class Phrase {
  /// Создаёт фразу; пустые строки запрещены.
  Phrase({
    required this.id,
    required this.phrase,
    required this.translation,
    required this.category,
    required this.level,
  }) : assert(phrase.isNotEmpty, 'phrase must not be empty'),
       assert(translation.isNotEmpty, 'translation must not be empty'),
       assert(category.isNotEmpty, 'category must not be empty');

  /// Идентификатор в БД.
  final int id;

  /// Английская фраза.
  final String phrase;

  /// Русский перевод.
  final String translation;

  /// Тема.
  final String category;

  /// Уровень CEFR меткой (`a1`…`c2`).
  final String level;

  /// Returns a copy with the given fields replaced.
  Phrase copyWith({
    int? id,
    String? phrase,
    String? translation,
    String? category,
    String? level,
  }) => Phrase(
    id: id ?? this.id,
    phrase: phrase ?? this.phrase,
    translation: translation ?? this.translation,
    category: category ?? this.category,
    level: level ?? this.level,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Phrase &&
          id == other.id &&
          phrase == other.phrase &&
          translation == other.translation &&
          category == other.category &&
          level == other.level;

  @override
  int get hashCode => Object.hash(id, phrase, translation, category, level);

  @override
  String toString() => 'Phrase($id, "$phrase" → "$translation")';
}
