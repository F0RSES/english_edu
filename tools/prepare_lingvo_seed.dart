import 'dart:convert';
import 'dart:io';

/// Квоты целевых уровней (Phase 38a): всего 9500 слов.
const _quotas = <String, int>{
  'A0': 2000,
  'A1': 2000,
  'A2': 2000,
  'B1': 1250,
  'B2': 1250,
  'C1': 500,
  'C2': 500,
};

/// Уровни от простого к сложному: порядок распределения и добивания.
const _levelOrder = <String>['A0', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

const _inputPath = 'lingvoberry.csv';
const _seedPath = 'assets/seed/words_v2.json';
const _outputPath = 'lingvoberry_filtered.csv';

/// Готовит словарь LingvoBerry по квотам (Phase 38a).
///
/// Читает `lingvoberry.csv` (заголовок `rank,word,cefr`; BOM и строки
/// комментариев `#` пропускаются), исключает слова, уже имеющиеся в
/// `assets/seed/words_v2.json`, и дубликаты внутри CSV. Недобор A0–A2
/// добивается из B1 и выше, B1+ — из следующих уровней; целевой уровень
/// сохраняется в `level`, оригинальный — в `source_level`. Пишет
/// `lingvoberry_filtered.csv` и печатает статистику по уровням.
void main() {
  final inputFile = File(_inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln(
      'Нет $_inputPath: положите CSV LingvoBerry в корень проекта.',
    );
    exit(1);
  }

  final existing = _existingTerms();
  final lines = const LineSplitter().convert(
    inputFile.readAsStringSync().replaceFirst('\uFEFF', ''),
  );

  final header = lines.firstWhere(
    (line) => !line.startsWith('#') && line.trim().isNotEmpty,
    orElse: () => '',
  );
  final columns = header
      .split(',')
      .map((column) => column.trim().toLowerCase())
      .toList();
  final wordIndex = columns.indexWhere((c) => c == 'word' || c == 'term');
  final levelIndex = columns.indexWhere((c) => c == 'cefr' || c == 'level');
  if (wordIndex < 0 || levelIndex < 0) {
    stderr.writeln(
      'Заголовок CSV должен содержать word/term и cefr/level: "$header"',
    );
    exit(1);
  }

  final pools = <String, List<String>>{
    for (final level in _levelOrder) level: <String>[],
  };
  final seen = <String>{};
  var wordLines = 0;
  var skippedLines = 0;
  var excludedExisting = 0;
  var excludedDuplicates = 0;
  var excludedUnknownLevel = 0;
  var excludedEmpty = 0;
  var headerSeen = false;

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      skippedLines++;
      continue;
    }
    if (!headerSeen) {
      headerSeen = true;
      continue;
    }
    wordLines++;
    final fields = line.split(',');
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
    pools[level]!.add(word);
  }

  final poolSizes = [
    for (final level in _levelOrder) '$level=${pools[level]!.length}',
  ].join(' ');
  stdout
    ..writeln('LingvoBerry → $_outputPath (Phase 38a)')
    ..writeln(
      'Слов в исходнике: $wordLines, комментариев/пустых: $skippedLines',
    )
    ..writeln(
      'Исключено: уже в words_v2.json — $excludedExisting, '
      'дубликаты CSV — $excludedDuplicates, '
      'неизвестный уровень — $excludedUnknownLevel, пустые — $excludedEmpty',
    )
    ..writeln('Пулы после дедупа: $poolSizes');

  final b1Index = _levelOrder.indexOf('B1');
  final cursors = <String, int>{for (final level in _levelOrder) level: 0};
  final rows = <String>[];
  final totalQuota = _quotas.values.fold<int>(0, (sum, quota) => sum + quota);
  var totalWritten = 0;
  var totalShortfall = 0;

  stdout.writeln('Квоты (свои + добивание = записано / квота, недобор):');
  for (var t = 0; t < _levelOrder.length; t++) {
    final target = _levelOrder[t];
    final quota = _quotas[target]!;
    var written = 0;
    var own = 0;
    final fills = <String>[];

    // Курсор вместо removeAt(0): пулы читаются последовательно, O(1).
    String take(String source) {
      final pool = pools[source]!;
      final cursor = cursors[source]!;
      if (cursor >= pool.length) {
        return '';
      }
      cursors[source] = cursor + 1;
      return pool[cursor];
    }

    while (written < quota) {
      final word = take(target);
      if (word.isEmpty) {
        break;
      }
      rows.add('${_csvField(word)},$target,$target');
      written++;
      own++;
    }
    // A0–A2 добиваются из B1 и выше: у A1/A2 свои квоты, их не трогаем.
    final donorStart = t < b1Index ? b1Index : t + 1;
    for (var d = donorStart; d < _levelOrder.length && written < quota; d++) {
      final donor = _levelOrder[d];
      var fromDonor = 0;
      while (written < quota) {
        final word = take(donor);
        if (word.isEmpty) {
          break;
        }
        rows.add('${_csvField(word)},$target,$donor');
        written++;
        fromDonor++;
      }
      if (fromDonor > 0) {
        fills.add('$donor $fromDonor');
      }
    }

    final shortfall = quota - written;
    totalWritten += written;
    totalShortfall += shortfall;
    final fillsText = fills.isEmpty ? '—' : fills.join(', ');
    stdout.writeln(
      '  $target: свои $own + добивание [$fillsText] = $written / $quota, '
      'недобор $shortfall',
    );
  }

  var unused = 0;
  for (final level in _levelOrder) {
    unused += pools[level]!.length - cursors[level]!;
  }
  stdout
    ..writeln(
      'Итого: записано $totalWritten / $totalQuota, '
      'недобор $totalShortfall',
    )
    ..writeln('Неиспользованный остаток: $unused');

  // CC BY-SA 4.0 требует атрибуции: производный список несёт лицензию.
  final buffer = StringBuffer()
    ..writeln(
      '# Derived from LingvoBerry (lingvoberry.com/wordlist/en), CC BY-SA 4.0.',
    )
    ..writeln(
      '# CEFR bands: CEFR-J Wordlist v1.5 (Yukio Tono) and Octanove '
      'Vocabulary Profile, CC BY-SA 4.0.',
    )
    ..writeln('# level — целевой уровень квоты, source_level — исходный.')
    ..writeln('word,level,source_level');
  rows.forEach(buffer.writeln);
  File(_outputPath).writeAsStringSync(buffer.toString());
  stdout.writeln('Записано: $_outputPath (${rows.length} строк)');
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

/// Минимальное CSV-экранирование: запятая или кавычка внутри поля.
String _csvField(String value) => value.contains(',') || value.contains('"')
    ? '"${value.replaceAll('"', '""')}"'
    : value;
