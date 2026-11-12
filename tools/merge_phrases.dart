import 'dart:convert';
import 'dart:io';

/// Куда пишется объединённый разговорник.
const _outputPath = 'assets/seed/phrases_v1.json';

/// Дополнительные файлы фраз в корне проекта.
///
/// Отсутствующий файл — не ошибка: набор тем может быть неполным, и слияние
/// должно работать с тем, что есть.
const _inputs = <String>[
  'phrases_greet.json',
  'phrases_airport.json',
  'phrases_restaurant.json',
  'phrases_idioms.json',
];

/// Сливает сгенерированные наборы фраз с базовым файлом (ADR-038).
///
/// Запуск: `dart run tools/merge_phrases.dart`.
///
/// Дубликаты ищутся по `phrase` без учёта регистра и пробелов по краям: одно и
/// то же приветствие встречается в нескольких темах, и вторая вкладка с той же
/// фразой была бы шумом. Идентификаторы перенумеровываются — после слияния
/// исходные номера конфликтуют.
Future<void> main() async {
  final phrases = <Map<String, Object?>>[];
  final seen = <String>{};
  var dropped = 0;

  for (final path in <String>[_outputPath, ..._inputs]) {
    final file = File(path);
    if (!file.existsSync()) {
      stdout.writeln('SKIP: $path (не найден)');
      continue;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (error) {
      stderr.writeln('ERROR: $path: некорректный JSON: ${error.message}');
      exitCode = 1;
      return;
    }

    if (decoded is! Map<String, Object?> || decoded['phrases'] is! List) {
      stderr.writeln('ERROR: $path: ожидался объект с массивом phrases');
      exitCode = 1;
      return;
    }

    var added = 0;
    for (final item in decoded['phrases']! as List) {
      if (item is! Map<String, Object?>) {
        continue;
      }
      final phrase = '${item['phrase'] ?? ''}'.trim();
      final translation = '${item['translation'] ?? ''}'.trim();
      if (phrase.isEmpty || translation.isEmpty) {
        dropped++;
        continue;
      }

      final key = phrase.toLowerCase();
      if (!seen.add(key)) {
        dropped++;
        continue;
      }

      phrases.add({
        'phrase': phrase,
        'translation': translation,
        'category': '${item['category'] ?? 'Разное'}'.trim(),
        'level': '${item['level'] ?? 'a1'}'.trim().toLowerCase(),
      });
      added++;
    }
    final total = (decoded['phrases']! as List).length;
    stdout.writeln('Read $path: $added новых, $total всего');
  }

  if (phrases.isEmpty) {
    stderr.writeln('ERROR: нечего записывать — фразы не найдены');
    exitCode = 1;
    return;
  }

  for (var index = 0; index < phrases.length; index++) {
    phrases[index]['id'] = index + 1;
  }

  final output = <String, Object?>{'schemaVersion': 1, 'phrases': phrases};
  await File(_outputPath)
      .writeAsString('${const JsonEncoder.withIndent('  ').convert(output)}\n');

  final categories = {for (final item in phrases) item['category']};
  stdout
    ..writeln()
    ..writeln('Wrote $_outputPath')
    ..writeln('Фраз: ${phrases.length} (удалено дублей и пустых: $dropped)')
    ..writeln(
      'Тем: ${categories.length} — '
      '${(categories.toList()..sort()).join(', ')}',
    );
}
