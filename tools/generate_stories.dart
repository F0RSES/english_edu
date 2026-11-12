import 'dart:convert';
import 'dart:io';

const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
const _model = 'deepseek-chat';
const _attempts = 2;
const _retryDelay = Duration(milliseconds: 200);
const _allowedLevels = <String>{'A1', 'A2', 'B1', 'B2', 'C1'};

/// Генерирует короткие рассказы для Reading Mode через DeepSeek (ADR-039).
///
/// Запуск: `DEEPSEEK_API_KEY=… dart run tools/generate_stories.dart
/// --level=A2 --limit=10 [--output=stories_gen_a2.json]`.
///
/// Выход — обёртка `{"schemaVersion": 1, "level": …, "stories": […]}`:
/// `merge_stories.dart` берёт уровень из обёртки. В `assets/seed/stories_v1.json`
/// результат попадает только через merge после проверки перевода.
Future<void> main(List<String> args) async {
  final level = _flag(args, '--level')?.trim().toUpperCase();
  final limit = int.tryParse(_flag(args, '--limit') ?? '10') ?? 10;
  if (level == null || !_allowedLevels.contains(level) || limit <= 0) {
    stderr.writeln(
      'ERROR: usage: dart run tools/generate_stories.dart '
      '--level=A2 --limit=10 [--output=path] (level: A1, A2, B1, B2, C1)',
    );
    exitCode = 1;
    return;
  }
  final output =
      _flag(args, '--output') ?? 'stories_gen_${level.toLowerCase()}.json';

  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('ERROR: DEEPSEEK_API_KEY is not set');
    exitCode = 1;
    return;
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final stories = await _generate(client, apiKey, level, limit);
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'level': level.toLowerCase(),
      'stories': stories,
    };
    await File(
      output,
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(payload)}\n');
    stdout.writeln('Wrote ${stories.length} stories to $output');
  } finally {
    client.close(force: true);
  }
}

Future<List<Map<String, Object?>>> _generate(
  HttpClient client,
  String apiKey,
  String level,
  int limit,
) async {
  final prompt =
      'Составь $limit коротких рассказов на английском языке '
      'уровня $level (50-80 слов каждый). '
      'Верни СТРОГО JSON без markdown: '
      '[{"title": "Заголовок", "text": "Английский текст", '
      '"translation": "Русский перевод"}] '
      'Темы: повседневная жизнь, путешествия, еда, хобби.';

  Object? lastError;
  for (var attempt = 1; attempt <= _attempts; attempt++) {
    try {
      final body = await _post(client, apiKey, prompt);
      return _parse(body);
    } on Object catch (error) {
      lastError = error;
      if (attempt < _attempts) {
        await Future<void>.delayed(_retryDelay);
      }
    }
  }
  throw HttpException('generation failed: $lastError');
}

Future<String> _post(HttpClient client, String apiKey, String prompt) async {
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

List<Map<String, Object?>> _parse(String content) {
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
          item['title'] is String &&
          item['text'] is String &&
          item['translation'] is String)
        {
          'title': item['title'],
          'text': item['text'],
          'translation': item['translation'],
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
