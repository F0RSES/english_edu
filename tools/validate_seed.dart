import 'dart:convert';
import 'dart:io';

import 'validate_seed_lib.dart';

/// CLI-обёртка: читает файл, валидирует и печатает результат.
///
/// Код возврата 0 — файл валиден, 1 — есть блокирующие ошибки.
void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('ERROR: usage: dart run tools/validate_seed.dart <path>');
    exitCode = 1;
    return;
  }

  final path = args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: file not found: $path');
    exitCode = 1;
    return;
  }

  Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln('ERROR: invalid JSON: ${error.message}');
    exitCode = 1;
    return;
  } on FileSystemException catch (error) {
    stderr.writeln('ERROR: cannot read $path: ${error.message}');
    exitCode = 1;
    return;
  }

  final result = validateSeed(decoded);
  if (!result.isValid) {
    for (final error in result.errors) {
      stderr.writeln('ERROR: $error');
    }
    exitCode = 1;
    return;
  }

  final words = _plural(result.wordCount, 'word');
  final sources = _plural(result.sourceCount, 'source');
  final warnings = _plural(result.warnings.length, 'warning');
  stdout.writeln(
    'OK: ${result.wordCount} $words, '
    '${result.sourceCount} $sources, '
    '${result.warnings.length} $warnings',
  );
  for (final warning in result.warnings) {
    stdout.writeln('WARNING: $warning');
  }
  exitCode = 0;
}

String _plural(int count, String singular) =>
    count == 1 ? singular : '${singular}s';
