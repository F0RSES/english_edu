import 'package:english_edu/domain/services/hint_generator.dart';

/// Считает вызовы и умеет падать — для проверки кэша и обработки ошибок.
final class FakeHintGenerator implements HintGenerator {
  /// Создаёт генератор, возвращающий [hint].
  FakeHintGenerator({this.hint = 'подсказка', this.throwOnGenerate = false});

  /// Текст, который возвращается на каждый вызов.
  final String hint;

  /// Заставляет [generate] бросить исключение.
  bool throwOnGenerate;

  /// Сколько раз генератор вызывали.
  int calls = 0;

  /// Слова, которые пришли в [generate], в порядке вызовов.
  final List<String> words = [];

  @override
  Future<String> generate(String word) async {
    calls++;
    words.add(word);
    if (throwOnGenerate) {
      throw StateError('ai failed');
    }
    return hint;
  }
}
