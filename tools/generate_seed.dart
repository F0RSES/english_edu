import 'dart:convert';
import 'dart:io';

import 'validate_seed_lib.dart';

const _baseSeedPath = 'assets/seed/words_v1.json';
const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
const _model = 'deepseek-chat';
const _maxWords = 100;
const _requestDelay = Duration(milliseconds: 200);
const _autoSourceId = 'ngsl-auto';
const _levelFlag = '--level=';
const _autoSourceName = 'NGSL terms, auto-translated';
const _autoSourceLicense =
    'CC BY-SA 4.0 (NGSL terms); '
    'translations pending review';

/// Сколько раз повторяем запрос к API при ошибке.
const _attempts = 2;

/// Читает TSV/CSV с частотным списком и дополняет seed переводами.
///
/// Запуск:
/// `dart run tools/generate_seed.dart <ngsl.csv> <output.json> [--level=A1]`.
/// Требует переменную окружения `DEEPSEEK_API_KEY`; сеть нужна только этому
/// скрипту, приложение остаётся офлайновым.
///
/// Timeouts: connect 30s, idle 60s. Exceptions не логируют auth headers —
/// в сообщение попадают только статус и первые 200 символов ответа.
Future<void> main(List<String> args) async {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln(
      'ERROR: usage: dart run tools/generate_seed.dart <ngsl.csv> '
      '<output.json> [--level=A1]',
    );
    exitCode = 1;
    return;
  }

  final level = _parseLevel(args.length == 3 ? args[2] : null);
  if (level == null) {
    exitCode = 1;
    return;
  }

  final apiKey = Platform.environment['DEEPSEEK_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('ERROR: DEEPSEEK_API_KEY is not set');
    exitCode = 1;
    return;
  }

  final csvFile = File(args[0]);
  if (!csvFile.existsSync()) {
    stderr.writeln('ERROR: file not found: ${args[0]}');
    exitCode = 1;
    return;
  }

  final baseFile = File(_baseSeedPath);
  if (!baseFile.existsSync()) {
    stderr.writeln('ERROR: base seed not found: $_baseSeedPath');
    exitCode = 1;
    return;
  }

  final base = jsonDecode(baseFile.readAsStringSync()) as Map<String, Object?>;
  final existing = _existingTerms(base);
  final candidates = _readRankedTerms(csvFile)
      .where((entry) => !existing.contains(entry.term))
      .take(_maxWords)
      .toList();

  if (candidates.isEmpty) {
    stdout.writeln('Nothing to do: every term is already in the seed');
    exitCode = 0;
    return;
  }

  final generated = <Map<String, Object?>>[];
  final warnings = <String>[];
  var nextId = _maxId(base) + 1;

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 60);
  try {
    for (var index = 0; index < candidates.length; index++) {
      final entry = candidates[index];
      final fields = await _translate(client, apiKey, entry.term, level);
      if (fields == null) {
        warnings.add('${entry.term}: skipped, translation failed');
        continue;
      }
      generated.add(<String, Object?>{
        'id': nextId++,
        'term': entry.term,
        'translation': fields['translation'],
        'transcription': fields['transcription'],
        'partOfSpeech': fields['partOfSpeech'],
        'exampleSentence': fields['exampleSentence'],
        'sourceId': _autoSourceId,
        'frequencyRank': entry.rank,
        'autoTranslated': true,
        'level': _normalizeLevel(fields['level'], level, entry.term, warnings),
      });
      stdout.writeln(
        'Word ${index + 1}/${candidates.length}: '
        '${entry.term} → ${fields['translation']}',
      );
      await Future<void>.delayed(_requestDelay);
    }
  } finally {
    client.close(force: true);
  }

  final merged = _merge(base, generated);
  final result = validateSeed(merged);
  if (!result.isValid) {
    for (final error in result.errors) {
      stderr.writeln('ERROR: $error');
    }
    exitCode = 1;
    return;
  }

  final output = File(args[1])
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(merged));
  for (final warning in warnings) {
    stdout.writeln('WARNING: $warning');
  }
  stdout
    ..writeln('Wrote ${output.path}')
    ..writeln(
      'Generated ${generated.length} words, ${warnings.length} warnings',
    );
  exitCode = 0;
}

/// Пара «частотный ранг — термин» из входного списка.
final class RankedTerm {
  /// Создаёт пару.
  const RankedTerm(this.rank, this.term);

  /// Частотный ранг из списка.
  final int rank;

  /// Английский термин в нижнем регистре.
  final String term;
}

Set<String> _existingTerms(Map<String, Object?> base) {
  final terms = <String>{};
  for (final item in base['words']! as List<Object?>) {
    if (item is Map<String, Object?>) {
      final term = item['term'];
      if (term is String) {
        terms.add(term);
      }
    }
  }
  return terms;
}

int _maxId(Map<String, Object?> base) {
  var maxId = 0;
  for (final item in base['words']! as List<Object?>) {
    if (item is Map<String, Object?>) {
      final id = item['id'];
      if (id is int && id > maxId) {
        maxId = id;
      }
    }
  }
  return maxId;
}

/// Читает TSV или CSV с колонками `rank` и `term`.
///
/// Header распознаётся по первому полю, которое не парсится в int.
List<RankedTerm> _readRankedTerms(File file) {
  final content = file.readAsStringSync();
  final separator = content.contains('\t') ? '\t' : ',';
  final terms = <RankedTerm>[];
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    final cells = trimmed.split(separator);
    if (cells.length < 2) {
      continue;
    }
    final rank = int.tryParse(cells[0].trim());
    final term = cells[1].trim().toLowerCase();
    if (rank == null || term.isEmpty) {
      continue;
    }
    terms.add(RankedTerm(rank, term));
  }
  terms.sort((left, right) => left.rank.compareTo(right.rank));
  return terms;
}

/// Разбирает `--level=A1`; null — ошибка уже напечатана.
///
/// Отсутствие флага даёт A1: пачка без указанного уровня не должна молча
/// размечаться как A1 «по факту», поэтому дефолт явный и документирован.
String? _parseLevel(String? raw) {
  if (raw == null) {
    return 'A1';
  }
  if (!raw.startsWith(_levelFlag)) {
    stderr.writeln('ERROR: unknown option $raw, expected ${_levelFlag}A1');
    return null;
  }
  final value = raw.substring(_levelFlag.length).trim().toUpperCase();
  if (!allowedCefrLevels.contains(value)) {
    stderr.writeln(
      'ERROR: unknown level "$value", expected one of '
      '${(allowedCefrLevels.toList()..sort()).join(', ')}',
    );
    return null;
  }
  return value;
}

/// Уровень из ответа модели; неизвестная метка заменяется на [fallback].
///
/// Модель иногда отвечает не тем уровнем, который просили. Слово с чужим
/// уровнем исказило бы очередь дня (ADR-023), поэтому метка нормализуется, а
/// расхождение попадает в предупреждения.
String _normalizeLevel(
  Object? raw,
  String fallback,
  String term,
  List<String> warnings,
) {
  if (raw is! String) {
    warnings.add('$term: no level in response, using $fallback');
    return fallback;
  }
  final normalized = raw.trim().toUpperCase();
  if (!allowedCefrLevels.contains(normalized)) {
    warnings.add('$term: unknown level "$raw", using $fallback');
    return fallback;
  }
  return normalized;
}

Map<String, Object?> _merge(
  Map<String, Object?> base,
  List<Map<String, Object?>> generated,
) {
  final sources = [...base['sources']! as List<Object?>];
  final hasAutoSource = sources.any(
    (item) => item is Map<String, Object?> && item['id'] == _autoSourceId,
  );
  if (!hasAutoSource && generated.isNotEmpty) {
    sources.add(<String, Object?>{
      'id': _autoSourceId,
      'name': _autoSourceName,
      'license': _autoSourceLicense,
      'url': 'https://www.newgeneralservicelist.com/',
    });
  }
  return <String, Object?>{
    'schemaVersion': base['schemaVersion'],
    'sources': sources,
    // Слова базового файла переносятся как есть: их `level` (если размечен)
    // сохраняется, генератор дописывает только новые слова.
    'words': [...base['words']! as List<Object?>, ...generated],
  };
}

Future<Map<String, Object?>?> _translate(
  HttpClient client,
  String apiKey,
  String term,
  String level,
) async {
  for (var attempt = 0; attempt < _attempts; attempt++) {
    try {
      return await _requestTranslation(client, apiKey, term, level);
    } on Object catch (error) {
      if (attempt == _attempts - 1) {
        stderr.writeln('WARNING: $term: $error');
      }
    }
  }
  return null;
}

Future<Map<String, Object?>> _requestTranslation(
  HttpClient client,
  String apiKey,
  String term,
  String level,
) async {
  final request = await client.postUrl(Uri.parse(_apiUrl));
  request.headers.contentType = ContentType.json;
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
  request.write(
    jsonEncode(<String, Object?>{
      'model': _model,
      'messages': [
        <String, Object?>{'role': 'user', 'content': _promptFor(term, level)},
      ],
    }),
  );

  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != HttpStatus.ok) {
    // В сообщение попадают только статус и начало тела: заголовки и URI
    // могут содержать учётные данные, если конфигурация изменится.
    throw HttpException('HTTP ${response.statusCode}: ${_truncate(body)}');
  }

  final decoded = jsonDecode(body) as Map<String, Object?>;
  final choices = decoded['choices']! as List<Object?>;
  final message =
      (choices.first! as Map<String, Object?>)['message']!
          as Map<String, Object?>;
  final content = message['content']! as String;
  return jsonDecode(_stripFences(content)) as Map<String, Object?>;
}

String _promptFor(String term, String level) =>
    'For the English word "$term" at CEFR level $level, return strict JSON: '
    '{"translation": "<russian>", "transcription": "/<IPA>/", '
    '"partOfSpeech": "<${allowedPartsOfSpeech.join('|')}>", '
    '"exampleSentence": "<one English sentence>", '
    '"level": "$level"}. '
    'Use simple vocabulary and grammar that match $level. '
    'No markdown, no code fences, only JSON.';

/// Убирает markdown-обёртку, если модель её всё же добавила.
String _stripFences(String content) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('```')) {
    return trimmed;
  }
  final withoutOpening = trimmed.replaceFirst(RegExp('^```[a-zA-Z]*'), '');
  return withoutOpening.replaceFirst(RegExp(r'```$'), '').trim();
}

/// Обрезает диагностический текст до 200 символов.
String _truncate(String text) =>
    text.length <= 200 ? text : '${text.substring(0, 200)}…';
