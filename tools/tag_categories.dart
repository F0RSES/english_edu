import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Прокси AI (ADR-019): ключ модели живёт на воркере, клиент его не знает.
const _proxyUrl = 'https://english-edu-ai.forses17.workers.dev/';

/// Тип запроса пакетного тегирования категориями (Phase 39b).
const _categorizeType = 'categorize_words';

/// Размер батча: компромисс между числом запросов и длиной ответа модели.
const _batchSize = 50;

const _requestDelay = Duration(milliseconds: 200);

/// Одна повторная попытка при ошибке, включая таймаут: батч из 50 слов
/// дорого пропускать молча.
const _attempts = 2;

/// Таймаут каждой фазы запроса: ответ на 50 слов генерируется дольше,
/// чем перевод одного слова (enrich_seed — 15 с).
const _requestTimeout = Duration(seconds: 60);

/// Чекпоинт-обёртка: processedTerms отличает обработанные слова от
/// необработанных — category=null неотличим от отсутствующего тега.
const _checkpointPath = 'words_v3_categories_checkpoint.json';

const _limitFlag = '--limit=';

/// 19 тематических категорий промпта Worker. POS-категории (verbs/adverbs/
/// adjectives) не тегируются — они определяются по partOfSpeech.
///
/// Список дублирует ключи WordCategory из приложения: tools не импортируют
/// lib/ (прецедент allowedCefrLevels в validate_seed_lib).
const _allowedCategories = <String>{
  'animals',
  'nature',
  'food',
  'home',
  'clothes',
  'hobbies',
  'datetime',
  'languages',
  'countries',
  'colors',
  'transport',
  'computers',
  'travel',
  'health',
  'body',
  'weather',
  'school',
  'professions',
  'family',
};

/// Тегирует слова seed тематическими категориями через AI-прокси (Phase 39b).
///
/// Запуск: `dart run tools/tag_categories.dart input.json output.json`
/// с опциональным `--limit=N` (число слов для dry-run).
///
/// Читает seed (schemaVersion, sources, words), батчами по 50 слов шлёт
/// POST {type: categorize_words, words} в Cloudflare Worker и проставляет
/// каждой статье поле `category`: один из 19 тематических ключей (food,
/// animals, …) или null. Глаголы/наречия/прилагательные не тегируются —
/// словарь фильтрует их по partOfSpeech. Ключ API не нужен: он живёт на
/// прокси (ADR-019).
///
/// Retry 1 раз при ошибке (включая таймаут 60 с на фазу), задержка 200 мс
/// между батчами. После каждого батча пишется чекпоинт
/// `words_v3_categories_checkpoint.json` (processedTerms + payload);
/// повторный запуск продолжает с места обрыва, пропущенные из-за ошибок
/// батчи добираются. Уже тегированные слова (category — строка) сохраняются.
/// Термины, опущенные моделью в ответе, считаются null: модель пропускает
/// служебные слова вместо явного null, иначе они никогда не закроются.
///
/// Выход — seed того же формата с полем category у обработанных слов.
/// Если новых слов нет, выход всё равно пишется (финализация из чекпоинта).
Future<void> main(List<String> args) async {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln(
      'ERROR: usage: dart run tools/tag_categories.dart <input.json> '
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

  if (args[0] == args[1]) {
    stderr.writeln('ERROR: output must differ from input');
    exitCode = 1;
    return;
  }
  final inputFile = File(args[0]);
  if (!inputFile.existsSync()) {
    stderr.writeln('ERROR: file not found: ${args[0]}');
    exitCode = 1;
    return;
  }

  Map<String, Object?> root;
  List<Map<String, Object?>> words;
  try {
    final seed = _parseSeed(jsonDecode(inputFile.readAsStringSync()));
    root = seed.root;
    words = seed.words;
  } on FormatException catch (error) {
    stderr.writeln('ERROR: ${args[0]}: ${error.message}');
    exitCode = 1;
    return;
  }

  final processed = <String>{};
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
    final termsRaw = checkpoint['processedTerms'];
    if (termsRaw is! List) {
      stderr.writeln('ERROR: checkpoint "processedTerms" must be an array');
      exitCode = 1;
      return;
    }
    try {
      final payload = _parseSeed(checkpoint['payload']);
      root = payload.root;
      words = payload.words;
    } on FormatException catch (error) {
      stderr.writeln('ERROR: checkpoint payload: ${error.message}');
      exitCode = 1;
      return;
    }
    for (final term in termsRaw) {
      if (term is! String) {
        stderr.writeln('ERROR: checkpoint processedTerms must contain strings');
        exitCode = 1;
        return;
      }
      processed.add(term);
    }
    stdout.writeln(
      'Checkpoint найден: ${processed.length} слов обработано, продолжаем',
    );
  }

  final pending = <Map<String, Object?>>[];
  var skippedTagged = 0;
  for (final word in words) {
    final termRaw = word['term'];
    if (termRaw is! String) {
      continue;
    }
    final term = termRaw.trim().toLowerCase();
    if (processed.contains(term)) {
      continue;
    }
    if (word['category'] is String) {
      skippedTagged++;
      continue;
    }
    pending.add(word);
    if (limit != null && pending.length >= limit) {
      break;
    }
  }

  final batches = <List<Map<String, Object?>>>[];
  for (var i = 0; i < pending.length; i += _batchSize) {
    final end = i + _batchSize < pending.length
        ? i + _batchSize
        : pending.length;
    batches.add(pending.sublist(i, end));
  }

  stdout.writeln(
    'Слов всего: ${words.length}, к обработке: ${pending.length}, '
    'батчей: ${batches.length}, уже тегировано: $skippedTagged',
  );

  if (batches.isEmpty) {
    stdout.writeln('Nothing to do: все слова уже обработаны');
    await _writeSeed(args[1], root, words);
    _printStats(words);
    return;
  }

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 60);
  var failedBatches = 0;
  try {
    for (var index = 0; index < batches.length; index++) {
      final batch = batches[index];
      if (index > 0) {
        await Future<void>.delayed(_requestDelay);
      }
      final terms = <String>[];
      for (final word in batch) {
        final termRaw = word['term'];
        if (termRaw is String) {
          terms.add(termRaw.trim().toLowerCase());
        }
      }
      final categories = await _categorize(client, terms);
      if (categories == null) {
        failedBatches++;
        stderr.writeln(
          'WARNING: batch ${index + 1}/${batches.length}: пропущен после '
          'ошибок, слова повторятся при следующем запуске',
        );
        continue;
      }
      var categorized = 0;
      var nulls = 0;
      var missing = 0;
      for (final word in batch) {
        final termRaw = word['term'];
        if (termRaw is! String) {
          continue;
        }
        final term = termRaw.trim().toLowerCase();
        // Модель опускает слова без категории вместо явного null —
        // считаем пропуск нулём, иначе служебные слова никогда не закроются.
        final category = categories[term];
        if (!categories.containsKey(term)) {
          missing++;
        }
        word['category'] = category;
        processed.add(term);
        if (category == null) {
          nulls++;
        } else {
          categorized++;
        }
      }
      await _writeCheckpoint(processed, root, words);
      stdout.writeln(
        'Batch ${index + 1}/${batches.length}: ${batch.length} words → '
        '$categorized categorized, $nulls null'
        '${missing > 0 ? ' ($missing omitted by model)' : ''}',
      );
    }
  } finally {
    client.close(force: true);
  }

  await _writeSeed(args[1], root, words);
  stdout.writeln('Записано: ${args[1]} (${words.length} слов)');
  if (failedBatches > 0) {
    stdout.writeln(
      'Пропущено батчей: $failedBatches — повторите запуск для добора.',
    );
  }
  _printStats(words);
}

/// Запрашивает категории у прокси; при ошибке (включая таймаут) повторяет
/// один раз. `null` — батч не обработан, его слова добираются перезапуском.
Future<Map<String, String?>?> _categorize(
  HttpClient client,
  List<String> terms,
) async {
  for (var attempt = 0; attempt < _attempts; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(_requestDelay);
    }
    try {
      return await _requestCategories(client, terms);
    } on Object catch (error) {
      if (attempt == _attempts - 1) {
        stderr.writeln('WARNING: batch of ${terms.length}: $error');
      }
    }
  }
  return null;
}

Future<Map<String, String?>> _requestCategories(
  HttpClient client,
  List<String> terms,
) async {
  final request = await client
      .postUrl(Uri.parse(_proxyUrl))
      .timeout(_requestTimeout);
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode(<String, Object?>{'type': _categorizeType, 'words': terms}),
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
  final categoriesRaw = decoded['categories'];
  if (categoriesRaw is! List) {
    throw const FormatException('proxy returned no categories array');
  }
  final result = <String, String?>{};
  for (final item in categoriesRaw) {
    if (item is! Map<String, Object?>) {
      throw const FormatException('category entry must be an object');
    }
    final termRaw = item['term'];
    if (termRaw is! String || termRaw.trim().isEmpty) {
      throw const FormatException('category entry requires a term');
    }
    final term = termRaw.trim().toLowerCase();
    if (result.containsKey(term)) {
      continue; // дубль в ответе — первое вхождение побеждает
    }
    final categoryRaw = item['category'];
    String? category;
    if (categoryRaw is String) {
      final normalized = categoryRaw.trim().toLowerCase();
      if (_allowedCategories.contains(normalized)) {
        category = normalized;
      } else if (normalized.isNotEmpty && normalized != 'null') {
        stderr.writeln(
          'WARNING: $term: неизвестная категория "$normalized" → null',
        );
      }
    }
    result[term] = category;
  }
  return result;
}

/// Разбирает seed на границе данных: корень-объект, words — непустой список
/// объектов с term. Бросает [FormatException] на неверном формате.
({Map<String, Object?> root, List<Map<String, Object?>> words}) _parseSeed(
  Object? decoded,
) {
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('seed root must be a JSON object');
  }
  final wordsRaw = decoded['words'];
  if (wordsRaw is! List || wordsRaw.isEmpty) {
    throw const FormatException('seed "words" must be a non-empty array');
  }
  final words = <Map<String, Object?>>[];
  for (final item in wordsRaw) {
    if (item is! Map<String, Object?> || item['term'] is! String) {
      throw const FormatException('seed word must be an object with a term');
    }
    words.add(item);
  }
  return (root: decoded, words: words);
}

/// Payload seed-формата: schemaVersion и sources переносятся без изменений.
Map<String, Object?> _seedPayload(
  Map<String, Object?> root,
  List<Map<String, Object?>> words,
) => <String, Object?>{
  'schemaVersion': root['schemaVersion'],
  'sources': root['sources'],
  'words': words,
};

Future<void> _writeSeed(
  String path,
  Map<String, Object?> root,
  List<Map<String, Object?>> words,
) async {
  const encoder = JsonEncoder.withIndent('  ');
  final json = encoder.convert(_seedPayload(root, words));
  await File(path).writeAsString('$json\n');
}

/// Чекпоинт после каждого батча: обработанные термины плюс текущий payload.
Future<void> _writeCheckpoint(
  Set<String> processed,
  Map<String, Object?> root,
  List<Map<String, Object?>> words,
) async {
  final wrapper = <String, Object?>{
    'processedTerms': processed.toList(),
    'payload': _seedPayload(root, words),
  };
  await File(
    _checkpointPath,
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(wrapper)}\n');
}

/// Итоговая гистограмма категорий для отчёта (Phase 39b, задача 4).
void _printStats(List<Map<String, Object?>> words) {
  final counts = <String, int>{};
  var tagged = 0;
  var untagged = 0;
  for (final word in words) {
    final category = word['category'];
    if (category is String) {
      tagged++;
      counts[category] = (counts[category] ?? 0) + 1;
    } else {
      untagged++;
    }
  }
  stdout.writeln('Тегировано: $tagged, без категории: $untagged');
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sorted) {
    stdout.writeln('  ${entry.key}: ${entry.value}');
  }
}

/// Обрезает диагностический текст до 200 символов.
String _truncate(String text) =>
    text.length <= 200 ? text : '${text.substring(0, 200)}…';
