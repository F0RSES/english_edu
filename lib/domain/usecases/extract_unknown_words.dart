import 'package:english_edu/domain/repositories/word_repository.dart';

/// Достаёт из текста рассказа слова, которых нет в словаре (ADR-039).
///
/// Текст очищается регекспом: нижний регистр, всё кроме букв и пробелов
/// заменяется пробелом; слова короче трёх символов отбрасываются. Сравнение —
/// с нормализованным `term` из БД.
final class ExtractUnknownWords {
  /// Creates the use case.
  const ExtractUnknownWords({required WordRepository words}) : _words = words;

  final WordRepository _words;

  /// Парсит текст: убирает знаки препинания, lowercase.
  /// Возвращает список слов, которых НЕТ в БД.
  Future<List<String>> call(String text) async {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w.length > 2)
        .toSet()
        .toList();

    final known = await _words.getAll();
    final knownSet = {for (final w in known) w.term.toLowerCase()};

    return cleaned.where((w) => !knownSet.contains(w)).toList();
  }
}
