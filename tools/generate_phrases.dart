import 'dart:convert';
import 'dart:io';

const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
const _model = 'deepseek-chat';
const _defaultOutput = 'assets/seed/phrases_gen.json';
const _attempts = 2;

/// Генерирует фразы разговорника через DeepSeek (ADR-038).
///
/// Запуск: `DEEPSEEK_API_KEY=… dart run tools/generate_phrases.dart
/// --category="Airport" --level=A2 --limit=20 [--output=path]`.
///
/// Скрипт — dev-инструмент: результат руками переносится в
/// `assets/seed/phrases_v1.json` после проверки перевода. Автоматически
/// ассеты не перезаписываются: машинный перевод без ревью в продукт не идёт.
Future<void> main(List<String> args) async {
  final category = _flag(args, '--category');
  final level = _flag(args, '--level') ?? 'A2';
  final limit = int.tryParse(_flag(args, '--limit') ?? '20') ?? 20;
  final output = _flag(args, '--output') ?? _defaultOutput;

  if (category == null || category.trim().isEmpty) {
    stderr.writeln(
      'ERROR: usage: dart run tools/generate_phrases.dart '
      '--category="Airport" --level=A2 --limit=20 [--output=path]',
    );
    exitCode = 1;
    return;
  }

  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('ERROR: DEEPSEEK_API_KEY is not set');
    exitCode = 1;
    return;
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final phrases = await _generate(client, apiKey, category, level, limit);
    final payload = {
      'schemaVersion': 1,
      'phrases': phrases,
    };
    await File(output).writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
    );
    stdout.writeln('Wrote ${phrases.length} phrases to $output');
  } finally {
    client.close(force: true);
  }
}

Future<List<Map<String, Object?>>> _generate(
  HttpClient client,
  String apiKey,
  String category,
  String level,
  int limit,
) async {
  final prompt =
      'Составь $limit употребительных английских фраз на тему "$category" '
      'уровня $level и их точный русский перевод. Ответь СТРОГО JSON-массивом: '
      '[{"phrase": "...", "translation": "..."}]';

  Object? lastError;
  for (var attempt = 1; attempt <= _attempts; attempt++) {
    try {
      final body = await _post(client, apiKey, prompt);
      return _parse(body, category, level);
    } on Object catch (error) {
      lastError = error;
    }
  }
  throw HttpException('generation failed: $lastError');
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
      'temperature': 0.4,
    }),
  );

  final response = await request.close().timeout(const Duration(seconds: 60));
  final text = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    final head = text.length > 200 ? text.substring(0, 200) : text;
    throw HttpException('status ${response.statusCode}: $head');
  }

  final decoded = jsonDecode(text);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('unexpected envelope');
  }
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const FormatException('no choices');
  }
  final message = (choices.first as Map<String, Object?>)['message'];
  final content = (message as Map<String, Object?>?)?['content'];
  if (content is! String) {
    throw const FormatException('no content');
  }
  return content;
}

List<Map<String, Object?>> _parse(
  String content,
  String category,
  String level,
) {
  final start = content.indexOf('[');
  final end = content.lastIndexOf(']');
  if (start < 0 || end <= start) {
    throw const FormatException('no JSON array in response');
  }
  final decoded = jsonDecode(content.substring(start, end + 1));
  if (decoded is! List) {
    throw const FormatException('response is not an array');
  }
  return [
    for (final item in decoded)
      if (item is Map<String, Object?> &&
          item['phrase'] is String &&
          item['translation'] is String)
        {
          'phrase': item['phrase'],
          'translation': item['translation'],
          'category': category,
          'level': level.toLowerCase(),
        },
  ];
}

String? _flag(List<String> args, String name) {
  for (final arg in args) {
    if (arg.startsWith('$name=')) {
      return arg.substring(name.length + 1);
    }
  }
  return null;
}
