import 'dart:convert';
import 'dart:io';

import 'review_seed_lib.dart';
import 'validate_seed_lib.dart';

/// Входные файлы в порядке приоритета при дедупликации.
///
/// Порядок — это и есть правило разрешения конфликтов: слово остаётся в том
/// уровне, где встречается впервые, то есть в самом простом. Базовый файл
/// идёт первым: его 20 слов — ручная выборка, она главнее машинной разметки.
const _inputs = <String>[
  'assets/seed/words_v1.json',
  'assets/seed/words_a1.json',
  'assets/seed/words_a2.json',
  'assets/seed/words_b1.json',
  'assets/seed/words_b2.json',
  'assets/seed/words_c1.json',
];

/// Куда пишется слитый словарь.
const _outputPath = 'assets/seed/words_v2.json';

/// Файл ручных правок после LLM-ревью (BL-21).
///
/// Отдельный файл, а не правка `words_v2.json`: слитый словарь
/// перезаписывается при каждом запуске, поэтому ручные фиксы хранятся здесь и
/// применяются в конце.
const _overridesPath = 'tools/manual_review_overrides.json';

/// Применяет ручные правки и печатает итог.
///
/// Отсутствие файла — норма: ревью может ещё не быть. Несовпадение термина —
/// предупреждение, а не ошибка: словарь мог измениться, и правку нужно
/// перенести руками, а не потерять молча.
void _applyOverrides(List<Map<String, Object?>> words) {
  final file = File(_overridesPath);
  if (!file.existsSync()) {
    stdout.writeln('No manual overrides file, skipped');
    return;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln('WARNING: invalid overrides JSON: ${error.message}');
    return;
  }

  if (decoded is! Map<String, Object?> || decoded['overrides'] is! List) {
    stderr.writeln('WARNING: overrides file has no overrides array');
    return;
  }

  final overrides = [
    for (final item in decoded['overrides']! as List)
      if (item is Map<String, Object?>) item,
  ];
  final result = applyManualOverrides(words, overrides);

  for (final term in result.missingTerms) {
    stdout.writeln("WARNING: override term '$term' not found in seed");
  }
  stdout.writeln('Applied ${result.applied} manual overrides');
}

/// Сливает словари по уровням в один seed-файл.
///
/// Запуск: `dart run tools/merge_seeds.dart`.
///
/// Список слов в разных уровнях пересекается (одно и то же слово есть и в A2,
/// и в B1), поэтому слова объединяются по нормализованному `term`, а не
/// конкатенируются: иначе в словаре появилось бы два `about`. Идентификаторы
/// пересчитываются заново — после слияния исходные `id` конфликтуют.
Future<void> main() async {
  final sources = <String, Map<String, Object?>>{};
  final seenTerms = <String, String>{};
  final merged = <Map<String, Object?>>[];
  var dropped = 0;
  var inputWarnings = 0;

  for (final path in _inputs) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('ERROR: input not found: $path');
      exitCode = 1;
      return;
    }
    final decoded = jsonDecode(file.readAsStringSync());
    final result = validateSeed(decoded);
    if (!result.isValid) {
      // Битый вход не должен попасть в общий словарь: причину видно сразу,
      // по конкретному файлу, а не после слияния 2700 слов.
      stderr.writeln('ERROR: $path is not a valid seed');
      for (final error in result.errors) {
        stderr.writeln('  $error');
      }
      exitCode = 1;
      return;
    }
    inputWarnings += result.warnings.length;

    final root = decoded as Map<String, Object?>;
    for (final item in root['sources']! as List<Object?>) {
      final source = item! as Map<String, Object?>;
      final id = source['id']! as String;
      final existing = sources[id];
      if (existing == null) {
        sources[id] = source;
      } else if (jsonEncode(existing) != jsonEncode(source)) {
        // Один и тот же id с разными лицензиями — повод разобраться руками,
        // а не молча выбрать первый.
        stdout.writeln('WARNING: source "$id" differs in $path, kept first');
      }
    }

    for (final item in root['words']! as List<Object?>) {
      final word = item! as Map<String, Object?>;
      final term = (word['term']! as String).trim().toLowerCase();
      final keptIn = seenTerms[term];
      if (keptIn != null) {
        dropped++;
        stdout.writeln('DROPPED: $term (kept from $keptIn, skipped $path)');
        continue;
      }
      seenTerms[term] = path;
      merged.add(Map<String, Object?>.of(word));
    }
    stdout.writeln('Read $path: ${result.wordCount} words');
  }

  // Новые идентификаторы: 1..N по порядку появления в объединении.
  for (var index = 0; index < merged.length; index++) {
    merged[index]['id'] = index + 1;
  }

  // Ручные правки применяются последними: они должны побеждать и слияние, и
  // перенумерацию (BL-21).
  _applyOverrides(merged);

  final output = <String, Object?>{
    'schemaVersion': 1,
    'sources': sources.values.toList(),
    'words': merged,
  };

  final check = validateSeed(output);
  if (!check.isValid) {
    stderr.writeln('ERROR: merged seed is not valid');
    for (final error in check.errors) {
      stderr.writeln('  $error');
    }
    exitCode = 1;
    return;
  }

  final file = File(_outputPath)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));

  stdout
    ..writeln()
    ..writeln('Wrote ${file.path}')
    ..writeln('Words: ${merged.length} (dropped $dropped duplicates)')
    ..writeln(
      'Sources: ${sources.keys.join(', ')}; '
      'warnings: $inputWarnings input + ${check.warnings.length} merged',
    );
  exitCode = 0;
}
