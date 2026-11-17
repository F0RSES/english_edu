import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'validate_seed_lib.dart';

/// Прокси AI (ADR-019): ключ модели живёт на воркере, клиент его не знает.
const _proxyUrl = 'https://english-edu-ai.forses17.workers.dev/';

/// Тип запроса словарного перевода (Phase 33): воркер возвращает
/// {translation, partOfSpeech, transcription, example}.
const _translateType = 'translate_word';

const _baseSeedPath = 'assets/seed/words_v2.json';
const _limitFlag = '--limit=';
const _requestDelay = Duration(milliseconds: 200);

/// Одна повторная попытка при ошибке: всего два запроса на слово.
const _attempts = 2;

/// Явный таймаут каждой фазы запроса: connectionTimeout/idleTimeout у
/// HttpClient не ограничивают ожидание ответа активного соединения
/// (dart-sdk lib/_http/http.dart), без этого Worker может подвесить запуск.
const _requestTimeout = Duration(seconds: 15);

/// Промежуточный результат полного запуска: переживает обрыв процесса.
const _checkpointPath = 'words_v3_checkpoint.json';
const _checkpointEvery = 100;

/// Атрибуция источников final_seed.csv: CC BY-SA требует лицензий в seed.
const _sourceMeta = <String, ({String name, String license, String url})>{
  'lingvoberry': (
    name: 'LingvoBerry',
    license: 'CC BY-SA 4.0',
    url: 'https://lingvoberry.com/wordlist/en',
  ),
  'cefrj': (
    name: 'CEFR-J Wordlist v1.5',
    license:
        'CEFR-J Wordlist v1.5 (Yukio Tono, Tokyo University of Foreign '
        'Studies, cefr-j.org)',
    url: 'https://cefr-j.org',
  ),
  'octanove': (
    name: 'Octanove Vocabulary Profile',
    license: 'CC BY-SA 4.0',
    url: 'https://github.com/openlanguageprofiles/olp-en-cefrj',
  ),
};

/// Поля ответа воркера после валидации на границе данных.
typedef _TranslationFields = ({
  String translation,
  String? partOfSpeech,
  String? transcription,
  String? example,
});

/// Обогащает final_seed.csv переводами через AI-прокси и сливает с seed v2.
///
/// Запуск:
/// `dart run tools/enrich_seed.dart <input.csv> <output.json> [--limit=N]`.
///
/// Вход — `final_seed.csv` (word,level,source; BOM, `#`-комментарии и кавычки
/// обрабатываются). База слияния — `assets/seed/words_v2.json`: её слова
/// переносятся как есть, новые получают id после максимального существующего.
/// Без `--limit` обогащаются все новые слова; `--limit=5` — dry-run на пяти.
///
/// Ключ API не нужен: запросы идут в Cloudflare Worker (ADR-019), ключ модели
/// живёт на прокси. Сеть нужна только этому скрипту; приложение офлайновое.
///
/// На каждое новое слово — POST {type: translate_word, word}: явный таймаут
/// 15 с на фазу запроса, одна повторная попытка при ошибке (таймаут не
/// ретраится — сразу следующее слово), задержка 200 мс между запросами.
/// Провал — warning и пропуск слова, запуск продолжается. Новые слова
/// помечаются `autoTranslated: true` (машинный перевод, pending review —
/// BL-21).
///
/// Каждые 100 обработанных слов промежуточный результат пишется в
/// `words_v3_checkpoint.json`. При перезапуске существующий чекпоинт
/// становится базой: уже сгенерированные слова пропускаются, id продолжаются.
/// Чекпоинт после успеха не удаляется: повторный запуск доберёт только
/// пропущенные и новые слова; начать заново — удалить файл вручную.
///
/// Выход — seed формата words_v2 (schemaVersion, sources, words; sourceId
/// ссылается на sources). Если новых слов нет, файл не пишется.
Future<void> main(List<String> args) async {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln(
      'ERROR: usage: dart run tools/enrich_seed.dart <input.csv> '
      '<output.json> [--limit=N]',
    );
    exitCode = 1;
    return;
  }

  int? limit;
  if (args.length == 3) {
    final arg = args[2];
    if (!arg.startsWith(_limitFlag)) {
      stderr.writeln('ERROR: unknown flag "$arg", expected $_limitFlag<N>');
      exitCode = 1;
      return;
    }
    limit = int.tryParse(arg.substring(_limitFlag.length));
    if (limit == null || limit <= 0) {
      stderr.writeln('ERROR: --limit must be a positive integer');
      exitCode = 1;
      return;
    }
  }

  final csvFile = File(args[0]);
  if (!csvFile.existsSync()) {
    stderr.writeln('ERROR: file not found: ${args[0]}');
    exitCode = 1;
    return;
  }

  // База не должна быть перезаписана собственным выводом.
  if (args[1] == _baseSeedPath) {
    stderr.writeln('ERROR: output must not overwrite $_baseSeedPath');
    exitCode = 1;
    return;
  }

  final baseFile = File(_baseSeedPath);
  if (!baseFile.existsSync()) {
    stderr.writeln('ERROR: base seed not found: $_baseSeedPath');
    exitCode = 1;
    return;
  }
  final base = jsonDecode(baseFile.readAsStringSync());
  if (base is! Map<String, Object?>) {
    stderr.writeln('ERROR: base seed root must be a JSON object');
    exitCode = 1;
    return;
  }
  final baseWords = base['words'];
  final baseSources = base['sources'];
  if (baseWords is! List || baseSources is! List) {
    stderr.writeln('ERROR: base seed "words" and "sources" must be arrays');
    exitCode = 1;
    return;
  }

  // Чекпоинт прошлого запуска — эффективная база: уже сгенерированные слова
  // не запрашиваются повторно. Повреждённый файл — явная ошибка, а не
  // молчаливая потеря прогресса.
  var effectiveWords = baseWords;
  var effectiveSources = baseSources;
  final checkpointFile = File(_checkpointPath);
  if (checkpointFile.existsSync()) {
    final Object? checkpoint;
    try {
      checkpoint = jsonDecode(checkpointFile.readAsStringSync());
    } on FormatException catch (error) {
      stderr.writeln(
        'ERROR: checkpoint повреждён (${error.message}); '
        'удалите $_checkpointPath, чтобы начать заново',
      );
      exitCode = 1;
      return;
    }
    if (checkpoint is! Map<String, Object?>) {
      stderr.writeln('ERROR: checkpoint root must be a JSON object');
      exitCode = 1;
      return;
    }
    final checkpointWords = checkpoint['words'];
    final checkpointSources = checkpoint['sources'];
    if (checkpointWords is! List ||
        checkpointWords.isEmpty ||
        checkpointSources is! List) {
      stderr.writeln(
        'ERROR: checkpoint "words" must be a non-empty array '
        'and "sources" an array',
      );
      exitCode = 1;
      return;
    }
    effectiveWords = checkpointWords;
    effectiveSources = checkpointSources;
    stdout.writeln(
      'Checkpoint найден: ${checkpointWords.length} слов — '
      'уже сгенерированные пропускаются',
    );
  }

  final existing = <String>{};
  var maxId = 0;
  for (final item in effectiveWords) {
    if (item is! Map<String, Object?>) {
      stderr.writeln('ERROR: base seed word must be an object');
      exitCode = 1;
      return;
    }
    final term = item['term'];
    final id = item['id'];
    if (term is! String || id is! int) {
      stderr.writeln('ERROR: base seed word needs string term and int id');
      exitCode = 1;
      return;
    }
    existing.add(term.trim().toLowerCase());
    if (id > maxId) {
      maxId = id;
    }
  }

  final lines = const LineSplitter().convert(
    csvFile.readAsStringSync().replaceFirst('\uFEFF', ''),
  );
  final header = lines.firstWhere(
    (line) => !line.startsWith('#') && line.trim().isNotEmpty,
    orElse: () => '',
  );
  final columns = _parseCsvLine(header)
      .map((column) => column.trim().toLowerCase())
      .toList();
  final wordIndex = columns.indexWhere(
    (c) => c == 'word' || c == 'headword' || c == 'term',
  );
  final levelIndex = columns.indexWhere((c) => c == 'cefr' || c == 'level');
  final sourceIndex = columns.indexWhere((c) => c == 'source');
  if (wordIndex < 0 || levelIndex < 0 || sourceIndex < 0) {
    stderr.writeln(
      'ERROR: ${args[0]}: header must contain word, level and source: '
      '"$header"',
    );
    exitCode = 1;
    return;
  }

  final candidates = <({String term, String level, String source})>[];
  final seen = <String>{};
  final warnings = <String>[];
  var skippedExisting = 0;
  var skippedDuplicates = 0;
  var headerSeen = false;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }
    if (!headerSeen) {
      headerSeen = true;
      continue;
    }
    final fields = _parseCsvLine(line);
    if (fields.length <= wordIndex ||
        fields.length <= levelIndex ||
        fields.length <= sourceIndex) {
      warnings.add('skipped malformed line: "$trimmed"');
      continue;
    }
    final term = fields[wordIndex].trim().toLowerCase();
    final level = fields[levelIndex].trim().toUpperCase();
    final source = fields[sourceIndex].trim().toLowerCase();
    if (term.isEmpty) {
      continue;
    }
    if (!allowedCefrLevels.contains(level)) {
      warnings.add('$term: skipped, unknown level "$level"');
      continue;
    }
    if (!_sourceMeta.containsKey(source)) {
      warnings.add('$term: skipped, unknown source "$source"');
      continue;
    }
    if (existing.contains(term)) {
      skippedExisting++;
      continue;
    }
    if (!seen.add(term)) {
      skippedDuplicates++;
      continue;
    }
    if (limit != null && candidates.length >= limit) {
      break;
    }
    candidates.add((term: term, level: level, source: source));
  }

  if (candidates.isEmpty) {
    stdout.writeln('Nothing to do: no new terms in ${args[0]}');
    for (final warning in warnings) {
      stderr.writeln('WARNING: $warning');
    }
    return;
  }

  final generated = <Map<String, Object?>>[];
  final usedSources = <String>{};
  var failed = 0;
  var nextId = maxId + 1;

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 60);
  try {
    for (var index = 0; index < candidates.length; index++) {
      final entry = candidates[index];
      if (index > 0) {
        await Future<void>.delayed(_requestDelay);
      }
      stdout.writeln(
        'Requesting: ${entry.term} (${index + 1}/${candidates.length})',
      );
      final fields = await _translate(client, entry.term);
      if (fields == null) {
        failed++;
        continue;
      }
      final partOfSpeech = sanitizePartOfSpeech(fields.partOfSpeech);
      final transcription = _ipa(fields.transcription);
      final example = fields.example;
      generated.add(<String, Object?>{
        'id': nextId,
        'term': entry.term,
        'translation': fields.translation,
        'level': entry.level,
        if (partOfSpeech != null) 'partOfSpeech': partOfSpeech,
        if (transcription != null) 'transcription': transcription,
        if (example != null) 'exampleSentence': example,
        'sourceId': entry.source,
        'synonyms': <String>[],
        // Машинный перевод не проходил ревью (BL-21): валидатор даст warning.
        'autoTranslated': true,
      });
      nextId++;
      usedSources.add(entry.source);
      stdout.writeln('Got response: ${entry.term} → ${fields.translation}');
      if ((index + 1) % _checkpointEvery == 0) {
        await _writeJson(_checkpointPath, <String, Object?>{
          'schemaVersion': base['schemaVersion'],
          'sources': _mergedSources(effectiveSources, usedSources),
          'words': [...effectiveWords, ...generated],
        });
        stdout.writeln(
          'Checkpoint: ${generated.length} новых слов → $_checkpointPath',
        );
      }
    }
  } finally {
    client.close(force: true);
  }

  final payload = <String, Object?>{
    'schemaVersion': base['schemaVersion'],
    'sources': _mergedSources(effectiveSources, usedSources),
    'words': [...effectiveWords, ...generated],
  };
  await _writeJson(args[1], payload);

  for (final warning in warnings) {
    stderr.writeln('WARNING: $warning');
  }
  stdout
    ..writeln(
      'Сгенерировано: ${generated.length}, пропущено из-за ошибок: $failed, '
      'уже в seed: $skippedExisting, дубликаты в CSV: $skippedDuplicates',
    )
    ..writeln(
      'Записано: ${args[1]} (${effectiveWords.length + generated.length} слов)',
    );
}

/// Источники базы плюс атрибуция реально использованных новых источников.
List<Object?> _mergedSources(
  List<Object?> baseSources,
  Set<String> usedSources,
) {
  final sources = [...baseSources];
  for (final meta in _sourceMeta.entries) {
    if (!usedSources.contains(meta.key)) {
      continue;
    }
    final alreadyListed = sources.any(
      (item) => item is Map<String, Object?> && item['id'] == meta.key,
    );
    if (!alreadyListed) {
      sources.add(<String, Object?>{
        'id': meta.key,
        'name': meta.value.name,
        'license': meta.value.license,
        'url': meta.value.url,
      });
    }
  }
  return sources;
}

/// Пишет seed-JSON с отступами; общий путь финального файла и чекпоинтов.
Future<void> _writeJson(String path, Map<String, Object?> payload) async {
  await File(
    path,
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(payload)}\n');
}

/// Запрашивает перевод у прокси; при ошибке повторяет один раз.
///
/// Таймаут не ретраится: зависший ответ сразу ведёт к следующему слову.
/// `null` — слово не обогащено (warning уже напечатан), запуск продолжается.
Future<_TranslationFields?> _translate(HttpClient client, String term) async {
  for (var attempt = 0; attempt < _attempts; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(_requestDelay);
    }
    try {
      return await _requestTranslation(client, term);
    } on TimeoutException {
      stderr.writeln('Timeout: $term');
      return null;
    } on Object catch (error) {
      if (attempt == _attempts - 1) {
        stderr.writeln('WARNING: $term: $error');
      }
    }
  }
  return null;
}

Future<_TranslationFields> _requestTranslation(
  HttpClient client,
  String term,
) async {
  final request = await client
      .postUrl(Uri.parse(_proxyUrl))
      .timeout(_requestTimeout);
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode(<String, Object?>{'type': _translateType, 'word': term}),
  );
  final HttpClientResponse response;
  final String body;
  try {
    response = await request.close().timeout(_requestTimeout);
    body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_requestTimeout);
  } on TimeoutException {
    // Без abort зависший запрос держит сокет в пуле HttpClient.
    request.abort();
    rethrow;
  }
  if (response.statusCode != HttpStatus.ok) {
    // В диагностику идут только статус и начало тела: без заголовков и URI.
    throw HttpException('HTTP ${response.statusCode}: ${_truncate(body)}');
  }
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('proxy returned a non-object payload');
  }
  final translation = decoded['translation'];
  if (translation is! String || translation.trim().isEmpty) {
    throw const FormatException('proxy returned no translation');
  }
  return (
    translation: translation.trim(),
    partOfSpeech: _optionalText(decoded['partOfSpeech']),
    transcription: _optionalText(decoded['transcription']),
    example: _optionalText(decoded['example']),
  );
}

/// Необязательное поле ответа: не-строка или пустая строка — отсутствие.
String? _optionalText(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

/// Валидатор требует IPA в обрамлении `/…/`; модель иногда даёт без слэшей.
String? _ipa(String? raw) {
  if (raw == null) {
    return null;
  }
  final core = raw.replaceAll(RegExp(r'^/+|/+$'), '');
  return core.isEmpty ? null : '/$core/';
}

/// Разбирает CSV-строку с кавычками: запятая внутри кавычек — не разделитель,
/// удвоенная кавычка — экранированная.
List<String> _parseCsvLine(String line) {
  final fields = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        buffer.write(char);
      }
    } else if (char == '"') {
      inQuotes = true;
    } else if (char == ',') {
      fields.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  fields.add(buffer.toString());
  return fields;
}

/// Обрезает диагностический текст до 200 символов.
String _truncate(String text) =>
    text.length <= 200 ? text : '${text.substring(0, 200)}…';
