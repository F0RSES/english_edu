import 'dart:convert';
import 'dart:io';

/// Целевые квоты (Phase 38b): всего 9500 слов.
const _quotas = <String, int>{
  'A0': 2000,
  'A1': 2000,
  'A2': 2000,
  'B1': 1250,
  'B2': 1250,
  'C1': 500,
  'C2': 500,
};

/// Уровни от простого к сложному: порядок резервирования и добивания.
const _levelOrder = <String>['A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

/// Источники в порядке приоритета: при дубле слова побеждает первое
/// вхождение (lingvoberry — единственный источник A0, поэтому первый).
const _sources = <({String name, String path})>[
  (name: 'lingvoberry', path: 'lingvoberry.csv'),
  (name: 'cefrj', path: 'cefrj.csv'),
  (name: 'octanove', path: 'octanove.csv'),
];

const _seedPath = 'assets/seed/words_v2.json';
const _outputPath = 'final_seed.csv';

/// Собирает финальный словарь из трёх источников (Phase 38b).
///
/// Читает lingvoberry.csv, cefrj.csv, octanove.csv (колонки word/headword
/// и cefr/level определяются по заголовку; BOM, `#`-комментарии и кавычки
/// обрабатываются), дедуплицирует (trim + lowercase, первое вхождение
/// побеждает) и исключает слова, уже имеющиеся в `assets/seed/words_v2.json`.
///
/// Распределение (исправление бага Phase 38a): сначала каждый уровень
/// резервирует свои слова до квоты (излишек обрезается), затем недобор
/// добирается из остатков следующих уровней — уровень не отдаёт слова,
/// пока не заполнил собственную квоту. Пишет `final_seed.csv`
/// (word,level,source) и печатает подробную статистику.
void main() {
  final existing = _existingTerms();
  final pools = <String, List<(String, String)>>{
    for (final level in _levelOrder) level: <(String, String)>[],
  };
  final seen = <String>{};

  for (final (name: source, :path) in _sources) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Нет $path: положите исходный CSV в корень проекта.');
      exit(1);
    }
    final lines = const LineSplitter().convert(
      file.readAsStringSync().replaceFirst('\uFEFF', ''),
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
    if (wordIndex < 0 || levelIndex < 0) {
      stderr.writeln(
        '$path: заголовок должен содержать word/headword и cefr/level: '
        '"$header"',
      );
      exit(1);
    }

    var wordLines = 0;
    var skipped = 0;
    var excludedExisting = 0;
    var excludedDuplicates = 0;
    var excludedUnknownLevel = 0;
    var excludedEmpty = 0;
    var headerSeen = false;
    var added = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        skipped++;
        continue;
      }
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      wordLines++;
      final fields = _parseCsvLine(line);
      if (fields.length <= wordIndex || fields.length <= levelIndex) {
        excludedEmpty++;
        continue;
      }
      final word = fields[wordIndex].trim().toLowerCase();
      final level = fields[levelIndex].trim().toUpperCase();
      if (word.isEmpty) {
        excludedEmpty++;
        continue;
      }
      if (!pools.containsKey(level)) {
        excludedUnknownLevel++;
        continue;
      }
      if (existing.contains(word)) {
        excludedExisting++;
        continue;
      }
      if (!seen.add(word)) {
        excludedDuplicates++;
        continue;
      }
      pools[level]!.add((word, source));
      added++;
    }

    stdout.writeln(
      '$source: строк $wordLines, добавлено $added, '
      'уже в seed $excludedExisting, дубликаты $excludedDuplicates, '
      'неизвестный уровень $excludedUnknownLevel, пустые $excludedEmpty, '
      'комментариев/пустых строк $skipped',
    );
  }

  final poolSizes = [
    for (final level in _levelOrder) '$level=${pools[level]!.length}',
  ].join(' ');
  stdout.writeln('Уникальные слова по уровням после дедупа: $poolSizes');

  final cursors = <String, int>{for (final level in _levelOrder) level: 0};
  final assigned = <String, List<(String, String)>>{
    for (final level in _levelOrder) level: <(String, String)>[],
  };
  final ownCounts = <String, int>{};

  // Шаг 1: каждый уровень резервирует свои слова до квоты (шаг 3 — обрезка).
  for (final target in _levelOrder) {
    final pool = pools[target]!;
    final quota = _quotas[target]!;
    final take = pool.length < quota ? pool.length : quota;
    for (var i = 0; i < take; i++) {
      assigned[target]!.add(pool[i]);
    }
    cursors[target] = take;
    ownCounts[target] = take;
  }

  // Шаг 2: недобор добирается из остатков следующих уровней: донор отдаёт
  // только то, что осталось после его собственной квоты (исправление 38a).
  final fills = <String, Map<String, int>>{};
  for (var t = 0; t < _levelOrder.length; t++) {
    final target = _levelOrder[t];
    final quota = _quotas[target]!;
    var written = assigned[target]!.length;
    for (var d = t + 1; d < _levelOrder.length && written < quota; d++) {
      final donor = _levelOrder[d];
      final pool = pools[donor]!;
      var fromDonor = 0;
      while (written < quota && cursors[donor]! < pool.length) {
        assigned[target]!.add(pool[cursors[donor]!]);
        cursors[donor] = cursors[donor]! + 1;
        written++;
        fromDonor++;
      }
      if (fromDonor > 0) {
        (fills[target] ??= <String, int>{})[donor] = fromDonor;
      }
    }
  }

  final totalQuota = _quotas.values.fold<int>(0, (sum, quota) => sum + quota);
  var totalWritten = 0;
  final shortfalls = <String>[];
  stdout.writeln(
    'Итоговое распределение (свои + добивание = записано / квота):',
  );
  for (final target in _levelOrder) {
    final written = assigned[target]!.length;
    final quota = _quotas[target]!;
    totalWritten += written;
    final fillParts = [
      for (final entry in (fills[target] ?? <String, int>{}).entries)
        '${entry.key} ${entry.value}',
    ];
    final fillText = fillParts.isEmpty ? '—' : fillParts.join(', ');
    final shortfall = quota - written;
    if (shortfall > 0) {
      shortfalls.add('$target — $shortfall');
    }
    stdout.writeln(
      '  $target: свои ${ownCounts[target]} + добивание [$fillText] = '
      '$written / $quota'
      '${shortfall > 0 ? ', недобор $shortfall' : ''}',
    );
  }
  stdout.writeln('Итого слов в $_outputPath: $totalWritten / $totalQuota');
  if (shortfalls.isEmpty) {
    stdout.writeln('Квоты заполнены полностью.');
  } else {
    stdout.writeln('Не хватает слов: ${shortfalls.join('; ')}.');
  }

  // CC BY-SA требует атрибуции: производный список несёт лицензии источников.
  final buffer = StringBuffer()
    ..writeln(
      '# Sources: LingvoBerry (lingvoberry.com/wordlist/en), CC BY-SA 4.0;',
    )
    ..writeln(
      '# CEFR-J Wordlist v1.5 (Yukio Tono, Tokyo University of Foreign '
      'Studies, cefr-j.org);',
    )
    ..writeln(
      '# Octanove Vocabulary Profile '
      '(github.com/openlanguageprofiles/olp-en-cefrj), CC BY-SA 4.0.',
    )
    ..writeln('# level — целевой уровень квоты, source — происхождение слова.')
    ..writeln('word,level,source');
  for (final target in _levelOrder) {
    for (final (word, source) in assigned[target]!) {
      buffer.writeln('${_csvField(word)},$target,$source');
    }
  }
  File(_outputPath).writeAsStringSync(buffer.toString());
  stdout.writeln('Записано: $_outputPath ($totalWritten слов)');
}

/// Термины текущего seed: уже оплаченные слова повторно не берутся.
Set<String> _existingTerms() {
  final file = File(_seedPath);
  if (!file.existsSync()) {
    stderr.writeln('Нет $_seedPath');
    exit(1);
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    stderr.writeln('Seed root must be a JSON object');
    exit(1);
  }
  final words = decoded['words'];
  if (words is! List) {
    stderr.writeln('Seed "words" must be an array');
    exit(1);
  }
  final terms = <String>{};
  for (final item in words) {
    if (item is Map<String, Object?>) {
      final term = item['term'];
      if (term is String) {
        terms.add(term.trim().toLowerCase());
      }
    }
  }
  return terms;
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

/// Минимальное CSV-экранирование: запятая или кавычка внутри поля.
String _csvField(String value) => value.contains(',') || value.contains('"')
    ? '"${value.replaceAll('"', '""')}"'
    : value;
