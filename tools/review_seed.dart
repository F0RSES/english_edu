import 'dart:convert';
import 'dart:io';

import 'review_seed_lib.dart';

const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
const _model = 'deepseek-chat';
const _requestDelay = Duration(milliseconds: 200);
const _attempts = 2;
const _defaultOutput = 'review_report.json';

/// Ревью переводов seed-файла через DeepSeek.
///
/// Запуск: `dart run tools/review_seed.dart input.json [--output=out.json]
/// [--levels=A1,A2] [--sample=N]`.
///
/// Модель не переводит слова заново, а **проверяет** существующие: перевод,
/// часть речи и уровень. Результат — список подозрительных слов для ручной
/// правки, а не готовый словарь: контент с `autoTranslated` требует решения
/// человека (docs/LICENSE_CONTENT.md).
///
/// Ключ берётся только из `DEEPSEEK_API_KEY`. Скрипт — dev-инструмент, поэтому
/// ходит в API напрямую, а не через прокси приложения (ADR-019).
///
/// Ошибки печатают только статус и первые 200 символов ответа: заголовок с
/// ключом в лог не попадает.
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'ERROR: usage: dart run tools/review_seed.dart <input.json> '
      '[--output=out.json] [--levels=A1,A2] [--sample=N]',
    );
    exitCode = 1;
    return;
  }

  final outputPath = _flag(args, '--output') ?? _defaultOutput;
  final levels = _levels(_flag(args, '--levels'));
  final sample = _sample(_flag(args, '--sample'));
  if (sample == null) {
    exitCode = 1;
    return;
  }

  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('ERROR: DEEPSEEK_API_KEY is not set');
    exitCode = 1;
    return;
  }

  final allWords = _readWords(args.first);
  if (allWords == null) {
    exitCode = 1;
    return;
  }

  final selected = selectWords(allWords, levels: levels, sample: sample);
  final problems = <ReviewProblem>[];
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

  try {
    for (var index = 0; index < selected.length; index++) {
      final word = selected[index];
      final verdict = await _review(client, apiKey, word);
      final number = index + 1;

      if (verdict.isCorrect) {
        stdout.writeln('Word $number/${selected.length}: '
            '${word['term']} → OK');
      } else {
        stdout.writeln('Word $number/${selected.length}: '
            '${word['term']} → PROBLEM (${verdict.issues.join('; ')})');
        problems.add(_toProblem(word, verdict));
      }

      if (index < selected.length - 1) {
        await Future<void>.delayed(_requestDelay);
      }
    }
  } finally {
    client.close(force: true);
  }

  final report = buildReviewReport(
    reviewedAt: DateTime.now(),
    totalWords: allWords.length,
    checkedCount: selected.length,
    problems: problems,
  );
  await File(outputPath).writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(report)}\n',
  );

  stdout
    ..writeln(
      formatSummary(
        checkedCount: selected.length,
        problemsFound: problems.length,
      ),
    )
    ..writeln('Report written to $outputPath');
}

/// Читает `words` из seed-файла; печатает ошибку и возвращает null при сбое.
List<Map<String, Object?>>? _readWords(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('ERROR: file not found: $path');
    return null;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln('ERROR: invalid JSON: ${error.message}');
    return null;
  }

  if (decoded is! Map<String, Object?> || decoded['words'] is! List) {
    stderr.writeln('ERROR: expected an object with a words array');
    return null;
  }

  return [
    for (final item in decoded['words']! as List)
      if (item is Map<String, Object?>) item,
  ];
}

/// Спрашивает модель про одно слово; при сбое повторяет один раз.
Future<ReviewVerdict> _review(
  HttpClient client,
  String apiKey,
  Map<String, Object?> word,
) async {
  Object? lastError;
  for (var attempt = 1; attempt <= _attempts; attempt++) {
    try {
      final content = await _post(client, apiKey, _prompt(word));
      return parseReviewVerdict(content);
    } on Object catch (error) {
      lastError = error;
    }
  }
  // Два провала подряд — тоже проблема: слово уходит в ручную проверку.
  return ReviewVerdict.unparsable('request failed: $lastError');
}

Future<String> _post(
  HttpClient client,
  String apiKey,
  String prompt,
) async {
  final request = await client.postUrl(Uri.parse(_apiUrl));
  request.headers
    ..contentType = ContentType.json
    ..set('Authorization', 'Bearer $apiKey');
  request.write(
    jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0,
      'response_format': {'type': 'json_object'},
    }),
  );

  final response = await request.close().timeout(
    const Duration(seconds: 60),
  );
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    final head = body.length > 200 ? body.substring(0, 200) : body;
    throw HttpException('status ${response.statusCode}: $head');
  }

  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('unexpected response envelope');
  }
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException('no choices in response');
  }
  final message = (choices.first as Map<String, Object?>)['message'];
  final content = (message as Map<String, Object?>?)?['content'];
  if (content is! String) {
    throw const FormatException('no content in response');
  }
  return content;
}

String _prompt(Map<String, Object?> word) {
  final partOfSpeech = word['partOfSpeech'] ?? 'null';
  return 'Проверь корректность английского слова и его русского перевода. '
      'Ответь СТРОГО JSON:\n'
      '{\n'
      '  "isCorrect": true/false,\n'
      '  "issues": ["перечисление проблем, если есть"],\n'
      '  "suggestedTranslation": "если неправильно — правильный перевод, '
      'иначе null",\n'
      '  "suggestedPartOfSpeech": "если неправильно — правильная часть речи, '
      'иначе null"\n'
      '}\n\n'
      "Слово: '${word['term']}'\n"
      "Перевод: '${word['translation']}'\n"
      "Часть речи: '$partOfSpeech'\n"
      "Уровень: '${word['level'] ?? 'A1'}'";
}

ReviewProblem _toProblem(Map<String, Object?> word, ReviewVerdict verdict) =>
    ReviewProblem(
      id: (word['id'] as num?)?.toInt() ?? 0,
      term: '${word['term']}',
      level: word['level'] as String?,
      translation: '${word['translation']}',
      partOfSpeech: word['partOfSpeech'] as String?,
      issues: verdict.issues,
      suggestedTranslation: verdict.suggestedTranslation,
      suggestedPartOfSpeech: verdict.suggestedPartOfSpeech,
    );

String? _flag(List<String> args, String name) {
  for (final arg in args) {
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}

Set<String>? _levels(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  return {
    for (final level in raw.split(','))
      if (level.trim().isNotEmpty) level.trim().toUpperCase(),
  };
}

int? _sample(String? raw) {
  if (raw == null) {
    return null;
  }
  final value = int.tryParse(raw);
  if (value == null || value <= 0) {
    stderr.writeln('ERROR: --sample must be a positive integer');
    return null;
  }
  return value;
}
