import 'dart:convert';
import 'dart:io';

/// Куда пишется объединённый сборник рассказов.
const _outputPath = 'assets/seed/stories_v1.json';

/// Сгенерированные наборы в корне проекта (артефакты generate_stories).
final _genPattern = RegExp(r'^stories_gen_.*\.json$');

/// Сливает сгенерированные рассказы с базовым файлом (ADR-039).
///
/// Запуск: `dart run tools/merge_stories.dart`.
///
/// Дубликаты ищутся по паре `title` + `text` без учёта регистра и пробелов по
/// краям. Уровень берётся из записи, а для обёртки генератора — из поля
/// `level` обёртки. Идентификаторы перенумеровываются: после слияния исходные
/// номера конфликтуют.
Future<void> main() async {
  final genFiles =
      Directory.current
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where(_genPattern.hasMatch)
          .toList()
        ..sort();

  final stories = <Map<String, Object?>>[];
  final seen = <String>{};
  var dropped = 0;

  for (final path in <String>[_outputPath, ...genFiles]) {
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

    if (decoded is! Map<String, Object?> || decoded['stories'] is! List) {
      stderr.writeln('ERROR: $path: ожидался объект с массивом stories');
      exitCode = 1;
      return;
    }

    final wrapperLevel = '${decoded['level'] ?? ''}'.trim().toLowerCase();
    var added = 0;
    for (final item in decoded['stories']! as List) {
      if (item is! Map<String, Object?>) {
        continue;
      }
      final title = '${item['title'] ?? ''}'.trim();
      final text = '${item['text'] ?? ''}'.trim();
      final translation = '${item['translation'] ?? ''}'.trim();
      final level = '${item['level'] ?? wrapperLevel}'.trim().toLowerCase();
      if (title.isEmpty ||
          text.isEmpty ||
          translation.isEmpty ||
          level.isEmpty) {
        dropped++;
        continue;
      }

      final key = '${title.toLowerCase()}|${text.toLowerCase()}';
      if (!seen.add(key)) {
        dropped++;
        continue;
      }

      stories.add({
        'title': title,
        'text': text,
        'translation': translation,
        'level': level,
      });
      added++;
    }
    final total = (decoded['stories']! as List).length;
    stdout.writeln('Read $path: $added новых, $total всего');
  }

  if (stories.isEmpty) {
    stderr.writeln('ERROR: нечего записывать — рассказы не найдены');
    exitCode = 1;
    return;
  }

  for (var index = 0; index < stories.length; index++) {
    stories[index]['id'] = index + 1;
  }

  final output = <String, Object?>{'schemaVersion': 1, 'stories': stories};
  await File(_outputPath)
      .writeAsString('${const JsonEncoder.withIndent('  ').convert(output)}\n');

  final levels = {for (final item in stories) item['level']};
  stdout
    ..writeln()
    ..writeln('Wrote $_outputPath')
    ..writeln(
      'Рассказов: ${stories.length} (удалено дублей и пустых: $dropped)',
    )
    ..writeln(
      'Уровней: ${levels.length} — '
      '${(levels.toList()..sort()).join(', ')}',
    );
}
