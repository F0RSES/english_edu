import 'dart:convert';
import 'dart:io';

import 'validate_seed_lib.dart';

const _baseSeedPath = 'assets/seed/words_v1.json';
const _apiUrl = 'https://api.deepseek.com/v1/chat/completions';
const _model = 'deepseek-chat';
const _defaultLimit = 1000;
const _requestDelay = Duration(milliseconds: 200);
const _autoSourceId = 'ngsl-auto';
const _limitFlag = '--limit=';
const _autoSourceName = 'NGSL terms, auto-translated';
const _autoSourceLicense =
    'CC BY-SA 4.0 (NGSL terms); '
    'translations pending review';

/// Сколько раз повторяем запрос к API при ошибке.
const _attempts = 2;

/// Читает TSV/CSV со списком слов по уровням CEFR и дополняет seed переводами.
///
/// Запуск:
/// `dart run tools/generate_seed.dart <list.csv> <output.json> [--limit=1000]`.
///
/// Вход — колонки `term` и `level` (ADR-023); заголовок необязателен, но если
/// он есть, колонки ищутся по именам, а не по позиции. Уровень берётся из
/// файла, а не из флага: один список может быть смешанным по уровням.
///
/// Требует переменную окружения `DEEPSEEK_API_KEY`; сеть нужна только этому
/// скрипту, приложение остаётся офлайновым.
///
/// Timeouts: connect 30s, idle 60s. Exceptions не логируют auth headers —
/// в сообщение попадают только статус и первые 200 символов ответа.
Future<void> main(List<String> args) async {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln(
      'ERROR: usage: dart run tools/generate_seed.dart <list.csv> '
      '<output.json> [--limit=$_defaultLimit]',
    );
    exitCode = 1;
    return;
  }

  final limit = _parseLimit(args.length == 3 ? args[2] : null);
  if (limit == null) {
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
  final warnings = <String>[];

  final candidates = <SeedCandidate>[];
  for (final entry in _readCandidates(csvFile)) {
    if (!allowedCefrLevels.contains(entry.level)) {
      // Опечатка в уровне — не повод угадывать: слово выпадает, автор видит.
      warnings.add('${entry.term}: skipped, unknown level "${entry.level}"');
      continue;
    }
    if (existing.contains(entry.term) || candidates.length >= limit) {
      continue;
    }
    candidates.add(entry);
  }

  if (candidates.isEmpty) {
    stdout.writeln('Nothing to do: no new terms in the list');
    exitCode = 0;
    return;
  }

  final generated = <Map<String, Object?>>[];
  var nextId = _maxId(base) + 1;

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 60);
  try {
    for (var index = 0; index < candidates.length; index++) {
      final entry = candidates[index];
      final fields = await _translate(client, apiKey, entry.term, entry.level);
      if (fields == null) {
        warnings.add('${entry.term}: skipped, translation failed');
        continue;
      }
      if (fields['levelFits'] == false) {
        // Уровень остаётся из списка (он источник истины), но автор видит
        // слова, которые модель считает несоответствующими уровню.
        warnings.add('${entry.term}: model doubts it matches ${entry.level}');
      }
      // Модель отвечает и "noun|adjective": валидатор ждёт одно значение,
      // поэтому чистим ответ до записи в JSON.
      final rawPartOfSpeech = fields['partOfSpeech'];
      final partOfSpeech = sanitizePartOfSpeech(
        rawPartOfSpeech is String ? rawPartOfSpeech : null,
      );
      if (rawPartOfSpeech != null && partOfSpeech == null) {
        warnings.add(
          'Word ${entry.term}: partOfSpeech "$rawPartOfSpeech" unknown, '
          'set to null',
        );
      }
      generated.add(<String, Object?>{
        'id': nextId++,
        'term': entry.term,
        'translation': fields['translation'],
        'transcription': fields['transcription'],
        'partOfSpeech': partOfSpeech,
        'exampleSentence': fields['exampleSentence'],
        'sourceId': _autoSourceId,
        if (entry.rank case final rank?) 'frequencyRank': rank,
        'autoTranslated': true,
        // Уровень из входного списка, а не из ответа модели: разметка —
        // ответственность источника контента (ADR-023).
        'level': entry.level,
      });
      stdout.writeln(
        'Word ${index + 1}/${candidates.length}: '
        '${entry.term} [${entry.level}] → ${fields['translation']}',
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

/// Слово из входного списка: термин, уровень и необязательный ранг.
final class SeedCandidate {
  /// Создаёт кандидата.
  const SeedCandidate(this.term, this.level, {this.rank});

  /// Английский термин в нижнем регистре.
  final String term;

  /// Уровень CEFR из списка (метка в верхнем регистре).
  final String level;

  /// Частотный ранг, если в списке была колонка `rank`.
  final int? rank;
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

/// Читает TSV/CSV с колонками `term` и `level`.
///
/// Заголовок необязателен: если он есть (`term`/`level`/`rank` в любом
/// порядке), колонки ищутся по именам, иначе берутся первые две — `term`,
/// `level`. Порядок слов сохраняется: список уже отсортирован автором.
List<SeedCandidate> _readCandidates(File file) {
  final content = file.readAsStringSync();
  final separator = content.contains('\t') ? '\t' : ',';
  final rows = [
    for (final line in content.split('\n'))
      if (line.trim().isNotEmpty) line.split(separator),
  ];
  if (rows.isEmpty) {
    return const [];
  }

  var termIndex = 0;
  var levelIndex = 1;
  var rankIndex = -1;
  var firstRow = 0;

  final header = [for (final cell in rows.first) cell.trim().toLowerCase()];
  if (header.contains('term') && header.contains('level')) {
    termIndex = header.indexOf('term');
    levelIndex = header.indexOf('level');
    rankIndex = header.indexOf('rank');
    firstRow = 1;
  }

  final candidates = <SeedCandidate>[];
  for (final cells in rows.skip(firstRow)) {
    if (cells.length <= termIndex || cells.length <= levelIndex) {
      continue;
    }
    final term = cells[termIndex].trim().toLowerCase();
    if (term.isEmpty) {
      continue;
    }
    final rank = rankIndex >= 0 && rankIndex < cells.length
        ? int.tryParse(cells[rankIndex].trim())
        : null;
    candidates.add(
      SeedCandidate(term, cells[levelIndex].trim().toUpperCase(), rank: rank),
    );
  }
  return candidates;
}

/// Разбирает `--limit=1000`; null — ошибка уже напечатана.
///
/// Лимит ограничивает один запуск: 1000 слов — это ~17 минут при задержке
/// 200 мс, дольше держать один прогон смысла нет.
int? _parseLimit(String? raw) {
  if (raw == null) {
    return _defaultLimit;
  }
  if (!raw.startsWith(_limitFlag)) {
    stderr.writeln('ERROR: unknown option $raw, expected ${_limitFlag}1000');
    return null;
  }
  final value = int.tryParse(raw.substring(_limitFlag.length).trim());
  if (value == null || value <= 0) {
    stderr.writeln('ERROR: limit must be a positive integer, got $raw');
    return null;
  }
  return value;
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
    'Определи, подходит ли слово "$term" под уровень $level. '
    'Сгенерируй перевод и пример. '
    'Верни строгий JSON: '
    '{"translation": "<russian>", "transcription": "/<IPA>/", '
    '"partOfSpeech": "<one tag>", '
    '"exampleSentence": "<one English sentence>", '
    '"levelFits": <true|false>}. '
    'partOfSpeech ОБЯЗАТЕЛЬНО одно слово из списка: '
    '${allowedPartsOfSpeech.join(', ')}. '
    'НИКАКИХ "noun|verb" или "noun, verb". '
    'Перевод и пример — на лексике и грамматике уровня $level. '
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
