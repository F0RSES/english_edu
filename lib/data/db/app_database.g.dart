// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transcriptionMeta = const VerificationMeta(
    'transcription',
  );
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
    'transcription',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exampleSentenceMeta = const VerificationMeta(
    'exampleSentence',
  );
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
    'example_sentence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('a1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    term,
    translation,
    transcription,
    partOfSpeech,
    exampleSentence,
    category,
    level,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(
    Insertable<Word> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('transcription')) {
      context.handle(
        _transcriptionMeta,
        transcription.isAcceptableOrUnknown(
          data['transcription']!,
          _transcriptionMeta,
        ),
      );
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
        _exampleSentenceMeta,
        exampleSentence.isAcceptableOrUnknown(
          data['example_sentence']!,
          _exampleSentenceMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      transcription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transcription'],
      ),
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      exampleSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  /// Первичный ключ из домена.
  final int id;

  /// Английский термин в нижнем регистре.
  final String term;

  /// Перевод на русский.
  final String translation;

  /// IPA-транскрипция, если есть.
  final String? transcription;

  /// Часть речи, если известна.
  final String? partOfSpeech;

  /// Пример употребления.
  final String? exampleSentence;

  /// Тематическая категория слова; null — без категории (schema v3).
  ///
  /// Список категорий фиксирован в UI; пользовательские категории — BL-56.
  final String? category;

  /// Уровень по CEFR меткой: `a0`…`c2` (schema v6, ADR-023).
  ///
  /// Хранится как текст, а не как индекс enum: порядок значений в коде может
  /// измениться, а миграция чужого файла с числом стала бы неоднозначной.
  final String level;
  const Word({
    required this.id,
    required this.term,
    required this.translation,
    this.transcription,
    this.partOfSpeech,
    this.exampleSentence,
    this.category,
    required this.level,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['term'] = Variable<String>(term);
    map['translation'] = Variable<String>(translation);
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    if (!nullToAbsent || exampleSentence != null) {
      map['example_sentence'] = Variable<String>(exampleSentence);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['level'] = Variable<String>(level);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      term: Value(term),
      translation: Value(translation),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      exampleSentence: exampleSentence == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleSentence),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      level: Value(level),
    );
  }

  factory Word.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      term: serializer.fromJson<String>(json['term']),
      translation: serializer.fromJson<String>(json['translation']),
      transcription: serializer.fromJson<String?>(json['transcription']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      exampleSentence: serializer.fromJson<String?>(json['exampleSentence']),
      category: serializer.fromJson<String?>(json['category']),
      level: serializer.fromJson<String>(json['level']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'term': serializer.toJson<String>(term),
      'translation': serializer.toJson<String>(translation),
      'transcription': serializer.toJson<String?>(transcription),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'exampleSentence': serializer.toJson<String?>(exampleSentence),
      'category': serializer.toJson<String?>(category),
      'level': serializer.toJson<String>(level),
    };
  }

  Word copyWith({
    int? id,
    String? term,
    String? translation,
    Value<String?> transcription = const Value.absent(),
    Value<String?> partOfSpeech = const Value.absent(),
    Value<String?> exampleSentence = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? level,
  }) => Word(
    id: id ?? this.id,
    term: term ?? this.term,
    translation: translation ?? this.translation,
    transcription: transcription.present
        ? transcription.value
        : this.transcription,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    exampleSentence: exampleSentence.present
        ? exampleSentence.value
        : this.exampleSentence,
    category: category.present ? category.value : this.category,
    level: level ?? this.level,
  );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      term: data.term.present ? data.term.value : this.term,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
      category: data.category.present ? data.category.value : this.category,
      level: data.level.present ? data.level.value : this.level,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('translation: $translation, ')
          ..write('transcription: $transcription, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('category: $category, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    term,
    translation,
    transcription,
    partOfSpeech,
    exampleSentence,
    category,
    level,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.term == this.term &&
          other.translation == this.translation &&
          other.transcription == this.transcription &&
          other.partOfSpeech == this.partOfSpeech &&
          other.exampleSentence == this.exampleSentence &&
          other.category == this.category &&
          other.level == this.level);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> term;
  final Value<String> translation;
  final Value<String?> transcription;
  final Value<String?> partOfSpeech;
  final Value<String?> exampleSentence;
  final Value<String?> category;
  final Value<String> level;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.term = const Value.absent(),
    this.translation = const Value.absent(),
    this.transcription = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.category = const Value.absent(),
    this.level = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    required String term,
    required String translation,
    this.transcription = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.exampleSentence = const Value.absent(),
    this.category = const Value.absent(),
    this.level = const Value.absent(),
  }) : term = Value(term),
       translation = Value(translation);
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<String>? term,
    Expression<String>? translation,
    Expression<String>? transcription,
    Expression<String>? partOfSpeech,
    Expression<String>? exampleSentence,
    Expression<String>? category,
    Expression<String>? level,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (term != null) 'term': term,
      if (translation != null) 'translation': translation,
      if (transcription != null) 'transcription': transcription,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (category != null) 'category': category,
      if (level != null) 'level': level,
    });
  }

  WordsCompanion copyWith({
    Value<int>? id,
    Value<String>? term,
    Value<String>? translation,
    Value<String?>? transcription,
    Value<String?>? partOfSpeech,
    Value<String?>? exampleSentence,
    Value<String?>? category,
    Value<String>? level,
  }) {
    return WordsCompanion(
      id: id ?? this.id,
      term: term ?? this.term,
      translation: translation ?? this.translation,
      transcription: transcription ?? this.transcription,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      category: category ?? this.category,
      level: level ?? this.level,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('term: $term, ')
          ..write('translation: $translation, ')
          ..write('transcription: $transcription, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('exampleSentence: $exampleSentence, ')
          ..write('category: $category, ')
          ..write('level: $level')
          ..write(')'))
        .toString();
  }
}

class $WordProgressesTable extends WordProgresses
    with TableInfo<$WordProgressesTable, WordProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordProgressesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _easePermilleMeta = const VerificationMeta(
    'easePermille',
  );
  @override
  late final GeneratedColumn<int> easePermille = GeneratedColumn<int>(
    'ease_permille',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtUtcMeta = const VerificationMeta(
    'dueAtUtc',
  );
  @override
  late final GeneratedColumn<int> dueAtUtc = GeneratedColumn<int>(
    'due_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstSeenAtUtcMeta = const VerificationMeta(
    'firstSeenAtUtc',
  );
  @override
  late final GeneratedColumn<int> firstSeenAtUtc = GeneratedColumn<int>(
    'first_seen_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtUtcMeta = const VerificationMeta(
    'lastReviewedAtUtc',
  );
  @override
  late final GeneratedColumn<int> lastReviewedAtUtc = GeneratedColumn<int>(
    'last_reviewed_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    easePermille,
    intervalDays,
    repetitions,
    lapses,
    dueAtUtc,
    status,
    firstSeenAtUtc,
    lastReviewedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_progresses';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('ease_permille')) {
      context.handle(
        _easePermilleMeta,
        easePermille.isAcceptableOrUnknown(
          data['ease_permille']!,
          _easePermilleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_easePermilleMeta);
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalDaysMeta);
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repetitionsMeta);
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    } else if (isInserting) {
      context.missing(_lapsesMeta);
    }
    if (data.containsKey('due_at_utc')) {
      context.handle(
        _dueAtUtcMeta,
        dueAtUtc.isAcceptableOrUnknown(data['due_at_utc']!, _dueAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_dueAtUtcMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('first_seen_at_utc')) {
      context.handle(
        _firstSeenAtUtcMeta,
        firstSeenAtUtc.isAcceptableOrUnknown(
          data['first_seen_at_utc']!,
          _firstSeenAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstSeenAtUtcMeta);
    }
    if (data.containsKey('last_reviewed_at_utc')) {
      context.handle(
        _lastReviewedAtUtcMeta,
        lastReviewedAtUtc.isAcceptableOrUnknown(
          data['last_reviewed_at_utc']!,
          _lastReviewedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordProgressRow(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      easePermille: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ease_permille'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      dueAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_at_utc'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      firstSeenAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_seen_at_utc'],
      )!,
      lastReviewedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reviewed_at_utc'],
      ),
    );
  }

  @override
  $WordProgressesTable createAlias(String alias) {
    return $WordProgressesTable(attachedDatabase, alias);
  }
}

class WordProgressRow extends DataClass implements Insertable<WordProgressRow> {
  /// Ссылка на слово; удаление слова удаляет прогресс.
  final int wordId;

  /// Ease-фактор SM-2, умноженный на 1000.
  final int easePermille;

  /// Текущий интервал в днях.
  final int intervalDays;

  /// Успешных повторений подряд.
  final int repetitions;

  /// Провалов.
  final int lapses;

  /// Момент следующего показа, миллисекунды UTC.
  final int dueAtUtc;

  /// Статус: `newWord` | `learning` | `mastered`.
  final String status;

  /// Первое появление, миллисекунды UTC.
  final int firstSeenAtUtc;

  /// Последний ответ, миллисекунды UTC; null — не отвечали.
  final int? lastReviewedAtUtc;
  const WordProgressRow({
    required this.wordId,
    required this.easePermille,
    required this.intervalDays,
    required this.repetitions,
    required this.lapses,
    required this.dueAtUtc,
    required this.status,
    required this.firstSeenAtUtc,
    this.lastReviewedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['ease_permille'] = Variable<int>(easePermille);
    map['interval_days'] = Variable<int>(intervalDays);
    map['repetitions'] = Variable<int>(repetitions);
    map['lapses'] = Variable<int>(lapses);
    map['due_at_utc'] = Variable<int>(dueAtUtc);
    map['status'] = Variable<String>(status);
    map['first_seen_at_utc'] = Variable<int>(firstSeenAtUtc);
    if (!nullToAbsent || lastReviewedAtUtc != null) {
      map['last_reviewed_at_utc'] = Variable<int>(lastReviewedAtUtc);
    }
    return map;
  }

  WordProgressesCompanion toCompanion(bool nullToAbsent) {
    return WordProgressesCompanion(
      wordId: Value(wordId),
      easePermille: Value(easePermille),
      intervalDays: Value(intervalDays),
      repetitions: Value(repetitions),
      lapses: Value(lapses),
      dueAtUtc: Value(dueAtUtc),
      status: Value(status),
      firstSeenAtUtc: Value(firstSeenAtUtc),
      lastReviewedAtUtc: lastReviewedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAtUtc),
    );
  }

  factory WordProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordProgressRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      easePermille: serializer.fromJson<int>(json['easePermille']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      lapses: serializer.fromJson<int>(json['lapses']),
      dueAtUtc: serializer.fromJson<int>(json['dueAtUtc']),
      status: serializer.fromJson<String>(json['status']),
      firstSeenAtUtc: serializer.fromJson<int>(json['firstSeenAtUtc']),
      lastReviewedAtUtc: serializer.fromJson<int?>(json['lastReviewedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'easePermille': serializer.toJson<int>(easePermille),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'repetitions': serializer.toJson<int>(repetitions),
      'lapses': serializer.toJson<int>(lapses),
      'dueAtUtc': serializer.toJson<int>(dueAtUtc),
      'status': serializer.toJson<String>(status),
      'firstSeenAtUtc': serializer.toJson<int>(firstSeenAtUtc),
      'lastReviewedAtUtc': serializer.toJson<int?>(lastReviewedAtUtc),
    };
  }

  WordProgressRow copyWith({
    int? wordId,
    int? easePermille,
    int? intervalDays,
    int? repetitions,
    int? lapses,
    int? dueAtUtc,
    String? status,
    int? firstSeenAtUtc,
    Value<int?> lastReviewedAtUtc = const Value.absent(),
  }) => WordProgressRow(
    wordId: wordId ?? this.wordId,
    easePermille: easePermille ?? this.easePermille,
    intervalDays: intervalDays ?? this.intervalDays,
    repetitions: repetitions ?? this.repetitions,
    lapses: lapses ?? this.lapses,
    dueAtUtc: dueAtUtc ?? this.dueAtUtc,
    status: status ?? this.status,
    firstSeenAtUtc: firstSeenAtUtc ?? this.firstSeenAtUtc,
    lastReviewedAtUtc: lastReviewedAtUtc.present
        ? lastReviewedAtUtc.value
        : this.lastReviewedAtUtc,
  );
  WordProgressRow copyWithCompanion(WordProgressesCompanion data) {
    return WordProgressRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      easePermille: data.easePermille.present
          ? data.easePermille.value
          : this.easePermille,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      dueAtUtc: data.dueAtUtc.present ? data.dueAtUtc.value : this.dueAtUtc,
      status: data.status.present ? data.status.value : this.status,
      firstSeenAtUtc: data.firstSeenAtUtc.present
          ? data.firstSeenAtUtc.value
          : this.firstSeenAtUtc,
      lastReviewedAtUtc: data.lastReviewedAtUtc.present
          ? data.lastReviewedAtUtc.value
          : this.lastReviewedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressRow(')
          ..write('wordId: $wordId, ')
          ..write('easePermille: $easePermille, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAtUtc: $dueAtUtc, ')
          ..write('status: $status, ')
          ..write('firstSeenAtUtc: $firstSeenAtUtc, ')
          ..write('lastReviewedAtUtc: $lastReviewedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    wordId,
    easePermille,
    intervalDays,
    repetitions,
    lapses,
    dueAtUtc,
    status,
    firstSeenAtUtc,
    lastReviewedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordProgressRow &&
          other.wordId == this.wordId &&
          other.easePermille == this.easePermille &&
          other.intervalDays == this.intervalDays &&
          other.repetitions == this.repetitions &&
          other.lapses == this.lapses &&
          other.dueAtUtc == this.dueAtUtc &&
          other.status == this.status &&
          other.firstSeenAtUtc == this.firstSeenAtUtc &&
          other.lastReviewedAtUtc == this.lastReviewedAtUtc);
}

class WordProgressesCompanion extends UpdateCompanion<WordProgressRow> {
  final Value<int> wordId;
  final Value<int> easePermille;
  final Value<int> intervalDays;
  final Value<int> repetitions;
  final Value<int> lapses;
  final Value<int> dueAtUtc;
  final Value<String> status;
  final Value<int> firstSeenAtUtc;
  final Value<int?> lastReviewedAtUtc;
  const WordProgressesCompanion({
    this.wordId = const Value.absent(),
    this.easePermille = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueAtUtc = const Value.absent(),
    this.status = const Value.absent(),
    this.firstSeenAtUtc = const Value.absent(),
    this.lastReviewedAtUtc = const Value.absent(),
  });
  WordProgressesCompanion.insert({
    this.wordId = const Value.absent(),
    required int easePermille,
    required int intervalDays,
    required int repetitions,
    required int lapses,
    required int dueAtUtc,
    required String status,
    required int firstSeenAtUtc,
    this.lastReviewedAtUtc = const Value.absent(),
  }) : easePermille = Value(easePermille),
       intervalDays = Value(intervalDays),
       repetitions = Value(repetitions),
       lapses = Value(lapses),
       dueAtUtc = Value(dueAtUtc),
       status = Value(status),
       firstSeenAtUtc = Value(firstSeenAtUtc);
  static Insertable<WordProgressRow> custom({
    Expression<int>? wordId,
    Expression<int>? easePermille,
    Expression<int>? intervalDays,
    Expression<int>? repetitions,
    Expression<int>? lapses,
    Expression<int>? dueAtUtc,
    Expression<String>? status,
    Expression<int>? firstSeenAtUtc,
    Expression<int>? lastReviewedAtUtc,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (easePermille != null) 'ease_permille': easePermille,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (repetitions != null) 'repetitions': repetitions,
      if (lapses != null) 'lapses': lapses,
      if (dueAtUtc != null) 'due_at_utc': dueAtUtc,
      if (status != null) 'status': status,
      if (firstSeenAtUtc != null) 'first_seen_at_utc': firstSeenAtUtc,
      if (lastReviewedAtUtc != null) 'last_reviewed_at_utc': lastReviewedAtUtc,
    });
  }

  WordProgressesCompanion copyWith({
    Value<int>? wordId,
    Value<int>? easePermille,
    Value<int>? intervalDays,
    Value<int>? repetitions,
    Value<int>? lapses,
    Value<int>? dueAtUtc,
    Value<String>? status,
    Value<int>? firstSeenAtUtc,
    Value<int?>? lastReviewedAtUtc,
  }) {
    return WordProgressesCompanion(
      wordId: wordId ?? this.wordId,
      easePermille: easePermille ?? this.easePermille,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      dueAtUtc: dueAtUtc ?? this.dueAtUtc,
      status: status ?? this.status,
      firstSeenAtUtc: firstSeenAtUtc ?? this.firstSeenAtUtc,
      lastReviewedAtUtc: lastReviewedAtUtc ?? this.lastReviewedAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (easePermille.present) {
      map['ease_permille'] = Variable<int>(easePermille.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (dueAtUtc.present) {
      map['due_at_utc'] = Variable<int>(dueAtUtc.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (firstSeenAtUtc.present) {
      map['first_seen_at_utc'] = Variable<int>(firstSeenAtUtc.value);
    }
    if (lastReviewedAtUtc.present) {
      map['last_reviewed_at_utc'] = Variable<int>(lastReviewedAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordProgressesCompanion(')
          ..write('wordId: $wordId, ')
          ..write('easePermille: $easePermille, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('dueAtUtc: $dueAtUtc, ')
          ..write('status: $status, ')
          ..write('firstSeenAtUtc: $firstSeenAtUtc, ')
          ..write('lastReviewedAtUtc: $lastReviewedAtUtc')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtUtcMeta = const VerificationMeta(
    'reviewedAtUtc',
  );
  @override
  late final GeneratedColumn<int> reviewedAtUtc = GeneratedColumn<int>(
    'reviewed_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevEasePermilleMeta = const VerificationMeta(
    'prevEasePermille',
  );
  @override
  late final GeneratedColumn<int> prevEasePermille = GeneratedColumn<int>(
    'prev_ease_permille',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevIntervalDaysMeta = const VerificationMeta(
    'prevIntervalDays',
  );
  @override
  late final GeneratedColumn<int> prevIntervalDays = GeneratedColumn<int>(
    'prev_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevRepetitionsMeta = const VerificationMeta(
    'prevRepetitions',
  );
  @override
  late final GeneratedColumn<int> prevRepetitions = GeneratedColumn<int>(
    'prev_repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevLapsesMeta = const VerificationMeta(
    'prevLapses',
  );
  @override
  late final GeneratedColumn<int> prevLapses = GeneratedColumn<int>(
    'prev_lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevDueAtUtcMeta = const VerificationMeta(
    'prevDueAtUtc',
  );
  @override
  late final GeneratedColumn<int> prevDueAtUtc = GeneratedColumn<int>(
    'prev_due_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newEasePermilleMeta = const VerificationMeta(
    'newEasePermille',
  );
  @override
  late final GeneratedColumn<int> newEasePermille = GeneratedColumn<int>(
    'new_ease_permille',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newIntervalDaysMeta = const VerificationMeta(
    'newIntervalDays',
  );
  @override
  late final GeneratedColumn<int> newIntervalDays = GeneratedColumn<int>(
    'new_interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newRepetitionsMeta = const VerificationMeta(
    'newRepetitions',
  );
  @override
  late final GeneratedColumn<int> newRepetitions = GeneratedColumn<int>(
    'new_repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newLapsesMeta = const VerificationMeta(
    'newLapses',
  );
  @override
  late final GeneratedColumn<int> newLapses = GeneratedColumn<int>(
    'new_lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newDueAtUtcMeta = const VerificationMeta(
    'newDueAtUtc',
  );
  @override
  late final GeneratedColumn<int> newDueAtUtc = GeneratedColumn<int>(
    'new_due_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordId,
    reviewedAtUtc,
    grade,
    prevEasePermille,
    prevIntervalDays,
    prevRepetitions,
    prevLapses,
    prevDueAtUtc,
    newEasePermille,
    newIntervalDays,
    newRepetitions,
    newLapses,
    newDueAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('reviewed_at_utc')) {
      context.handle(
        _reviewedAtUtcMeta,
        reviewedAtUtc.isAcceptableOrUnknown(
          data['reviewed_at_utc']!,
          _reviewedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtUtcMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('prev_ease_permille')) {
      context.handle(
        _prevEasePermilleMeta,
        prevEasePermille.isAcceptableOrUnknown(
          data['prev_ease_permille']!,
          _prevEasePermilleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prevEasePermilleMeta);
    }
    if (data.containsKey('prev_interval_days')) {
      context.handle(
        _prevIntervalDaysMeta,
        prevIntervalDays.isAcceptableOrUnknown(
          data['prev_interval_days']!,
          _prevIntervalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prevIntervalDaysMeta);
    }
    if (data.containsKey('prev_repetitions')) {
      context.handle(
        _prevRepetitionsMeta,
        prevRepetitions.isAcceptableOrUnknown(
          data['prev_repetitions']!,
          _prevRepetitionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prevRepetitionsMeta);
    }
    if (data.containsKey('prev_lapses')) {
      context.handle(
        _prevLapsesMeta,
        prevLapses.isAcceptableOrUnknown(data['prev_lapses']!, _prevLapsesMeta),
      );
    } else if (isInserting) {
      context.missing(_prevLapsesMeta);
    }
    if (data.containsKey('prev_due_at_utc')) {
      context.handle(
        _prevDueAtUtcMeta,
        prevDueAtUtc.isAcceptableOrUnknown(
          data['prev_due_at_utc']!,
          _prevDueAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prevDueAtUtcMeta);
    }
    if (data.containsKey('new_ease_permille')) {
      context.handle(
        _newEasePermilleMeta,
        newEasePermille.isAcceptableOrUnknown(
          data['new_ease_permille']!,
          _newEasePermilleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newEasePermilleMeta);
    }
    if (data.containsKey('new_interval_days')) {
      context.handle(
        _newIntervalDaysMeta,
        newIntervalDays.isAcceptableOrUnknown(
          data['new_interval_days']!,
          _newIntervalDaysMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newIntervalDaysMeta);
    }
    if (data.containsKey('new_repetitions')) {
      context.handle(
        _newRepetitionsMeta,
        newRepetitions.isAcceptableOrUnknown(
          data['new_repetitions']!,
          _newRepetitionsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newRepetitionsMeta);
    }
    if (data.containsKey('new_lapses')) {
      context.handle(
        _newLapsesMeta,
        newLapses.isAcceptableOrUnknown(data['new_lapses']!, _newLapsesMeta),
      );
    } else if (isInserting) {
      context.missing(_newLapsesMeta);
    }
    if (data.containsKey('new_due_at_utc')) {
      context.handle(
        _newDueAtUtcMeta,
        newDueAtUtc.isAcceptableOrUnknown(
          data['new_due_at_utc']!,
          _newDueAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_newDueAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      reviewedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviewed_at_utc'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      prevEasePermille: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prev_ease_permille'],
      )!,
      prevIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prev_interval_days'],
      )!,
      prevRepetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prev_repetitions'],
      )!,
      prevLapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prev_lapses'],
      )!,
      prevDueAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prev_due_at_utc'],
      )!,
      newEasePermille: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_ease_permille'],
      )!,
      newIntervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_interval_days'],
      )!,
      newRepetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_repetitions'],
      )!,
      newLapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_lapses'],
      )!,
      newDueAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_due_at_utc'],
      )!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLogRow extends DataClass implements Insertable<ReviewLogRow> {
  /// Идентификатор записи журнала.
  final int id;

  /// Слово, к которому относится ответ. Без FK — см. dartdoc класса.
  final int wordId;

  /// Момент ответа, миллисекунды UTC.
  final int reviewedAtUtc;

  /// Оценка: `again` | `hard` | `good` | `easy`.
  final String grade;

  /// Ease до ответа.
  final int prevEasePermille;

  /// Интервал до ответа.
  final int prevIntervalDays;

  /// Повторений до ответа.
  final int prevRepetitions;

  /// Провалов до ответа.
  final int prevLapses;

  /// Дедлайн до ответа, миллисекунды UTC.
  final int prevDueAtUtc;

  /// Ease после ответа.
  final int newEasePermille;

  /// Интервал после ответа.
  final int newIntervalDays;

  /// Повторений после ответа.
  final int newRepetitions;

  /// Провалов после ответа.
  final int newLapses;

  /// Дедлайн после ответа, миллисекунды UTC.
  final int newDueAtUtc;
  const ReviewLogRow({
    required this.id,
    required this.wordId,
    required this.reviewedAtUtc,
    required this.grade,
    required this.prevEasePermille,
    required this.prevIntervalDays,
    required this.prevRepetitions,
    required this.prevLapses,
    required this.prevDueAtUtc,
    required this.newEasePermille,
    required this.newIntervalDays,
    required this.newRepetitions,
    required this.newLapses,
    required this.newDueAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word_id'] = Variable<int>(wordId);
    map['reviewed_at_utc'] = Variable<int>(reviewedAtUtc);
    map['grade'] = Variable<String>(grade);
    map['prev_ease_permille'] = Variable<int>(prevEasePermille);
    map['prev_interval_days'] = Variable<int>(prevIntervalDays);
    map['prev_repetitions'] = Variable<int>(prevRepetitions);
    map['prev_lapses'] = Variable<int>(prevLapses);
    map['prev_due_at_utc'] = Variable<int>(prevDueAtUtc);
    map['new_ease_permille'] = Variable<int>(newEasePermille);
    map['new_interval_days'] = Variable<int>(newIntervalDays);
    map['new_repetitions'] = Variable<int>(newRepetitions);
    map['new_lapses'] = Variable<int>(newLapses);
    map['new_due_at_utc'] = Variable<int>(newDueAtUtc);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      reviewedAtUtc: Value(reviewedAtUtc),
      grade: Value(grade),
      prevEasePermille: Value(prevEasePermille),
      prevIntervalDays: Value(prevIntervalDays),
      prevRepetitions: Value(prevRepetitions),
      prevLapses: Value(prevLapses),
      prevDueAtUtc: Value(prevDueAtUtc),
      newEasePermille: Value(newEasePermille),
      newIntervalDays: Value(newIntervalDays),
      newRepetitions: Value(newRepetitions),
      newLapses: Value(newLapses),
      newDueAtUtc: Value(newDueAtUtc),
    );
  }

  factory ReviewLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogRow(
      id: serializer.fromJson<int>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      reviewedAtUtc: serializer.fromJson<int>(json['reviewedAtUtc']),
      grade: serializer.fromJson<String>(json['grade']),
      prevEasePermille: serializer.fromJson<int>(json['prevEasePermille']),
      prevIntervalDays: serializer.fromJson<int>(json['prevIntervalDays']),
      prevRepetitions: serializer.fromJson<int>(json['prevRepetitions']),
      prevLapses: serializer.fromJson<int>(json['prevLapses']),
      prevDueAtUtc: serializer.fromJson<int>(json['prevDueAtUtc']),
      newEasePermille: serializer.fromJson<int>(json['newEasePermille']),
      newIntervalDays: serializer.fromJson<int>(json['newIntervalDays']),
      newRepetitions: serializer.fromJson<int>(json['newRepetitions']),
      newLapses: serializer.fromJson<int>(json['newLapses']),
      newDueAtUtc: serializer.fromJson<int>(json['newDueAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordId': serializer.toJson<int>(wordId),
      'reviewedAtUtc': serializer.toJson<int>(reviewedAtUtc),
      'grade': serializer.toJson<String>(grade),
      'prevEasePermille': serializer.toJson<int>(prevEasePermille),
      'prevIntervalDays': serializer.toJson<int>(prevIntervalDays),
      'prevRepetitions': serializer.toJson<int>(prevRepetitions),
      'prevLapses': serializer.toJson<int>(prevLapses),
      'prevDueAtUtc': serializer.toJson<int>(prevDueAtUtc),
      'newEasePermille': serializer.toJson<int>(newEasePermille),
      'newIntervalDays': serializer.toJson<int>(newIntervalDays),
      'newRepetitions': serializer.toJson<int>(newRepetitions),
      'newLapses': serializer.toJson<int>(newLapses),
      'newDueAtUtc': serializer.toJson<int>(newDueAtUtc),
    };
  }

  ReviewLogRow copyWith({
    int? id,
    int? wordId,
    int? reviewedAtUtc,
    String? grade,
    int? prevEasePermille,
    int? prevIntervalDays,
    int? prevRepetitions,
    int? prevLapses,
    int? prevDueAtUtc,
    int? newEasePermille,
    int? newIntervalDays,
    int? newRepetitions,
    int? newLapses,
    int? newDueAtUtc,
  }) => ReviewLogRow(
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    reviewedAtUtc: reviewedAtUtc ?? this.reviewedAtUtc,
    grade: grade ?? this.grade,
    prevEasePermille: prevEasePermille ?? this.prevEasePermille,
    prevIntervalDays: prevIntervalDays ?? this.prevIntervalDays,
    prevRepetitions: prevRepetitions ?? this.prevRepetitions,
    prevLapses: prevLapses ?? this.prevLapses,
    prevDueAtUtc: prevDueAtUtc ?? this.prevDueAtUtc,
    newEasePermille: newEasePermille ?? this.newEasePermille,
    newIntervalDays: newIntervalDays ?? this.newIntervalDays,
    newRepetitions: newRepetitions ?? this.newRepetitions,
    newLapses: newLapses ?? this.newLapses,
    newDueAtUtc: newDueAtUtc ?? this.newDueAtUtc,
  );
  ReviewLogRow copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLogRow(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      reviewedAtUtc: data.reviewedAtUtc.present
          ? data.reviewedAtUtc.value
          : this.reviewedAtUtc,
      grade: data.grade.present ? data.grade.value : this.grade,
      prevEasePermille: data.prevEasePermille.present
          ? data.prevEasePermille.value
          : this.prevEasePermille,
      prevIntervalDays: data.prevIntervalDays.present
          ? data.prevIntervalDays.value
          : this.prevIntervalDays,
      prevRepetitions: data.prevRepetitions.present
          ? data.prevRepetitions.value
          : this.prevRepetitions,
      prevLapses: data.prevLapses.present
          ? data.prevLapses.value
          : this.prevLapses,
      prevDueAtUtc: data.prevDueAtUtc.present
          ? data.prevDueAtUtc.value
          : this.prevDueAtUtc,
      newEasePermille: data.newEasePermille.present
          ? data.newEasePermille.value
          : this.newEasePermille,
      newIntervalDays: data.newIntervalDays.present
          ? data.newIntervalDays.value
          : this.newIntervalDays,
      newRepetitions: data.newRepetitions.present
          ? data.newRepetitions.value
          : this.newRepetitions,
      newLapses: data.newLapses.present ? data.newLapses.value : this.newLapses,
      newDueAtUtc: data.newDueAtUtc.present
          ? data.newDueAtUtc.value
          : this.newDueAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogRow(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('reviewedAtUtc: $reviewedAtUtc, ')
          ..write('grade: $grade, ')
          ..write('prevEasePermille: $prevEasePermille, ')
          ..write('prevIntervalDays: $prevIntervalDays, ')
          ..write('prevRepetitions: $prevRepetitions, ')
          ..write('prevLapses: $prevLapses, ')
          ..write('prevDueAtUtc: $prevDueAtUtc, ')
          ..write('newEasePermille: $newEasePermille, ')
          ..write('newIntervalDays: $newIntervalDays, ')
          ..write('newRepetitions: $newRepetitions, ')
          ..write('newLapses: $newLapses, ')
          ..write('newDueAtUtc: $newDueAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordId,
    reviewedAtUtc,
    grade,
    prevEasePermille,
    prevIntervalDays,
    prevRepetitions,
    prevLapses,
    prevDueAtUtc,
    newEasePermille,
    newIntervalDays,
    newRepetitions,
    newLapses,
    newDueAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogRow &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.reviewedAtUtc == this.reviewedAtUtc &&
          other.grade == this.grade &&
          other.prevEasePermille == this.prevEasePermille &&
          other.prevIntervalDays == this.prevIntervalDays &&
          other.prevRepetitions == this.prevRepetitions &&
          other.prevLapses == this.prevLapses &&
          other.prevDueAtUtc == this.prevDueAtUtc &&
          other.newEasePermille == this.newEasePermille &&
          other.newIntervalDays == this.newIntervalDays &&
          other.newRepetitions == this.newRepetitions &&
          other.newLapses == this.newLapses &&
          other.newDueAtUtc == this.newDueAtUtc);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLogRow> {
  final Value<int> id;
  final Value<int> wordId;
  final Value<int> reviewedAtUtc;
  final Value<String> grade;
  final Value<int> prevEasePermille;
  final Value<int> prevIntervalDays;
  final Value<int> prevRepetitions;
  final Value<int> prevLapses;
  final Value<int> prevDueAtUtc;
  final Value<int> newEasePermille;
  final Value<int> newIntervalDays;
  final Value<int> newRepetitions;
  final Value<int> newLapses;
  final Value<int> newDueAtUtc;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.reviewedAtUtc = const Value.absent(),
    this.grade = const Value.absent(),
    this.prevEasePermille = const Value.absent(),
    this.prevIntervalDays = const Value.absent(),
    this.prevRepetitions = const Value.absent(),
    this.prevLapses = const Value.absent(),
    this.prevDueAtUtc = const Value.absent(),
    this.newEasePermille = const Value.absent(),
    this.newIntervalDays = const Value.absent(),
    this.newRepetitions = const Value.absent(),
    this.newLapses = const Value.absent(),
    this.newDueAtUtc = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    this.id = const Value.absent(),
    required int wordId,
    required int reviewedAtUtc,
    required String grade,
    required int prevEasePermille,
    required int prevIntervalDays,
    required int prevRepetitions,
    required int prevLapses,
    required int prevDueAtUtc,
    required int newEasePermille,
    required int newIntervalDays,
    required int newRepetitions,
    required int newLapses,
    required int newDueAtUtc,
  }) : wordId = Value(wordId),
       reviewedAtUtc = Value(reviewedAtUtc),
       grade = Value(grade),
       prevEasePermille = Value(prevEasePermille),
       prevIntervalDays = Value(prevIntervalDays),
       prevRepetitions = Value(prevRepetitions),
       prevLapses = Value(prevLapses),
       prevDueAtUtc = Value(prevDueAtUtc),
       newEasePermille = Value(newEasePermille),
       newIntervalDays = Value(newIntervalDays),
       newRepetitions = Value(newRepetitions),
       newLapses = Value(newLapses),
       newDueAtUtc = Value(newDueAtUtc);
  static Insertable<ReviewLogRow> custom({
    Expression<int>? id,
    Expression<int>? wordId,
    Expression<int>? reviewedAtUtc,
    Expression<String>? grade,
    Expression<int>? prevEasePermille,
    Expression<int>? prevIntervalDays,
    Expression<int>? prevRepetitions,
    Expression<int>? prevLapses,
    Expression<int>? prevDueAtUtc,
    Expression<int>? newEasePermille,
    Expression<int>? newIntervalDays,
    Expression<int>? newRepetitions,
    Expression<int>? newLapses,
    Expression<int>? newDueAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (reviewedAtUtc != null) 'reviewed_at_utc': reviewedAtUtc,
      if (grade != null) 'grade': grade,
      if (prevEasePermille != null) 'prev_ease_permille': prevEasePermille,
      if (prevIntervalDays != null) 'prev_interval_days': prevIntervalDays,
      if (prevRepetitions != null) 'prev_repetitions': prevRepetitions,
      if (prevLapses != null) 'prev_lapses': prevLapses,
      if (prevDueAtUtc != null) 'prev_due_at_utc': prevDueAtUtc,
      if (newEasePermille != null) 'new_ease_permille': newEasePermille,
      if (newIntervalDays != null) 'new_interval_days': newIntervalDays,
      if (newRepetitions != null) 'new_repetitions': newRepetitions,
      if (newLapses != null) 'new_lapses': newLapses,
      if (newDueAtUtc != null) 'new_due_at_utc': newDueAtUtc,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordId,
    Value<int>? reviewedAtUtc,
    Value<String>? grade,
    Value<int>? prevEasePermille,
    Value<int>? prevIntervalDays,
    Value<int>? prevRepetitions,
    Value<int>? prevLapses,
    Value<int>? prevDueAtUtc,
    Value<int>? newEasePermille,
    Value<int>? newIntervalDays,
    Value<int>? newRepetitions,
    Value<int>? newLapses,
    Value<int>? newDueAtUtc,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      reviewedAtUtc: reviewedAtUtc ?? this.reviewedAtUtc,
      grade: grade ?? this.grade,
      prevEasePermille: prevEasePermille ?? this.prevEasePermille,
      prevIntervalDays: prevIntervalDays ?? this.prevIntervalDays,
      prevRepetitions: prevRepetitions ?? this.prevRepetitions,
      prevLapses: prevLapses ?? this.prevLapses,
      prevDueAtUtc: prevDueAtUtc ?? this.prevDueAtUtc,
      newEasePermille: newEasePermille ?? this.newEasePermille,
      newIntervalDays: newIntervalDays ?? this.newIntervalDays,
      newRepetitions: newRepetitions ?? this.newRepetitions,
      newLapses: newLapses ?? this.newLapses,
      newDueAtUtc: newDueAtUtc ?? this.newDueAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (reviewedAtUtc.present) {
      map['reviewed_at_utc'] = Variable<int>(reviewedAtUtc.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (prevEasePermille.present) {
      map['prev_ease_permille'] = Variable<int>(prevEasePermille.value);
    }
    if (prevIntervalDays.present) {
      map['prev_interval_days'] = Variable<int>(prevIntervalDays.value);
    }
    if (prevRepetitions.present) {
      map['prev_repetitions'] = Variable<int>(prevRepetitions.value);
    }
    if (prevLapses.present) {
      map['prev_lapses'] = Variable<int>(prevLapses.value);
    }
    if (prevDueAtUtc.present) {
      map['prev_due_at_utc'] = Variable<int>(prevDueAtUtc.value);
    }
    if (newEasePermille.present) {
      map['new_ease_permille'] = Variable<int>(newEasePermille.value);
    }
    if (newIntervalDays.present) {
      map['new_interval_days'] = Variable<int>(newIntervalDays.value);
    }
    if (newRepetitions.present) {
      map['new_repetitions'] = Variable<int>(newRepetitions.value);
    }
    if (newLapses.present) {
      map['new_lapses'] = Variable<int>(newLapses.value);
    }
    if (newDueAtUtc.present) {
      map['new_due_at_utc'] = Variable<int>(newDueAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('reviewedAtUtc: $reviewedAtUtc, ')
          ..write('grade: $grade, ')
          ..write('prevEasePermille: $prevEasePermille, ')
          ..write('prevIntervalDays: $prevIntervalDays, ')
          ..write('prevRepetitions: $prevRepetitions, ')
          ..write('prevLapses: $prevLapses, ')
          ..write('prevDueAtUtc: $prevDueAtUtc, ')
          ..write('newEasePermille: $newEasePermille, ')
          ..write('newIntervalDays: $newIntervalDays, ')
          ..write('newRepetitions: $newRepetitions, ')
          ..write('newLapses: $newLapses, ')
          ..write('newDueAtUtc: $newDueAtUtc')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTableTable extends UserSettingsTable
    with TableInfo<$UserSettingsTableTable, UserSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyNewLimitMeta = const VerificationMeta(
    'dailyNewLimit',
  );
  @override
  late final GeneratedColumn<int> dailyNewLimit = GeneratedColumn<int>(
    'daily_new_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  static const VerificationMeta _dailyReviewLimitMeta = const VerificationMeta(
    'dailyReviewLimit',
  );
  @override
  late final GeneratedColumn<int> dailyReviewLimit = GeneratedColumn<int>(
    'daily_review_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(50),
  );
  static const VerificationMeta _remindersEnabledMeta = const VerificationMeta(
    'remindersEnabled',
  );
  @override
  late final GeneratedColumn<bool> remindersEnabled = GeneratedColumn<bool>(
    'reminders_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(9),
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ttsVoiceMeta = const VerificationMeta(
    'ttsVoice',
  );
  @override
  late final GeneratedColumn<String> ttsVoice = GeneratedColumn<String>(
    'tts_voice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en-US'),
  );
  static const VerificationMeta _ttsSpeedMeta = const VerificationMeta(
    'ttsSpeed',
  );
  @override
  late final GeneratedColumn<double> ttsSpeed = GeneratedColumn<double>(
    'tts_speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _hasSeenOnboardingMeta = const VerificationMeta(
    'hasSeenOnboarding',
  );
  @override
  late final GeneratedColumn<bool> hasSeenOnboarding = GeneratedColumn<bool>(
    'has_seen_onboarding',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_seen_onboarding" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _preferredLevelMeta = const VerificationMeta(
    'preferredLevel',
  );
  @override
  late final GeneratedColumn<String> preferredLevel = GeneratedColumn<String>(
    'preferred_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('a1'),
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyNewLimit,
    dailyReviewLimit,
    remindersEnabled,
    reminderHour,
    reminderMinute,
    ttsVoice,
    ttsSpeed,
    hasSeenOnboarding,
    preferredLevel,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('daily_new_limit')) {
      context.handle(
        _dailyNewLimitMeta,
        dailyNewLimit.isAcceptableOrUnknown(
          data['daily_new_limit']!,
          _dailyNewLimitMeta,
        ),
      );
    }
    if (data.containsKey('daily_review_limit')) {
      context.handle(
        _dailyReviewLimitMeta,
        dailyReviewLimit.isAcceptableOrUnknown(
          data['daily_review_limit']!,
          _dailyReviewLimitMeta,
        ),
      );
    }
    if (data.containsKey('reminders_enabled')) {
      context.handle(
        _remindersEnabledMeta,
        remindersEnabled.isAcceptableOrUnknown(
          data['reminders_enabled']!,
          _remindersEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('tts_voice')) {
      context.handle(
        _ttsVoiceMeta,
        ttsVoice.isAcceptableOrUnknown(data['tts_voice']!, _ttsVoiceMeta),
      );
    }
    if (data.containsKey('tts_speed')) {
      context.handle(
        _ttsSpeedMeta,
        ttsSpeed.isAcceptableOrUnknown(data['tts_speed']!, _ttsSpeedMeta),
      );
    }
    if (data.containsKey('has_seen_onboarding')) {
      context.handle(
        _hasSeenOnboardingMeta,
        hasSeenOnboarding.isAcceptableOrUnknown(
          data['has_seen_onboarding']!,
          _hasSeenOnboardingMeta,
        ),
      );
    }
    if (data.containsKey('preferred_level')) {
      context.handle(
        _preferredLevelMeta,
        preferredLevel.isAcceptableOrUnknown(
          data['preferred_level']!,
          _preferredLevelMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dailyNewLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_new_limit'],
      )!,
      dailyReviewLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_review_limit'],
      )!,
      remindersEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_enabled'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      )!,
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      )!,
      ttsVoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_voice'],
      )!,
      ttsSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tts_speed'],
      )!,
      hasSeenOnboarding: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_seen_onboarding'],
      )!,
      preferredLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_level'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $UserSettingsTableTable createAlias(String alias) {
    return $UserSettingsTableTable(attachedDatabase, alias);
  }
}

class UserSettingsRow extends DataClass implements Insertable<UserSettingsRow> {
  /// Всегда 1 — синглтон обеспечивается CHECK-констрейнтом.
  final int id;

  /// Лимит новых слов в день.
  final int dailyNewLimit;

  /// Лимит повторений в день.
  final int dailyReviewLimit;

  /// Включены ли напоминания.
  final bool remindersEnabled;

  /// Час напоминания, 0..23.
  final int reminderHour;

  /// Минута напоминания, 0..59.
  final int reminderMinute;

  /// Идентификатор голоса TTS.
  final String ttsVoice;

  /// Скорость речи 0.1..1.0. `real`, а не permille: диапазон узкий,
  /// сравнение в домене идёт через double.
  final double ttsSpeed;

  /// Пройден ли онбординг; false у новых установок (BL-61).
  final bool hasSeenOnboarding;

  /// Уровень пользователя по CEFR меткой: `a0`…`c2` (schema v6, ADR-023).
  ///
  /// Фильтрует новые слова в очереди дня; уже начатые слова не фильтруются.
  final String preferredLevel;

  /// Момент последнего изменения, миллисекунды UTC.
  final int updatedAtUtc;
  const UserSettingsRow({
    required this.id,
    required this.dailyNewLimit,
    required this.dailyReviewLimit,
    required this.remindersEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.ttsVoice,
    required this.ttsSpeed,
    required this.hasSeenOnboarding,
    required this.preferredLevel,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['daily_new_limit'] = Variable<int>(dailyNewLimit);
    map['daily_review_limit'] = Variable<int>(dailyReviewLimit);
    map['reminders_enabled'] = Variable<bool>(remindersEnabled);
    map['reminder_hour'] = Variable<int>(reminderHour);
    map['reminder_minute'] = Variable<int>(reminderMinute);
    map['tts_voice'] = Variable<String>(ttsVoice);
    map['tts_speed'] = Variable<double>(ttsSpeed);
    map['has_seen_onboarding'] = Variable<bool>(hasSeenOnboarding);
    map['preferred_level'] = Variable<String>(preferredLevel);
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    return map;
  }

  UserSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsTableCompanion(
      id: Value(id),
      dailyNewLimit: Value(dailyNewLimit),
      dailyReviewLimit: Value(dailyReviewLimit),
      remindersEnabled: Value(remindersEnabled),
      reminderHour: Value(reminderHour),
      reminderMinute: Value(reminderMinute),
      ttsVoice: Value(ttsVoice),
      ttsSpeed: Value(ttsSpeed),
      hasSeenOnboarding: Value(hasSeenOnboarding),
      preferredLevel: Value(preferredLevel),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory UserSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      dailyNewLimit: serializer.fromJson<int>(json['dailyNewLimit']),
      dailyReviewLimit: serializer.fromJson<int>(json['dailyReviewLimit']),
      remindersEnabled: serializer.fromJson<bool>(json['remindersEnabled']),
      reminderHour: serializer.fromJson<int>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int>(json['reminderMinute']),
      ttsVoice: serializer.fromJson<String>(json['ttsVoice']),
      ttsSpeed: serializer.fromJson<double>(json['ttsSpeed']),
      hasSeenOnboarding: serializer.fromJson<bool>(json['hasSeenOnboarding']),
      preferredLevel: serializer.fromJson<String>(json['preferredLevel']),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dailyNewLimit': serializer.toJson<int>(dailyNewLimit),
      'dailyReviewLimit': serializer.toJson<int>(dailyReviewLimit),
      'remindersEnabled': serializer.toJson<bool>(remindersEnabled),
      'reminderHour': serializer.toJson<int>(reminderHour),
      'reminderMinute': serializer.toJson<int>(reminderMinute),
      'ttsVoice': serializer.toJson<String>(ttsVoice),
      'ttsSpeed': serializer.toJson<double>(ttsSpeed),
      'hasSeenOnboarding': serializer.toJson<bool>(hasSeenOnboarding),
      'preferredLevel': serializer.toJson<String>(preferredLevel),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
    };
  }

  UserSettingsRow copyWith({
    int? id,
    int? dailyNewLimit,
    int? dailyReviewLimit,
    bool? remindersEnabled,
    int? reminderHour,
    int? reminderMinute,
    String? ttsVoice,
    double? ttsSpeed,
    bool? hasSeenOnboarding,
    String? preferredLevel,
    int? updatedAtUtc,
  }) => UserSettingsRow(
    id: id ?? this.id,
    dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
    dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
    remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
    ttsVoice: ttsVoice ?? this.ttsVoice,
    ttsSpeed: ttsSpeed ?? this.ttsSpeed,
    hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    preferredLevel: preferredLevel ?? this.preferredLevel,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  UserSettingsRow copyWithCompanion(UserSettingsTableCompanion data) {
    return UserSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      dailyNewLimit: data.dailyNewLimit.present
          ? data.dailyNewLimit.value
          : this.dailyNewLimit,
      dailyReviewLimit: data.dailyReviewLimit.present
          ? data.dailyReviewLimit.value
          : this.dailyReviewLimit,
      remindersEnabled: data.remindersEnabled.present
          ? data.remindersEnabled.value
          : this.remindersEnabled,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      ttsVoice: data.ttsVoice.present ? data.ttsVoice.value : this.ttsVoice,
      ttsSpeed: data.ttsSpeed.present ? data.ttsSpeed.value : this.ttsSpeed,
      hasSeenOnboarding: data.hasSeenOnboarding.present
          ? data.hasSeenOnboarding.value
          : this.hasSeenOnboarding,
      preferredLevel: data.preferredLevel.present
          ? data.preferredLevel.value
          : this.preferredLevel,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsRow(')
          ..write('id: $id, ')
          ..write('dailyNewLimit: $dailyNewLimit, ')
          ..write('dailyReviewLimit: $dailyReviewLimit, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('ttsVoice: $ttsVoice, ')
          ..write('ttsSpeed: $ttsSpeed, ')
          ..write('hasSeenOnboarding: $hasSeenOnboarding, ')
          ..write('preferredLevel: $preferredLevel, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyNewLimit,
    dailyReviewLimit,
    remindersEnabled,
    reminderHour,
    reminderMinute,
    ttsVoice,
    ttsSpeed,
    hasSeenOnboarding,
    preferredLevel,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSettingsRow &&
          other.id == this.id &&
          other.dailyNewLimit == this.dailyNewLimit &&
          other.dailyReviewLimit == this.dailyReviewLimit &&
          other.remindersEnabled == this.remindersEnabled &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.ttsVoice == this.ttsVoice &&
          other.ttsSpeed == this.ttsSpeed &&
          other.hasSeenOnboarding == this.hasSeenOnboarding &&
          other.preferredLevel == this.preferredLevel &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class UserSettingsTableCompanion extends UpdateCompanion<UserSettingsRow> {
  final Value<int> id;
  final Value<int> dailyNewLimit;
  final Value<int> dailyReviewLimit;
  final Value<bool> remindersEnabled;
  final Value<int> reminderHour;
  final Value<int> reminderMinute;
  final Value<String> ttsVoice;
  final Value<double> ttsSpeed;
  final Value<bool> hasSeenOnboarding;
  final Value<String> preferredLevel;
  final Value<int> updatedAtUtc;
  const UserSettingsTableCompanion({
    this.id = const Value.absent(),
    this.dailyNewLimit = const Value.absent(),
    this.dailyReviewLimit = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.ttsVoice = const Value.absent(),
    this.ttsSpeed = const Value.absent(),
    this.hasSeenOnboarding = const Value.absent(),
    this.preferredLevel = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
  });
  UserSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.dailyNewLimit = const Value.absent(),
    this.dailyReviewLimit = const Value.absent(),
    this.remindersEnabled = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.ttsVoice = const Value.absent(),
    this.ttsSpeed = const Value.absent(),
    this.hasSeenOnboarding = const Value.absent(),
    this.preferredLevel = const Value.absent(),
    required int updatedAtUtc,
  }) : updatedAtUtc = Value(updatedAtUtc);
  static Insertable<UserSettingsRow> custom({
    Expression<int>? id,
    Expression<int>? dailyNewLimit,
    Expression<int>? dailyReviewLimit,
    Expression<bool>? remindersEnabled,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<String>? ttsVoice,
    Expression<double>? ttsSpeed,
    Expression<bool>? hasSeenOnboarding,
    Expression<String>? preferredLevel,
    Expression<int>? updatedAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyNewLimit != null) 'daily_new_limit': dailyNewLimit,
      if (dailyReviewLimit != null) 'daily_review_limit': dailyReviewLimit,
      if (remindersEnabled != null) 'reminders_enabled': remindersEnabled,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (ttsVoice != null) 'tts_voice': ttsVoice,
      if (ttsSpeed != null) 'tts_speed': ttsSpeed,
      if (hasSeenOnboarding != null) 'has_seen_onboarding': hasSeenOnboarding,
      if (preferredLevel != null) 'preferred_level': preferredLevel,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
    });
  }

  UserSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? dailyNewLimit,
    Value<int>? dailyReviewLimit,
    Value<bool>? remindersEnabled,
    Value<int>? reminderHour,
    Value<int>? reminderMinute,
    Value<String>? ttsVoice,
    Value<double>? ttsSpeed,
    Value<bool>? hasSeenOnboarding,
    Value<String>? preferredLevel,
    Value<int>? updatedAtUtc,
  }) {
    return UserSettingsTableCompanion(
      id: id ?? this.id,
      dailyNewLimit: dailyNewLimit ?? this.dailyNewLimit,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      preferredLevel: preferredLevel ?? this.preferredLevel,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dailyNewLimit.present) {
      map['daily_new_limit'] = Variable<int>(dailyNewLimit.value);
    }
    if (dailyReviewLimit.present) {
      map['daily_review_limit'] = Variable<int>(dailyReviewLimit.value);
    }
    if (remindersEnabled.present) {
      map['reminders_enabled'] = Variable<bool>(remindersEnabled.value);
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (ttsVoice.present) {
      map['tts_voice'] = Variable<String>(ttsVoice.value);
    }
    if (ttsSpeed.present) {
      map['tts_speed'] = Variable<double>(ttsSpeed.value);
    }
    if (hasSeenOnboarding.present) {
      map['has_seen_onboarding'] = Variable<bool>(hasSeenOnboarding.value);
    }
    if (preferredLevel.present) {
      map['preferred_level'] = Variable<String>(preferredLevel.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('dailyNewLimit: $dailyNewLimit, ')
          ..write('dailyReviewLimit: $dailyReviewLimit, ')
          ..write('remindersEnabled: $remindersEnabled, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('ttsVoice: $ttsVoice, ')
          ..write('ttsSpeed: $ttsSpeed, ')
          ..write('hasSeenOnboarding: $hasSeenOnboarding, ')
          ..write('preferredLevel: $preferredLevel, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }
}

class $DailyStatsTableTable extends DailyStatsTable
    with TableInfo<$DailyStatsTableTable, DailyStatsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStatsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateEpochDaysMeta = const VerificationMeta(
    'dateEpochDays',
  );
  @override
  late final GeneratedColumn<int> dateEpochDays = GeneratedColumn<int>(
    'date_epoch_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newWordsStudiedMeta = const VerificationMeta(
    'newWordsStudied',
  );
  @override
  late final GeneratedColumn<int> newWordsStudied = GeneratedColumn<int>(
    'new_words_studied',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewsCompletedMeta = const VerificationMeta(
    'reviewsCompleted',
  );
  @override
  late final GeneratedColumn<int> reviewsCompleted = GeneratedColumn<int>(
    'reviews_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xpGainedMeta = const VerificationMeta(
    'xpGained',
  );
  @override
  late final GeneratedColumn<int> xpGained = GeneratedColumn<int>(
    'xp_gained',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctAnswersMeta = const VerificationMeta(
    'correctAnswers',
  );
  @override
  late final GeneratedColumn<int> correctAnswers = GeneratedColumn<int>(
    'correct_answers',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    dateEpochDays,
    newWordsStudied,
    reviewsCompleted,
    xpGained,
    correctAnswers,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyStatsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_epoch_days')) {
      context.handle(
        _dateEpochDaysMeta,
        dateEpochDays.isAcceptableOrUnknown(
          data['date_epoch_days']!,
          _dateEpochDaysMeta,
        ),
      );
    }
    if (data.containsKey('new_words_studied')) {
      context.handle(
        _newWordsStudiedMeta,
        newWordsStudied.isAcceptableOrUnknown(
          data['new_words_studied']!,
          _newWordsStudiedMeta,
        ),
      );
    }
    if (data.containsKey('reviews_completed')) {
      context.handle(
        _reviewsCompletedMeta,
        reviewsCompleted.isAcceptableOrUnknown(
          data['reviews_completed']!,
          _reviewsCompletedMeta,
        ),
      );
    }
    if (data.containsKey('xp_gained')) {
      context.handle(
        _xpGainedMeta,
        xpGained.isAcceptableOrUnknown(data['xp_gained']!, _xpGainedMeta),
      );
    }
    if (data.containsKey('correct_answers')) {
      context.handle(
        _correctAnswersMeta,
        correctAnswers.isAcceptableOrUnknown(
          data['correct_answers']!,
          _correctAnswersMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateEpochDays};
  @override
  DailyStatsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStatsRow(
      dateEpochDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_epoch_days'],
      )!,
      newWordsStudied: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_words_studied'],
      )!,
      reviewsCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reviews_completed'],
      )!,
      xpGained: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_gained'],
      )!,
      correctAnswers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_answers'],
      )!,
    );
  }

  @override
  $DailyStatsTableTable createAlias(String alias) {
    return $DailyStatsTableTable(attachedDatabase, alias);
  }
}

class DailyStatsRow extends DataClass implements Insertable<DailyStatsRow> {
  /// День в локальной TZ как число дней от эпохи.
  final int dateEpochDays;

  /// Новых слов показано.
  final int newWordsStudied;

  /// Повторений завершено.
  final int reviewsCompleted;

  /// XP за день.
  final int xpGained;

  /// Успешных ответов.
  final int correctAnswers;
  const DailyStatsRow({
    required this.dateEpochDays,
    required this.newWordsStudied,
    required this.reviewsCompleted,
    required this.xpGained,
    required this.correctAnswers,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_epoch_days'] = Variable<int>(dateEpochDays);
    map['new_words_studied'] = Variable<int>(newWordsStudied);
    map['reviews_completed'] = Variable<int>(reviewsCompleted);
    map['xp_gained'] = Variable<int>(xpGained);
    map['correct_answers'] = Variable<int>(correctAnswers);
    return map;
  }

  DailyStatsTableCompanion toCompanion(bool nullToAbsent) {
    return DailyStatsTableCompanion(
      dateEpochDays: Value(dateEpochDays),
      newWordsStudied: Value(newWordsStudied),
      reviewsCompleted: Value(reviewsCompleted),
      xpGained: Value(xpGained),
      correctAnswers: Value(correctAnswers),
    );
  }

  factory DailyStatsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStatsRow(
      dateEpochDays: serializer.fromJson<int>(json['dateEpochDays']),
      newWordsStudied: serializer.fromJson<int>(json['newWordsStudied']),
      reviewsCompleted: serializer.fromJson<int>(json['reviewsCompleted']),
      xpGained: serializer.fromJson<int>(json['xpGained']),
      correctAnswers: serializer.fromJson<int>(json['correctAnswers']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateEpochDays': serializer.toJson<int>(dateEpochDays),
      'newWordsStudied': serializer.toJson<int>(newWordsStudied),
      'reviewsCompleted': serializer.toJson<int>(reviewsCompleted),
      'xpGained': serializer.toJson<int>(xpGained),
      'correctAnswers': serializer.toJson<int>(correctAnswers),
    };
  }

  DailyStatsRow copyWith({
    int? dateEpochDays,
    int? newWordsStudied,
    int? reviewsCompleted,
    int? xpGained,
    int? correctAnswers,
  }) => DailyStatsRow(
    dateEpochDays: dateEpochDays ?? this.dateEpochDays,
    newWordsStudied: newWordsStudied ?? this.newWordsStudied,
    reviewsCompleted: reviewsCompleted ?? this.reviewsCompleted,
    xpGained: xpGained ?? this.xpGained,
    correctAnswers: correctAnswers ?? this.correctAnswers,
  );
  DailyStatsRow copyWithCompanion(DailyStatsTableCompanion data) {
    return DailyStatsRow(
      dateEpochDays: data.dateEpochDays.present
          ? data.dateEpochDays.value
          : this.dateEpochDays,
      newWordsStudied: data.newWordsStudied.present
          ? data.newWordsStudied.value
          : this.newWordsStudied,
      reviewsCompleted: data.reviewsCompleted.present
          ? data.reviewsCompleted.value
          : this.reviewsCompleted,
      xpGained: data.xpGained.present ? data.xpGained.value : this.xpGained,
      correctAnswers: data.correctAnswers.present
          ? data.correctAnswers.value
          : this.correctAnswers,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsRow(')
          ..write('dateEpochDays: $dateEpochDays, ')
          ..write('newWordsStudied: $newWordsStudied, ')
          ..write('reviewsCompleted: $reviewsCompleted, ')
          ..write('xpGained: $xpGained, ')
          ..write('correctAnswers: $correctAnswers')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dateEpochDays,
    newWordsStudied,
    reviewsCompleted,
    xpGained,
    correctAnswers,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStatsRow &&
          other.dateEpochDays == this.dateEpochDays &&
          other.newWordsStudied == this.newWordsStudied &&
          other.reviewsCompleted == this.reviewsCompleted &&
          other.xpGained == this.xpGained &&
          other.correctAnswers == this.correctAnswers);
}

class DailyStatsTableCompanion extends UpdateCompanion<DailyStatsRow> {
  final Value<int> dateEpochDays;
  final Value<int> newWordsStudied;
  final Value<int> reviewsCompleted;
  final Value<int> xpGained;
  final Value<int> correctAnswers;
  const DailyStatsTableCompanion({
    this.dateEpochDays = const Value.absent(),
    this.newWordsStudied = const Value.absent(),
    this.reviewsCompleted = const Value.absent(),
    this.xpGained = const Value.absent(),
    this.correctAnswers = const Value.absent(),
  });
  DailyStatsTableCompanion.insert({
    this.dateEpochDays = const Value.absent(),
    this.newWordsStudied = const Value.absent(),
    this.reviewsCompleted = const Value.absent(),
    this.xpGained = const Value.absent(),
    this.correctAnswers = const Value.absent(),
  });
  static Insertable<DailyStatsRow> custom({
    Expression<int>? dateEpochDays,
    Expression<int>? newWordsStudied,
    Expression<int>? reviewsCompleted,
    Expression<int>? xpGained,
    Expression<int>? correctAnswers,
  }) {
    return RawValuesInsertable({
      if (dateEpochDays != null) 'date_epoch_days': dateEpochDays,
      if (newWordsStudied != null) 'new_words_studied': newWordsStudied,
      if (reviewsCompleted != null) 'reviews_completed': reviewsCompleted,
      if (xpGained != null) 'xp_gained': xpGained,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
    });
  }

  DailyStatsTableCompanion copyWith({
    Value<int>? dateEpochDays,
    Value<int>? newWordsStudied,
    Value<int>? reviewsCompleted,
    Value<int>? xpGained,
    Value<int>? correctAnswers,
  }) {
    return DailyStatsTableCompanion(
      dateEpochDays: dateEpochDays ?? this.dateEpochDays,
      newWordsStudied: newWordsStudied ?? this.newWordsStudied,
      reviewsCompleted: reviewsCompleted ?? this.reviewsCompleted,
      xpGained: xpGained ?? this.xpGained,
      correctAnswers: correctAnswers ?? this.correctAnswers,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateEpochDays.present) {
      map['date_epoch_days'] = Variable<int>(dateEpochDays.value);
    }
    if (newWordsStudied.present) {
      map['new_words_studied'] = Variable<int>(newWordsStudied.value);
    }
    if (reviewsCompleted.present) {
      map['reviews_completed'] = Variable<int>(reviewsCompleted.value);
    }
    if (xpGained.present) {
      map['xp_gained'] = Variable<int>(xpGained.value);
    }
    if (correctAnswers.present) {
      map['correct_answers'] = Variable<int>(correctAnswers.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsTableCompanion(')
          ..write('dateEpochDays: $dateEpochDays, ')
          ..write('newWordsStudied: $newWordsStudied, ')
          ..write('reviewsCompleted: $reviewsCompleted, ')
          ..write('xpGained: $xpGained, ')
          ..write('correctAnswers: $correctAnswers')
          ..write(')'))
        .toString();
  }
}

class $FrozenDaysTable extends FrozenDays
    with TableInfo<$FrozenDaysTable, FrozenDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FrozenDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateEpochDaysMeta = const VerificationMeta(
    'dateEpochDays',
  );
  @override
  late final GeneratedColumn<int> dateEpochDays = GeneratedColumn<int>(
    'date_epoch_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consumedAtUtcMeta = const VerificationMeta(
    'consumedAtUtc',
  );
  @override
  late final GeneratedColumn<int> consumedAtUtc = GeneratedColumn<int>(
    'consumed_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dateEpochDays, consumedAtUtc, reason];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frozen_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<FrozenDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_epoch_days')) {
      context.handle(
        _dateEpochDaysMeta,
        dateEpochDays.isAcceptableOrUnknown(
          data['date_epoch_days']!,
          _dateEpochDaysMeta,
        ),
      );
    }
    if (data.containsKey('consumed_at_utc')) {
      context.handle(
        _consumedAtUtcMeta,
        consumedAtUtc.isAcceptableOrUnknown(
          data['consumed_at_utc']!,
          _consumedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consumedAtUtcMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateEpochDays};
  @override
  FrozenDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FrozenDayRow(
      dateEpochDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_epoch_days'],
      )!,
      consumedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consumed_at_utc'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
    );
  }

  @override
  $FrozenDaysTable createAlias(String alias) {
    return $FrozenDaysTable(attachedDatabase, alias);
  }
}

class FrozenDayRow extends DataClass implements Insertable<FrozenDayRow> {
  /// День в локальной TZ как число дней от эпохи.
  final int dateEpochDays;

  /// Момент, когда заморозка была израсходована, миллисекунды UTC.
  final int consumedAtUtc;

  /// Причина: `missedDay` | `manual`.
  final String reason;
  const FrozenDayRow({
    required this.dateEpochDays,
    required this.consumedAtUtc,
    required this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_epoch_days'] = Variable<int>(dateEpochDays);
    map['consumed_at_utc'] = Variable<int>(consumedAtUtc);
    map['reason'] = Variable<String>(reason);
    return map;
  }

  FrozenDaysCompanion toCompanion(bool nullToAbsent) {
    return FrozenDaysCompanion(
      dateEpochDays: Value(dateEpochDays),
      consumedAtUtc: Value(consumedAtUtc),
      reason: Value(reason),
    );
  }

  factory FrozenDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FrozenDayRow(
      dateEpochDays: serializer.fromJson<int>(json['dateEpochDays']),
      consumedAtUtc: serializer.fromJson<int>(json['consumedAtUtc']),
      reason: serializer.fromJson<String>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateEpochDays': serializer.toJson<int>(dateEpochDays),
      'consumedAtUtc': serializer.toJson<int>(consumedAtUtc),
      'reason': serializer.toJson<String>(reason),
    };
  }

  FrozenDayRow copyWith({
    int? dateEpochDays,
    int? consumedAtUtc,
    String? reason,
  }) => FrozenDayRow(
    dateEpochDays: dateEpochDays ?? this.dateEpochDays,
    consumedAtUtc: consumedAtUtc ?? this.consumedAtUtc,
    reason: reason ?? this.reason,
  );
  FrozenDayRow copyWithCompanion(FrozenDaysCompanion data) {
    return FrozenDayRow(
      dateEpochDays: data.dateEpochDays.present
          ? data.dateEpochDays.value
          : this.dateEpochDays,
      consumedAtUtc: data.consumedAtUtc.present
          ? data.consumedAtUtc.value
          : this.consumedAtUtc,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FrozenDayRow(')
          ..write('dateEpochDays: $dateEpochDays, ')
          ..write('consumedAtUtc: $consumedAtUtc, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dateEpochDays, consumedAtUtc, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FrozenDayRow &&
          other.dateEpochDays == this.dateEpochDays &&
          other.consumedAtUtc == this.consumedAtUtc &&
          other.reason == this.reason);
}

class FrozenDaysCompanion extends UpdateCompanion<FrozenDayRow> {
  final Value<int> dateEpochDays;
  final Value<int> consumedAtUtc;
  final Value<String> reason;
  const FrozenDaysCompanion({
    this.dateEpochDays = const Value.absent(),
    this.consumedAtUtc = const Value.absent(),
    this.reason = const Value.absent(),
  });
  FrozenDaysCompanion.insert({
    this.dateEpochDays = const Value.absent(),
    required int consumedAtUtc,
    required String reason,
  }) : consumedAtUtc = Value(consumedAtUtc),
       reason = Value(reason);
  static Insertable<FrozenDayRow> custom({
    Expression<int>? dateEpochDays,
    Expression<int>? consumedAtUtc,
    Expression<String>? reason,
  }) {
    return RawValuesInsertable({
      if (dateEpochDays != null) 'date_epoch_days': dateEpochDays,
      if (consumedAtUtc != null) 'consumed_at_utc': consumedAtUtc,
      if (reason != null) 'reason': reason,
    });
  }

  FrozenDaysCompanion copyWith({
    Value<int>? dateEpochDays,
    Value<int>? consumedAtUtc,
    Value<String>? reason,
  }) {
    return FrozenDaysCompanion(
      dateEpochDays: dateEpochDays ?? this.dateEpochDays,
      consumedAtUtc: consumedAtUtc ?? this.consumedAtUtc,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateEpochDays.present) {
      map['date_epoch_days'] = Variable<int>(dateEpochDays.value);
    }
    if (consumedAtUtc.present) {
      map['consumed_at_utc'] = Variable<int>(consumedAtUtc.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FrozenDaysCompanion(')
          ..write('dateEpochDays: $dateEpochDays, ')
          ..write('consumedAtUtc: $consumedAtUtc, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }
}

class $WordHintsTable extends WordHints
    with TableInfo<$WordHintsTable, WordHintRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordHintsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _termMeta = const VerificationMeta('term');
  @override
  late final GeneratedColumn<String> term = GeneratedColumn<String>(
    'term',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintTextMeta = const VerificationMeta(
    'hintText',
  );
  @override
  late final GeneratedColumn<String> hintText = GeneratedColumn<String>(
    'hint_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [wordId, term, hintText, createdAtUtc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_hints';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordHintRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('term')) {
      context.handle(
        _termMeta,
        term.isAcceptableOrUnknown(data['term']!, _termMeta),
      );
    } else if (isInserting) {
      context.missing(_termMeta);
    }
    if (data.containsKey('hint_text')) {
      context.handle(
        _hintTextMeta,
        hintText.isAcceptableOrUnknown(data['hint_text']!, _hintTextMeta),
      );
    } else if (isInserting) {
      context.missing(_hintTextMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  WordHintRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordHintRow(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      term: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}term'],
      )!,
      hintText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hint_text'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $WordHintsTable createAlias(String alias) {
    return $WordHintsTable(attachedDatabase, alias);
  }
}

class WordHintRow extends DataClass implements Insertable<WordHintRow> {
  /// Слово, к которому относится подсказка.
  final int wordId;

  /// Написание слова на момент генерации.
  final String term;

  /// Текст подсказки.
  final String hintText;

  /// Момент сохранения, миллисекунды UTC.
  final int createdAtUtc;
  const WordHintRow({
    required this.wordId,
    required this.term,
    required this.hintText,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['term'] = Variable<String>(term);
    map['hint_text'] = Variable<String>(hintText);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    return map;
  }

  WordHintsCompanion toCompanion(bool nullToAbsent) {
    return WordHintsCompanion(
      wordId: Value(wordId),
      term: Value(term),
      hintText: Value(hintText),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory WordHintRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordHintRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      term: serializer.fromJson<String>(json['term']),
      hintText: serializer.fromJson<String>(json['hintText']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'term': serializer.toJson<String>(term),
      'hintText': serializer.toJson<String>(hintText),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
    };
  }

  WordHintRow copyWith({
    int? wordId,
    String? term,
    String? hintText,
    int? createdAtUtc,
  }) => WordHintRow(
    wordId: wordId ?? this.wordId,
    term: term ?? this.term,
    hintText: hintText ?? this.hintText,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  WordHintRow copyWithCompanion(WordHintsCompanion data) {
    return WordHintRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      term: data.term.present ? data.term.value : this.term,
      hintText: data.hintText.present ? data.hintText.value : this.hintText,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordHintRow(')
          ..write('wordId: $wordId, ')
          ..write('term: $term, ')
          ..write('hintText: $hintText, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, term, hintText, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordHintRow &&
          other.wordId == this.wordId &&
          other.term == this.term &&
          other.hintText == this.hintText &&
          other.createdAtUtc == this.createdAtUtc);
}

class WordHintsCompanion extends UpdateCompanion<WordHintRow> {
  final Value<int> wordId;
  final Value<String> term;
  final Value<String> hintText;
  final Value<int> createdAtUtc;
  const WordHintsCompanion({
    this.wordId = const Value.absent(),
    this.term = const Value.absent(),
    this.hintText = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
  });
  WordHintsCompanion.insert({
    this.wordId = const Value.absent(),
    required String term,
    required String hintText,
    required int createdAtUtc,
  }) : term = Value(term),
       hintText = Value(hintText),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<WordHintRow> custom({
    Expression<int>? wordId,
    Expression<String>? term,
    Expression<String>? hintText,
    Expression<int>? createdAtUtc,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (term != null) 'term': term,
      if (hintText != null) 'hint_text': hintText,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
    });
  }

  WordHintsCompanion copyWith({
    Value<int>? wordId,
    Value<String>? term,
    Value<String>? hintText,
    Value<int>? createdAtUtc,
  }) {
    return WordHintsCompanion(
      wordId: wordId ?? this.wordId,
      term: term ?? this.term,
      hintText: hintText ?? this.hintText,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (term.present) {
      map['term'] = Variable<String>(term.value);
    }
    if (hintText.present) {
      map['hint_text'] = Variable<String>(hintText.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordHintsCompanion(')
          ..write('wordId: $wordId, ')
          ..write('term: $term, ')
          ..write('hintText: $hintText, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }
}

class $ClozeTasksTable extends ClozeTasks
    with TableInfo<$ClozeTasksTable, ClozeTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClozeTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES words (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sentenceMeta = const VerificationMeta(
    'sentence',
  );
  @override
  late final GeneratedColumn<String> sentence = GeneratedColumn<String>(
    'sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordId,
    sentence,
    answer,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloze_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClozeTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(
        _wordIdMeta,
        wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta),
      );
    }
    if (data.containsKey('sentence')) {
      context.handle(
        _sentenceMeta,
        sentence.isAcceptableOrUnknown(data['sentence']!, _sentenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId};
  @override
  ClozeTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClozeTaskRow(
      wordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_id'],
      )!,
      sentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $ClozeTasksTable createAlias(String alias) {
    return $ClozeTasksTable(attachedDatabase, alias);
  }
}

class ClozeTaskRow extends DataClass implements Insertable<ClozeTaskRow> {
  /// Слово, к которому относится задание.
  final int wordId;

  /// Предложение с пропуском `___`.
  final String sentence;

  /// Слово-ответ.
  final String answer;

  /// Момент генерации, миллисекунды UTC.
  final int createdAtUtc;
  const ClozeTaskRow({
    required this.wordId,
    required this.sentence,
    required this.answer,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['sentence'] = Variable<String>(sentence);
    map['answer'] = Variable<String>(answer);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    return map;
  }

  ClozeTasksCompanion toCompanion(bool nullToAbsent) {
    return ClozeTasksCompanion(
      wordId: Value(wordId),
      sentence: Value(sentence),
      answer: Value(answer),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory ClozeTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClozeTaskRow(
      wordId: serializer.fromJson<int>(json['wordId']),
      sentence: serializer.fromJson<String>(json['sentence']),
      answer: serializer.fromJson<String>(json['answer']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'sentence': serializer.toJson<String>(sentence),
      'answer': serializer.toJson<String>(answer),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
    };
  }

  ClozeTaskRow copyWith({
    int? wordId,
    String? sentence,
    String? answer,
    int? createdAtUtc,
  }) => ClozeTaskRow(
    wordId: wordId ?? this.wordId,
    sentence: sentence ?? this.sentence,
    answer: answer ?? this.answer,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  ClozeTaskRow copyWithCompanion(ClozeTasksCompanion data) {
    return ClozeTaskRow(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      sentence: data.sentence.present ? data.sentence.value : this.sentence,
      answer: data.answer.present ? data.answer.value : this.answer,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClozeTaskRow(')
          ..write('wordId: $wordId, ')
          ..write('sentence: $sentence, ')
          ..write('answer: $answer, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordId, sentence, answer, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClozeTaskRow &&
          other.wordId == this.wordId &&
          other.sentence == this.sentence &&
          other.answer == this.answer &&
          other.createdAtUtc == this.createdAtUtc);
}

class ClozeTasksCompanion extends UpdateCompanion<ClozeTaskRow> {
  final Value<int> wordId;
  final Value<String> sentence;
  final Value<String> answer;
  final Value<int> createdAtUtc;
  const ClozeTasksCompanion({
    this.wordId = const Value.absent(),
    this.sentence = const Value.absent(),
    this.answer = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
  });
  ClozeTasksCompanion.insert({
    this.wordId = const Value.absent(),
    required String sentence,
    required String answer,
    required int createdAtUtc,
  }) : sentence = Value(sentence),
       answer = Value(answer),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<ClozeTaskRow> custom({
    Expression<int>? wordId,
    Expression<String>? sentence,
    Expression<String>? answer,
    Expression<int>? createdAtUtc,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (sentence != null) 'sentence': sentence,
      if (answer != null) 'answer': answer,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
    });
  }

  ClozeTasksCompanion copyWith({
    Value<int>? wordId,
    Value<String>? sentence,
    Value<String>? answer,
    Value<int>? createdAtUtc,
  }) {
    return ClozeTasksCompanion(
      wordId: wordId ?? this.wordId,
      sentence: sentence ?? this.sentence,
      answer: answer ?? this.answer,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (sentence.present) {
      map['sentence'] = Variable<String>(sentence.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClozeTasksCompanion(')
          ..write('wordId: $wordId, ')
          ..write('sentence: $sentence, ')
          ..write('answer: $answer, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }
}

class $DailyChallengesTable extends DailyChallenges
    with TableInfo<$DailyChallengesTable, DailyChallengeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyChallengesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateEpochDaysMeta = const VerificationMeta(
    'dateEpochDays',
  );
  @override
  late final GeneratedColumn<int> dateEpochDays = GeneratedColumn<int>(
    'date_epoch_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _goalTypeMeta = const VerificationMeta(
    'goalType',
  );
  @override
  late final GeneratedColumn<String> goalType = GeneratedColumn<String>(
    'goal_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalValueMeta = const VerificationMeta(
    'goalValue',
  );
  @override
  late final GeneratedColumn<int> goalValue = GeneratedColumn<int>(
    'goal_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completedAtUtcMeta = const VerificationMeta(
    'completedAtUtc',
  );
  @override
  late final GeneratedColumn<int> completedAtUtc = GeneratedColumn<int>(
    'completed_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _claimedAtUtcMeta = const VerificationMeta(
    'claimedAtUtc',
  );
  @override
  late final GeneratedColumn<int> claimedAtUtc = GeneratedColumn<int>(
    'claimed_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xpRewardMeta = const VerificationMeta(
    'xpReward',
  );
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
    'xp_reward',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dateEpochDays,
    goalType,
    goalValue,
    progress,
    completedAtUtc,
    claimedAtUtc,
    xpReward,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_challenges';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyChallengeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_epoch_days')) {
      context.handle(
        _dateEpochDaysMeta,
        dateEpochDays.isAcceptableOrUnknown(
          data['date_epoch_days']!,
          _dateEpochDaysMeta,
        ),
      );
    }
    if (data.containsKey('goal_type')) {
      context.handle(
        _goalTypeMeta,
        goalType.isAcceptableOrUnknown(data['goal_type']!, _goalTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_goalTypeMeta);
    }
    if (data.containsKey('goal_value')) {
      context.handle(
        _goalValueMeta,
        goalValue.isAcceptableOrUnknown(data['goal_value']!, _goalValueMeta),
      );
    } else if (isInserting) {
      context.missing(_goalValueMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('completed_at_utc')) {
      context.handle(
        _completedAtUtcMeta,
        completedAtUtc.isAcceptableOrUnknown(
          data['completed_at_utc']!,
          _completedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('claimed_at_utc')) {
      context.handle(
        _claimedAtUtcMeta,
        claimedAtUtc.isAcceptableOrUnknown(
          data['claimed_at_utc']!,
          _claimedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('xp_reward')) {
      context.handle(
        _xpRewardMeta,
        xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta),
      );
    } else if (isInserting) {
      context.missing(_xpRewardMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateEpochDays};
  @override
  DailyChallengeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyChallengeRow(
      dateEpochDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}date_epoch_days'],
      )!,
      goalType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_type'],
      )!,
      goalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_value'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      completedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_utc'],
      ),
      claimedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}claimed_at_utc'],
      ),
      xpReward: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_reward'],
      )!,
    );
  }

  @override
  $DailyChallengesTable createAlias(String alias) {
    return $DailyChallengesTable(attachedDatabase, alias);
  }
}

class DailyChallengeRow extends DataClass
    implements Insertable<DailyChallengeRow> {
  /// День в локальной TZ как число дней от эпохи.
  final int dateEpochDays;

  /// Тип задания: имя значения `DailyChallengeType`.
  final String goalType;

  /// Сколько единиц нужно набрать.
  final int goalValue;

  /// Текущий прогресс. Может уменьшаться: серийные задания сбрасываются.
  final int progress;

  /// Момент выполнения, миллисекунды UTC; null — ещё не выполнено.
  final int? completedAtUtc;

  /// Момент получения награды, миллисекунды UTC; null — не забрана.
  final int? claimedAtUtc;

  /// Сколько XP начисляется за награду.
  final int xpReward;
  const DailyChallengeRow({
    required this.dateEpochDays,
    required this.goalType,
    required this.goalValue,
    required this.progress,
    this.completedAtUtc,
    this.claimedAtUtc,
    required this.xpReward,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_epoch_days'] = Variable<int>(dateEpochDays);
    map['goal_type'] = Variable<String>(goalType);
    map['goal_value'] = Variable<int>(goalValue);
    map['progress'] = Variable<int>(progress);
    if (!nullToAbsent || completedAtUtc != null) {
      map['completed_at_utc'] = Variable<int>(completedAtUtc);
    }
    if (!nullToAbsent || claimedAtUtc != null) {
      map['claimed_at_utc'] = Variable<int>(claimedAtUtc);
    }
    map['xp_reward'] = Variable<int>(xpReward);
    return map;
  }

  DailyChallengesCompanion toCompanion(bool nullToAbsent) {
    return DailyChallengesCompanion(
      dateEpochDays: Value(dateEpochDays),
      goalType: Value(goalType),
      goalValue: Value(goalValue),
      progress: Value(progress),
      completedAtUtc: completedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtc),
      claimedAtUtc: claimedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(claimedAtUtc),
      xpReward: Value(xpReward),
    );
  }

  factory DailyChallengeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyChallengeRow(
      dateEpochDays: serializer.fromJson<int>(json['dateEpochDays']),
      goalType: serializer.fromJson<String>(json['goalType']),
      goalValue: serializer.fromJson<int>(json['goalValue']),
      progress: serializer.fromJson<int>(json['progress']),
      completedAtUtc: serializer.fromJson<int?>(json['completedAtUtc']),
      claimedAtUtc: serializer.fromJson<int?>(json['claimedAtUtc']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateEpochDays': serializer.toJson<int>(dateEpochDays),
      'goalType': serializer.toJson<String>(goalType),
      'goalValue': serializer.toJson<int>(goalValue),
      'progress': serializer.toJson<int>(progress),
      'completedAtUtc': serializer.toJson<int?>(completedAtUtc),
      'claimedAtUtc': serializer.toJson<int?>(claimedAtUtc),
      'xpReward': serializer.toJson<int>(xpReward),
    };
  }

  DailyChallengeRow copyWith({
    int? dateEpochDays,
    String? goalType,
    int? goalValue,
    int? progress,
    Value<int?> completedAtUtc = const Value.absent(),
    Value<int?> claimedAtUtc = const Value.absent(),
    int? xpReward,
  }) => DailyChallengeRow(
    dateEpochDays: dateEpochDays ?? this.dateEpochDays,
    goalType: goalType ?? this.goalType,
    goalValue: goalValue ?? this.goalValue,
    progress: progress ?? this.progress,
    completedAtUtc: completedAtUtc.present
        ? completedAtUtc.value
        : this.completedAtUtc,
    claimedAtUtc: claimedAtUtc.present ? claimedAtUtc.value : this.claimedAtUtc,
    xpReward: xpReward ?? this.xpReward,
  );
  DailyChallengeRow copyWithCompanion(DailyChallengesCompanion data) {
    return DailyChallengeRow(
      dateEpochDays: data.dateEpochDays.present
          ? data.dateEpochDays.value
          : this.dateEpochDays,
      goalType: data.goalType.present ? data.goalType.value : this.goalType,
      goalValue: data.goalValue.present ? data.goalValue.value : this.goalValue,
      progress: data.progress.present ? data.progress.value : this.progress,
      completedAtUtc: data.completedAtUtc.present
          ? data.completedAtUtc.value
          : this.completedAtUtc,
      claimedAtUtc: data.claimedAtUtc.present
          ? data.claimedAtUtc.value
          : this.claimedAtUtc,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyChallengeRow(')
          ..write('dateEpochDays: $dateEpochDays, ')
          ..write('goalType: $goalType, ')
          ..write('goalValue: $goalValue, ')
          ..write('progress: $progress, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('claimedAtUtc: $claimedAtUtc, ')
          ..write('xpReward: $xpReward')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dateEpochDays,
    goalType,
    goalValue,
    progress,
    completedAtUtc,
    claimedAtUtc,
    xpReward,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyChallengeRow &&
          other.dateEpochDays == this.dateEpochDays &&
          other.goalType == this.goalType &&
          other.goalValue == this.goalValue &&
          other.progress == this.progress &&
          other.completedAtUtc == this.completedAtUtc &&
          other.claimedAtUtc == this.claimedAtUtc &&
          other.xpReward == this.xpReward);
}

class DailyChallengesCompanion extends UpdateCompanion<DailyChallengeRow> {
  final Value<int> dateEpochDays;
  final Value<String> goalType;
  final Value<int> goalValue;
  final Value<int> progress;
  final Value<int?> completedAtUtc;
  final Value<int?> claimedAtUtc;
  final Value<int> xpReward;
  const DailyChallengesCompanion({
    this.dateEpochDays = const Value.absent(),
    this.goalType = const Value.absent(),
    this.goalValue = const Value.absent(),
    this.progress = const Value.absent(),
    this.completedAtUtc = const Value.absent(),
    this.claimedAtUtc = const Value.absent(),
    this.xpReward = const Value.absent(),
  });
  DailyChallengesCompanion.insert({
    this.dateEpochDays = const Value.absent(),
    required String goalType,
    required int goalValue,
    this.progress = const Value.absent(),
    this.completedAtUtc = const Value.absent(),
    this.claimedAtUtc = const Value.absent(),
    required int xpReward,
  }) : goalType = Value(goalType),
       goalValue = Value(goalValue),
       xpReward = Value(xpReward);
  static Insertable<DailyChallengeRow> custom({
    Expression<int>? dateEpochDays,
    Expression<String>? goalType,
    Expression<int>? goalValue,
    Expression<int>? progress,
    Expression<int>? completedAtUtc,
    Expression<int>? claimedAtUtc,
    Expression<int>? xpReward,
  }) {
    return RawValuesInsertable({
      if (dateEpochDays != null) 'date_epoch_days': dateEpochDays,
      if (goalType != null) 'goal_type': goalType,
      if (goalValue != null) 'goal_value': goalValue,
      if (progress != null) 'progress': progress,
      if (completedAtUtc != null) 'completed_at_utc': completedAtUtc,
      if (claimedAtUtc != null) 'claimed_at_utc': claimedAtUtc,
      if (xpReward != null) 'xp_reward': xpReward,
    });
  }

  DailyChallengesCompanion copyWith({
    Value<int>? dateEpochDays,
    Value<String>? goalType,
    Value<int>? goalValue,
    Value<int>? progress,
    Value<int?>? completedAtUtc,
    Value<int?>? claimedAtUtc,
    Value<int>? xpReward,
  }) {
    return DailyChallengesCompanion(
      dateEpochDays: dateEpochDays ?? this.dateEpochDays,
      goalType: goalType ?? this.goalType,
      goalValue: goalValue ?? this.goalValue,
      progress: progress ?? this.progress,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      claimedAtUtc: claimedAtUtc ?? this.claimedAtUtc,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateEpochDays.present) {
      map['date_epoch_days'] = Variable<int>(dateEpochDays.value);
    }
    if (goalType.present) {
      map['goal_type'] = Variable<String>(goalType.value);
    }
    if (goalValue.present) {
      map['goal_value'] = Variable<int>(goalValue.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (completedAtUtc.present) {
      map['completed_at_utc'] = Variable<int>(completedAtUtc.value);
    }
    if (claimedAtUtc.present) {
      map['claimed_at_utc'] = Variable<int>(claimedAtUtc.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyChallengesCompanion(')
          ..write('dateEpochDays: $dateEpochDays, ')
          ..write('goalType: $goalType, ')
          ..write('goalValue: $goalValue, ')
          ..write('progress: $progress, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('claimedAtUtc: $claimedAtUtc, ')
          ..write('xpReward: $xpReward')
          ..write(')'))
        .toString();
  }
}

class $ChallengeStreaksTable extends ChallengeStreaks
    with TableInfo<$ChallengeStreaksTable, ChallengeStreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChallengeStreaksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestStreakMeta = const VerificationMeta(
    'bestStreak',
  );
  @override
  late final GeneratedColumn<int> bestStreak = GeneratedColumn<int>(
    'best_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCompletedDateEpochDaysMeta =
      const VerificationMeta('lastCompletedDateEpochDays');
  @override
  late final GeneratedColumn<int> lastCompletedDateEpochDays =
      GeneratedColumn<int>(
        'last_completed_date_epoch_days',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtc = GeneratedColumn<int>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentStreak,
    bestStreak,
    lastCompletedDateEpochDays,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'challenge_streaks';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChallengeStreakRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('best_streak')) {
      context.handle(
        _bestStreakMeta,
        bestStreak.isAcceptableOrUnknown(data['best_streak']!, _bestStreakMeta),
      );
    }
    if (data.containsKey('last_completed_date_epoch_days')) {
      context.handle(
        _lastCompletedDateEpochDaysMeta,
        lastCompletedDateEpochDays.isAcceptableOrUnknown(
          data['last_completed_date_epoch_days']!,
          _lastCompletedDateEpochDaysMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChallengeStreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChallengeStreakRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      bestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_streak'],
      )!,
      lastCompletedDateEpochDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_completed_date_epoch_days'],
      ),
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $ChallengeStreaksTable createAlias(String alias) {
    return $ChallengeStreaksTable(attachedDatabase, alias);
  }
}

class ChallengeStreakRow extends DataClass
    implements Insertable<ChallengeStreakRow> {
  /// Всегда 1 — синглтон обеспечивается CHECK-констрейнтом.
  final int id;

  /// Текущая серия дней подряд.
  final int currentStreak;

  /// Лучшая серия за всё время; не уменьшается.
  final int bestStreak;

  /// День последнего выполненного задания; null — ещё ни одного.
  final int? lastCompletedDateEpochDays;

  /// Момент последнего изменения, миллисекунды UTC.
  final int updatedAtUtc;
  const ChallengeStreakRow({
    required this.id,
    required this.currentStreak,
    required this.bestStreak,
    this.lastCompletedDateEpochDays,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current_streak'] = Variable<int>(currentStreak);
    map['best_streak'] = Variable<int>(bestStreak);
    if (!nullToAbsent || lastCompletedDateEpochDays != null) {
      map['last_completed_date_epoch_days'] = Variable<int>(
        lastCompletedDateEpochDays,
      );
    }
    map['updated_at_utc'] = Variable<int>(updatedAtUtc);
    return map;
  }

  ChallengeStreaksCompanion toCompanion(bool nullToAbsent) {
    return ChallengeStreaksCompanion(
      id: Value(id),
      currentStreak: Value(currentStreak),
      bestStreak: Value(bestStreak),
      lastCompletedDateEpochDays:
          lastCompletedDateEpochDays == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDateEpochDays),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory ChallengeStreakRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChallengeStreakRow(
      id: serializer.fromJson<int>(json['id']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      bestStreak: serializer.fromJson<int>(json['bestStreak']),
      lastCompletedDateEpochDays: serializer.fromJson<int?>(
        json['lastCompletedDateEpochDays'],
      ),
      updatedAtUtc: serializer.fromJson<int>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'bestStreak': serializer.toJson<int>(bestStreak),
      'lastCompletedDateEpochDays': serializer.toJson<int?>(
        lastCompletedDateEpochDays,
      ),
      'updatedAtUtc': serializer.toJson<int>(updatedAtUtc),
    };
  }

  ChallengeStreakRow copyWith({
    int? id,
    int? currentStreak,
    int? bestStreak,
    Value<int?> lastCompletedDateEpochDays = const Value.absent(),
    int? updatedAtUtc,
  }) => ChallengeStreakRow(
    id: id ?? this.id,
    currentStreak: currentStreak ?? this.currentStreak,
    bestStreak: bestStreak ?? this.bestStreak,
    lastCompletedDateEpochDays: lastCompletedDateEpochDays.present
        ? lastCompletedDateEpochDays.value
        : this.lastCompletedDateEpochDays,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  ChallengeStreakRow copyWithCompanion(ChallengeStreaksCompanion data) {
    return ChallengeStreakRow(
      id: data.id.present ? data.id.value : this.id,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      bestStreak: data.bestStreak.present
          ? data.bestStreak.value
          : this.bestStreak,
      lastCompletedDateEpochDays: data.lastCompletedDateEpochDays.present
          ? data.lastCompletedDateEpochDays.value
          : this.lastCompletedDateEpochDays,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeStreakRow(')
          ..write('id: $id, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('bestStreak: $bestStreak, ')
          ..write('lastCompletedDateEpochDays: $lastCompletedDateEpochDays, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currentStreak,
    bestStreak,
    lastCompletedDateEpochDays,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChallengeStreakRow &&
          other.id == this.id &&
          other.currentStreak == this.currentStreak &&
          other.bestStreak == this.bestStreak &&
          other.lastCompletedDateEpochDays == this.lastCompletedDateEpochDays &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class ChallengeStreaksCompanion extends UpdateCompanion<ChallengeStreakRow> {
  final Value<int> id;
  final Value<int> currentStreak;
  final Value<int> bestStreak;
  final Value<int?> lastCompletedDateEpochDays;
  final Value<int> updatedAtUtc;
  const ChallengeStreaksCompanion({
    this.id = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.bestStreak = const Value.absent(),
    this.lastCompletedDateEpochDays = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
  });
  ChallengeStreaksCompanion.insert({
    this.id = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.bestStreak = const Value.absent(),
    this.lastCompletedDateEpochDays = const Value.absent(),
    required int updatedAtUtc,
  }) : updatedAtUtc = Value(updatedAtUtc);
  static Insertable<ChallengeStreakRow> custom({
    Expression<int>? id,
    Expression<int>? currentStreak,
    Expression<int>? bestStreak,
    Expression<int>? lastCompletedDateEpochDays,
    Expression<int>? updatedAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (bestStreak != null) 'best_streak': bestStreak,
      if (lastCompletedDateEpochDays != null)
        'last_completed_date_epoch_days': lastCompletedDateEpochDays,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
    });
  }

  ChallengeStreaksCompanion copyWith({
    Value<int>? id,
    Value<int>? currentStreak,
    Value<int>? bestStreak,
    Value<int?>? lastCompletedDateEpochDays,
    Value<int>? updatedAtUtc,
  }) {
    return ChallengeStreaksCompanion(
      id: id ?? this.id,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastCompletedDateEpochDays:
          lastCompletedDateEpochDays ?? this.lastCompletedDateEpochDays,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (bestStreak.present) {
      map['best_streak'] = Variable<int>(bestStreak.value);
    }
    if (lastCompletedDateEpochDays.present) {
      map['last_completed_date_epoch_days'] = Variable<int>(
        lastCompletedDateEpochDays.value,
      );
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<int>(updatedAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChallengeStreaksCompanion(')
          ..write('id: $id, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('bestStreak: $bestStreak, ')
          ..write('lastCompletedDateEpochDays: $lastCompletedDateEpochDays, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }
}

class $UserCategoriesTable extends UserCategories
    with TableInfo<$UserCategoriesTable, UserCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorHex, createdAtUtc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $UserCategoriesTable createAlias(String alias) {
    return $UserCategoriesTable(attachedDatabase, alias);
  }
}

class UserCategoryRow extends DataClass implements Insertable<UserCategoryRow> {
  /// Автоинкремент: id базовых категорий фиксированы миграцией (1..4).
  final int id;

  /// Название категории; уникально, регистр не нормализуется в БД.
  final String name;

  /// Цвет для чипа в UI, например `#FF5722`; null — цвет по умолчанию.
  final String? colorHex;

  /// Момент создания, миллисекунды UTC.
  final int createdAtUtc;
  const UserCategoryRow({
    required this.id,
    required this.name,
    this.colorHex,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    return map;
  }

  UserCategoriesCompanion toCompanion(bool nullToAbsent) {
    return UserCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory UserCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserCategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String?>(colorHex),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
    };
  }

  UserCategoryRow copyWith({
    int? id,
    String? name,
    Value<String?> colorHex = const Value.absent(),
    int? createdAtUtc,
  }) => UserCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  UserCategoryRow copyWithCompanion(UserCategoriesCompanion data) {
    return UserCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.createdAtUtc == this.createdAtUtc);
}

class UserCategoriesCompanion extends UpdateCompanion<UserCategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> colorHex;
  final Value<int> createdAtUtc;
  const UserCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
  });
  UserCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.colorHex = const Value.absent(),
    required int createdAtUtc,
  }) : name = Value(name),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<UserCategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<int>? createdAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
    });
  }

  UserCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? colorHex,
    Value<int>? createdAtUtc,
  }) {
    return UserCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, AchievementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedAtUtcMeta = const VerificationMeta(
    'unlockedAtUtc',
  );
  @override
  late final GeneratedColumn<int> unlockedAtUtc = GeneratedColumn<int>(
    'unlocked_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastUpdatedAtUtcMeta = const VerificationMeta(
    'lastUpdatedAtUtc',
  );
  @override
  late final GeneratedColumn<int> lastUpdatedAtUtc = GeneratedColumn<int>(
    'last_updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    unlockedAtUtc,
    progress,
    lastUpdatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<AchievementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('unlocked_at_utc')) {
      context.handle(
        _unlockedAtUtcMeta,
        unlockedAtUtc.isAcceptableOrUnknown(
          data['unlocked_at_utc']!,
          _unlockedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('last_updated_at_utc')) {
      context.handle(
        _lastUpdatedAtUtcMeta,
        lastUpdatedAtUtc.isAcceptableOrUnknown(
          data['last_updated_at_utc']!,
          _lastUpdatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AchievementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AchievementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      unlockedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unlocked_at_utc'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      )!,
      lastUpdatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated_at_utc'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class AchievementRow extends DataClass implements Insertable<AchievementRow> {
  /// Ключ достижения из `AchievementType.key`.
  final String id;

  /// Момент разблокировки, миллисекунды UTC; null — ещё не открыто.
  final int? unlockedAtUtc;

  /// Текущий прогресс по метрике достижения.
  final int progress;

  /// Момент последнего пересчёта, миллисекунды UTC.
  final int lastUpdatedAtUtc;
  const AchievementRow({
    required this.id,
    this.unlockedAtUtc,
    required this.progress,
    required this.lastUpdatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || unlockedAtUtc != null) {
      map['unlocked_at_utc'] = Variable<int>(unlockedAtUtc);
    }
    map['progress'] = Variable<int>(progress);
    map['last_updated_at_utc'] = Variable<int>(lastUpdatedAtUtc);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      unlockedAtUtc: unlockedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAtUtc),
      progress: Value(progress),
      lastUpdatedAtUtc: Value(lastUpdatedAtUtc),
    );
  }

  factory AchievementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AchievementRow(
      id: serializer.fromJson<String>(json['id']),
      unlockedAtUtc: serializer.fromJson<int?>(json['unlockedAtUtc']),
      progress: serializer.fromJson<int>(json['progress']),
      lastUpdatedAtUtc: serializer.fromJson<int>(json['lastUpdatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'unlockedAtUtc': serializer.toJson<int?>(unlockedAtUtc),
      'progress': serializer.toJson<int>(progress),
      'lastUpdatedAtUtc': serializer.toJson<int>(lastUpdatedAtUtc),
    };
  }

  AchievementRow copyWith({
    String? id,
    Value<int?> unlockedAtUtc = const Value.absent(),
    int? progress,
    int? lastUpdatedAtUtc,
  }) => AchievementRow(
    id: id ?? this.id,
    unlockedAtUtc: unlockedAtUtc.present
        ? unlockedAtUtc.value
        : this.unlockedAtUtc,
    progress: progress ?? this.progress,
    lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
  );
  AchievementRow copyWithCompanion(AchievementsCompanion data) {
    return AchievementRow(
      id: data.id.present ? data.id.value : this.id,
      unlockedAtUtc: data.unlockedAtUtc.present
          ? data.unlockedAtUtc.value
          : this.unlockedAtUtc,
      progress: data.progress.present ? data.progress.value : this.progress,
      lastUpdatedAtUtc: data.lastUpdatedAtUtc.present
          ? data.lastUpdatedAtUtc.value
          : this.lastUpdatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AchievementRow(')
          ..write('id: $id, ')
          ..write('unlockedAtUtc: $unlockedAtUtc, ')
          ..write('progress: $progress, ')
          ..write('lastUpdatedAtUtc: $lastUpdatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, unlockedAtUtc, progress, lastUpdatedAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AchievementRow &&
          other.id == this.id &&
          other.unlockedAtUtc == this.unlockedAtUtc &&
          other.progress == this.progress &&
          other.lastUpdatedAtUtc == this.lastUpdatedAtUtc);
}

class AchievementsCompanion extends UpdateCompanion<AchievementRow> {
  final Value<String> id;
  final Value<int?> unlockedAtUtc;
  final Value<int> progress;
  final Value<int> lastUpdatedAtUtc;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.unlockedAtUtc = const Value.absent(),
    this.progress = const Value.absent(),
    this.lastUpdatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    this.unlockedAtUtc = const Value.absent(),
    this.progress = const Value.absent(),
    required int lastUpdatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lastUpdatedAtUtc = Value(lastUpdatedAtUtc);
  static Insertable<AchievementRow> custom({
    Expression<String>? id,
    Expression<int>? unlockedAtUtc,
    Expression<int>? progress,
    Expression<int>? lastUpdatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (unlockedAtUtc != null) 'unlocked_at_utc': unlockedAtUtc,
      if (progress != null) 'progress': progress,
      if (lastUpdatedAtUtc != null) 'last_updated_at_utc': lastUpdatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith({
    Value<String>? id,
    Value<int?>? unlockedAtUtc,
    Value<int>? progress,
    Value<int>? lastUpdatedAtUtc,
    Value<int>? rowid,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      unlockedAtUtc: unlockedAtUtc ?? this.unlockedAtUtc,
      progress: progress ?? this.progress,
      lastUpdatedAtUtc: lastUpdatedAtUtc ?? this.lastUpdatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (unlockedAtUtc.present) {
      map['unlocked_at_utc'] = Variable<int>(unlockedAtUtc.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (lastUpdatedAtUtc.present) {
      map['last_updated_at_utc'] = Variable<int>(lastUpdatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('unlockedAtUtc: $unlockedAtUtc, ')
          ..write('progress: $progress, ')
          ..write('lastUpdatedAtUtc: $lastUpdatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TypingRecordsTable extends TypingRecords
    with TableInfo<$TypingRecordsTable, TypingRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TypingRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _wordsCountMeta = const VerificationMeta(
    'wordsCount',
  );
  @override
  late final GeneratedColumn<int> wordsCount = GeneratedColumn<int>(
    'words_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wpmMeta = const VerificationMeta('wpm');
  @override
  late final GeneratedColumn<int> wpm = GeneratedColumn<int>(
    'wpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyPercentMeta = const VerificationMeta(
    'accuracyPercent',
  );
  @override
  late final GeneratedColumn<int> accuracyPercent = GeneratedColumn<int>(
    'accuracy_percent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    wordsCount,
    correctCount,
    durationSeconds,
    wpm,
    accuracyPercent,
    score,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'typing_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<TypingRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('words_count')) {
      context.handle(
        _wordsCountMeta,
        wordsCount.isAcceptableOrUnknown(data['words_count']!, _wordsCountMeta),
      );
    } else if (isInserting) {
      context.missing(_wordsCountMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctCountMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('wpm')) {
      context.handle(
        _wpmMeta,
        wpm.isAcceptableOrUnknown(data['wpm']!, _wpmMeta),
      );
    } else if (isInserting) {
      context.missing(_wpmMeta);
    }
    if (data.containsKey('accuracy_percent')) {
      context.handle(
        _accuracyPercentMeta,
        accuracyPercent.isAcceptableOrUnknown(
          data['accuracy_percent']!,
          _accuracyPercentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accuracyPercentMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TypingRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TypingRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      wordsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}words_count'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      wpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wpm'],
      )!,
      accuracyPercent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accuracy_percent'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $TypingRecordsTable createAlias(String alias) {
    return $TypingRecordsTable(attachedDatabase, alias);
  }
}

class TypingRecordRow extends DataClass implements Insertable<TypingRecordRow> {
  /// Автоинкремент: записи только добавляются.
  final int id;

  /// Сколько слов было в сессии.
  final int wordsCount;

  /// Сколько набрано верно.
  final int correctCount;

  /// Длительность сессии в секундах.
  final int durationSeconds;

  /// Слов в минуту.
  final int wpm;

  /// Точность в процентах, 0..100.
  final int accuracyPercent;

  /// Итоговые очки: WPM, взвешенный точностью.
  final int score;

  /// Момент завершения, миллисекунды UTC.
  final int createdAtUtc;
  const TypingRecordRow({
    required this.id,
    required this.wordsCount,
    required this.correctCount,
    required this.durationSeconds,
    required this.wpm,
    required this.accuracyPercent,
    required this.score,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['words_count'] = Variable<int>(wordsCount);
    map['correct_count'] = Variable<int>(correctCount);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['wpm'] = Variable<int>(wpm);
    map['accuracy_percent'] = Variable<int>(accuracyPercent);
    map['score'] = Variable<int>(score);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    return map;
  }

  TypingRecordsCompanion toCompanion(bool nullToAbsent) {
    return TypingRecordsCompanion(
      id: Value(id),
      wordsCount: Value(wordsCount),
      correctCount: Value(correctCount),
      durationSeconds: Value(durationSeconds),
      wpm: Value(wpm),
      accuracyPercent: Value(accuracyPercent),
      score: Value(score),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory TypingRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TypingRecordRow(
      id: serializer.fromJson<int>(json['id']),
      wordsCount: serializer.fromJson<int>(json['wordsCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      wpm: serializer.fromJson<int>(json['wpm']),
      accuracyPercent: serializer.fromJson<int>(json['accuracyPercent']),
      score: serializer.fromJson<int>(json['score']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'wordsCount': serializer.toJson<int>(wordsCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'wpm': serializer.toJson<int>(wpm),
      'accuracyPercent': serializer.toJson<int>(accuracyPercent),
      'score': serializer.toJson<int>(score),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
    };
  }

  TypingRecordRow copyWith({
    int? id,
    int? wordsCount,
    int? correctCount,
    int? durationSeconds,
    int? wpm,
    int? accuracyPercent,
    int? score,
    int? createdAtUtc,
  }) => TypingRecordRow(
    id: id ?? this.id,
    wordsCount: wordsCount ?? this.wordsCount,
    correctCount: correctCount ?? this.correctCount,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    wpm: wpm ?? this.wpm,
    accuracyPercent: accuracyPercent ?? this.accuracyPercent,
    score: score ?? this.score,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  TypingRecordRow copyWithCompanion(TypingRecordsCompanion data) {
    return TypingRecordRow(
      id: data.id.present ? data.id.value : this.id,
      wordsCount: data.wordsCount.present
          ? data.wordsCount.value
          : this.wordsCount,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      wpm: data.wpm.present ? data.wpm.value : this.wpm,
      accuracyPercent: data.accuracyPercent.present
          ? data.accuracyPercent.value
          : this.accuracyPercent,
      score: data.score.present ? data.score.value : this.score,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TypingRecordRow(')
          ..write('id: $id, ')
          ..write('wordsCount: $wordsCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('wpm: $wpm, ')
          ..write('accuracyPercent: $accuracyPercent, ')
          ..write('score: $score, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    wordsCount,
    correctCount,
    durationSeconds,
    wpm,
    accuracyPercent,
    score,
    createdAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TypingRecordRow &&
          other.id == this.id &&
          other.wordsCount == this.wordsCount &&
          other.correctCount == this.correctCount &&
          other.durationSeconds == this.durationSeconds &&
          other.wpm == this.wpm &&
          other.accuracyPercent == this.accuracyPercent &&
          other.score == this.score &&
          other.createdAtUtc == this.createdAtUtc);
}

class TypingRecordsCompanion extends UpdateCompanion<TypingRecordRow> {
  final Value<int> id;
  final Value<int> wordsCount;
  final Value<int> correctCount;
  final Value<int> durationSeconds;
  final Value<int> wpm;
  final Value<int> accuracyPercent;
  final Value<int> score;
  final Value<int> createdAtUtc;
  const TypingRecordsCompanion({
    this.id = const Value.absent(),
    this.wordsCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.wpm = const Value.absent(),
    this.accuracyPercent = const Value.absent(),
    this.score = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
  });
  TypingRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int wordsCount,
    required int correctCount,
    required int durationSeconds,
    required int wpm,
    required int accuracyPercent,
    required int score,
    required int createdAtUtc,
  }) : wordsCount = Value(wordsCount),
       correctCount = Value(correctCount),
       durationSeconds = Value(durationSeconds),
       wpm = Value(wpm),
       accuracyPercent = Value(accuracyPercent),
       score = Value(score),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<TypingRecordRow> custom({
    Expression<int>? id,
    Expression<int>? wordsCount,
    Expression<int>? correctCount,
    Expression<int>? durationSeconds,
    Expression<int>? wpm,
    Expression<int>? accuracyPercent,
    Expression<int>? score,
    Expression<int>? createdAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordsCount != null) 'words_count': wordsCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (wpm != null) 'wpm': wpm,
      if (accuracyPercent != null) 'accuracy_percent': accuracyPercent,
      if (score != null) 'score': score,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
    });
  }

  TypingRecordsCompanion copyWith({
    Value<int>? id,
    Value<int>? wordsCount,
    Value<int>? correctCount,
    Value<int>? durationSeconds,
    Value<int>? wpm,
    Value<int>? accuracyPercent,
    Value<int>? score,
    Value<int>? createdAtUtc,
  }) {
    return TypingRecordsCompanion(
      id: id ?? this.id,
      wordsCount: wordsCount ?? this.wordsCount,
      correctCount: correctCount ?? this.correctCount,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      wpm: wpm ?? this.wpm,
      accuracyPercent: accuracyPercent ?? this.accuracyPercent,
      score: score ?? this.score,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (wordsCount.present) {
      map['words_count'] = Variable<int>(wordsCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (wpm.present) {
      map['wpm'] = Variable<int>(wpm.value);
    }
    if (accuracyPercent.present) {
      map['accuracy_percent'] = Variable<int>(accuracyPercent.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TypingRecordsCompanion(')
          ..write('id: $id, ')
          ..write('wordsCount: $wordsCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('wpm: $wpm, ')
          ..write('accuracyPercent: $accuracyPercent, ')
          ..write('score: $score, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }
}

class $PhrasesTable extends Phrases with TableInfo<$PhrasesTable, PhraseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhrasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _phraseMeta = const VerificationMeta('phrase');
  @override
  late final GeneratedColumn<String> phrase = GeneratedColumn<String>(
    'phrase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    phrase,
    translation,
    category,
    level,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'phrases';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhraseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('phrase')) {
      context.handle(
        _phraseMeta,
        phrase.isAcceptableOrUnknown(data['phrase']!, _phraseMeta),
      );
    } else if (isInserting) {
      context.missing(_phraseMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhraseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhraseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      phrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phrase'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $PhrasesTable createAlias(String alias) {
    return $PhrasesTable(attachedDatabase, alias);
  }
}

class PhraseRow extends DataClass implements Insertable<PhraseRow> {
  /// Автоинкремент: контент только добавляется.
  final int id;

  /// Английская фраза.
  final String phrase;

  /// Русский перевод.
  final String translation;

  /// Тема: «Приветствия», «Аэропорт», «Идиомы».
  final String category;

  /// Уровень CEFR меткой: a1…c2.
  final String level;

  /// Момент загрузки, миллисекунды UTC.
  final int createdAtUtc;
  const PhraseRow({
    required this.id,
    required this.phrase,
    required this.translation,
    required this.category,
    required this.level,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['phrase'] = Variable<String>(phrase);
    map['translation'] = Variable<String>(translation);
    map['category'] = Variable<String>(category);
    map['level'] = Variable<String>(level);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    return map;
  }

  PhrasesCompanion toCompanion(bool nullToAbsent) {
    return PhrasesCompanion(
      id: Value(id),
      phrase: Value(phrase),
      translation: Value(translation),
      category: Value(category),
      level: Value(level),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory PhraseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhraseRow(
      id: serializer.fromJson<int>(json['id']),
      phrase: serializer.fromJson<String>(json['phrase']),
      translation: serializer.fromJson<String>(json['translation']),
      category: serializer.fromJson<String>(json['category']),
      level: serializer.fromJson<String>(json['level']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'phrase': serializer.toJson<String>(phrase),
      'translation': serializer.toJson<String>(translation),
      'category': serializer.toJson<String>(category),
      'level': serializer.toJson<String>(level),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
    };
  }

  PhraseRow copyWith({
    int? id,
    String? phrase,
    String? translation,
    String? category,
    String? level,
    int? createdAtUtc,
  }) => PhraseRow(
    id: id ?? this.id,
    phrase: phrase ?? this.phrase,
    translation: translation ?? this.translation,
    category: category ?? this.category,
    level: level ?? this.level,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  PhraseRow copyWithCompanion(PhrasesCompanion data) {
    return PhraseRow(
      id: data.id.present ? data.id.value : this.id,
      phrase: data.phrase.present ? data.phrase.value : this.phrase,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      category: data.category.present ? data.category.value : this.category,
      level: data.level.present ? data.level.value : this.level,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhraseRow(')
          ..write('id: $id, ')
          ..write('phrase: $phrase, ')
          ..write('translation: $translation, ')
          ..write('category: $category, ')
          ..write('level: $level, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, phrase, translation, category, level, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhraseRow &&
          other.id == this.id &&
          other.phrase == this.phrase &&
          other.translation == this.translation &&
          other.category == this.category &&
          other.level == this.level &&
          other.createdAtUtc == this.createdAtUtc);
}

class PhrasesCompanion extends UpdateCompanion<PhraseRow> {
  final Value<int> id;
  final Value<String> phrase;
  final Value<String> translation;
  final Value<String> category;
  final Value<String> level;
  final Value<int> createdAtUtc;
  const PhrasesCompanion({
    this.id = const Value.absent(),
    this.phrase = const Value.absent(),
    this.translation = const Value.absent(),
    this.category = const Value.absent(),
    this.level = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
  });
  PhrasesCompanion.insert({
    this.id = const Value.absent(),
    required String phrase,
    required String translation,
    required String category,
    required String level,
    required int createdAtUtc,
  }) : phrase = Value(phrase),
       translation = Value(translation),
       category = Value(category),
       level = Value(level),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<PhraseRow> custom({
    Expression<int>? id,
    Expression<String>? phrase,
    Expression<String>? translation,
    Expression<String>? category,
    Expression<String>? level,
    Expression<int>? createdAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phrase != null) 'phrase': phrase,
      if (translation != null) 'translation': translation,
      if (category != null) 'category': category,
      if (level != null) 'level': level,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
    });
  }

  PhrasesCompanion copyWith({
    Value<int>? id,
    Value<String>? phrase,
    Value<String>? translation,
    Value<String>? category,
    Value<String>? level,
    Value<int>? createdAtUtc,
  }) {
    return PhrasesCompanion(
      id: id ?? this.id,
      phrase: phrase ?? this.phrase,
      translation: translation ?? this.translation,
      category: category ?? this.category,
      level: level ?? this.level,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (phrase.present) {
      map['phrase'] = Variable<String>(phrase.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhrasesCompanion(')
          ..write('id: $id, ')
          ..write('phrase: $phrase, ')
          ..write('translation: $translation, ')
          ..write('category: $category, ')
          ..write('level: $level, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }
}

class $StoriesTable extends Stories with TableInfo<$StoriesTable, StoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<int> createdAtUtc = GeneratedColumn<int>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    translation,
    level,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['text']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class StoryRow extends DataClass implements Insertable<StoryRow> {
  /// Автоинкремент: контент только добавляется.
  final int id;

  /// Заголовок рассказа.
  final String title;

  /// Английский текст.
  ///
  /// Getter не может называться `text`: Dart запрещает одноимённые getter и
  /// унаследованный метод `Table.text()`. SQL-имя колонки остаётся `text`
  /// через `.named()`.
  final String content;

  /// Русский перевод.
  final String translation;

  /// Уровень CEFR меткой: a1…c1.
  final String level;

  /// Момент загрузки, миллисекунды UTC.
  final int createdAtUtc;
  const StoryRow({
    required this.id,
    required this.title,
    required this.content,
    required this.translation,
    required this.level,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['text'] = Variable<String>(content);
    map['translation'] = Variable<String>(translation);
    map['level'] = Variable<String>(level);
    map['created_at_utc'] = Variable<int>(createdAtUtc);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      id: Value(id),
      title: Value(title),
      content: Value(content),
      translation: Value(translation),
      level: Value(level),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory StoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      translation: serializer.fromJson<String>(json['translation']),
      level: serializer.fromJson<String>(json['level']),
      createdAtUtc: serializer.fromJson<int>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'content': serializer.toJson<String>(content),
      'translation': serializer.toJson<String>(translation),
      'level': serializer.toJson<String>(level),
      'createdAtUtc': serializer.toJson<int>(createdAtUtc),
    };
  }

  StoryRow copyWith({
    int? id,
    String? title,
    String? content,
    String? translation,
    String? level,
    int? createdAtUtc,
  }) => StoryRow(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    translation: translation ?? this.translation,
    level: level ?? this.level,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  StoryRow copyWithCompanion(StoriesCompanion data) {
    return StoryRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      level: data.level.present ? data.level.value : this.level,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('translation: $translation, ')
          ..write('level: $level, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, content, translation, level, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.translation == this.translation &&
          other.level == this.level &&
          other.createdAtUtc == this.createdAtUtc);
}

class StoriesCompanion extends UpdateCompanion<StoryRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> content;
  final Value<String> translation;
  final Value<String> level;
  final Value<int> createdAtUtc;
  const StoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.translation = const Value.absent(),
    this.level = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
  });
  StoriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String content,
    required String translation,
    required String level,
    required int createdAtUtc,
  }) : title = Value(title),
       content = Value(content),
       translation = Value(translation),
       level = Value(level),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<StoryRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? translation,
    Expression<String>? level,
    Expression<int>? createdAtUtc,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'text': content,
      if (translation != null) 'translation': translation,
      if (level != null) 'level': level,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
    });
  }

  StoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? content,
    Value<String>? translation,
    Value<String>? level,
    Value<int>? createdAtUtc,
  }) {
    return StoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      translation: translation ?? this.translation,
      level: level ?? this.level,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['text'] = Variable<String>(content.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<int>(createdAtUtc.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('translation: $translation, ')
          ..write('level: $level, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $WordProgressesTable wordProgresses = $WordProgressesTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $UserSettingsTableTable userSettingsTable =
      $UserSettingsTableTable(this);
  late final $DailyStatsTableTable dailyStatsTable = $DailyStatsTableTable(
    this,
  );
  late final $FrozenDaysTable frozenDays = $FrozenDaysTable(this);
  late final $WordHintsTable wordHints = $WordHintsTable(this);
  late final $ClozeTasksTable clozeTasks = $ClozeTasksTable(this);
  late final $DailyChallengesTable dailyChallenges = $DailyChallengesTable(
    this,
  );
  late final $ChallengeStreaksTable challengeStreaks = $ChallengeStreaksTable(
    this,
  );
  late final $UserCategoriesTable userCategories = $UserCategoriesTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $TypingRecordsTable typingRecords = $TypingRecordsTable(this);
  late final $PhrasesTable phrases = $PhrasesTable(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final Index idxWordsTerm = Index(
    'idx_words_term',
    'CREATE INDEX idx_words_term ON words (term)',
  );
  late final Index idxWordProgressDue = Index(
    'idx_word_progress_due',
    'CREATE INDEX idx_word_progress_due ON word_progresses (due_at_utc)',
  );
  late final Index idxWordProgressStatus = Index(
    'idx_word_progress_status',
    'CREATE INDEX idx_word_progress_status ON word_progresses (status)',
  );
  late final Index idxReviewLogsWord = Index(
    'idx_review_logs_word',
    'CREATE INDEX idx_review_logs_word ON review_logs (word_id)',
  );
  late final Index idxReviewLogsReviewed = Index(
    'idx_review_logs_reviewed',
    'CREATE INDEX idx_review_logs_reviewed ON review_logs (reviewed_at_utc)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    words,
    wordProgresses,
    reviewLogs,
    userSettingsTable,
    dailyStatsTable,
    frozenDays,
    wordHints,
    clozeTasks,
    dailyChallenges,
    challengeStreaks,
    userCategories,
    achievements,
    typingRecords,
    phrases,
    stories,
    idxWordsTerm,
    idxWordProgressDue,
    idxWordProgressStatus,
    idxReviewLogsWord,
    idxReviewLogsReviewed,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('word_progresses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('word_hints', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'words',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cloze_tasks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  required String term,
  required String translation,
  Value<String?> transcription,
  Value<String?> partOfSpeech,
  Value<String?> exampleSentence,
  Value<String?> category,
  Value<String> level,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  Value<String> term,
  Value<String> translation,
  Value<String?> transcription,
  Value<String?> partOfSpeech,
  Value<String?> exampleSentence,
  Value<String?> category,
  Value<String> level,
});

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WordProgressesTable, List<WordProgressRow>>
  _wordProgressesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordProgresses,
    aliasName: 'words__id__word_progresses__word_id',
  );

  $$WordProgressesTableProcessedTableManager get wordProgressesRefs {
    final manager = $$WordProgressesTableTableManager(
      $_db,
      $_db.wordProgresses,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordProgressesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WordHintsTable, List<WordHintRow>>
  _wordHintsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.wordHints,
    aliasName: 'words__id__word_hints__word_id',
  );

  $$WordHintsTableProcessedTableManager get wordHintsRefs {
    final manager = $$WordHintsTableTableManager(
      $_db,
      $_db.wordHints,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_wordHintsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ClozeTasksTable, List<ClozeTaskRow>>
  _clozeTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.clozeTasks,
    aliasName: 'words__id__cloze_tasks__word_id',
  );

  $$ClozeTasksTableProcessedTableManager get clozeTasksRefs {
    final manager = $$ClozeTasksTableTableManager(
      $_db,
      $_db.clozeTasks,
    ).filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_clozeTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordProgressesRefs(
    Expression<bool> Function($$WordProgressesTableFilterComposer f) f,
  ) {
    final $$WordProgressesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordProgresses,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordProgressesTableFilterComposer(
            $db: $db,
            $table: $db.wordProgresses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> wordHintsRefs(
    Expression<bool> Function($$WordHintsTableFilterComposer f) f,
  ) {
    final $$WordHintsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordHints,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordHintsTableFilterComposer(
            $db: $db,
            $table: $db.wordHints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> clozeTasksRefs(
    Expression<bool> Function($$ClozeTasksTableFilterComposer f) f,
  ) {
    final $$ClozeTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clozeTasks,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClozeTasksTableFilterComposer(
            $db: $db,
            $table: $db.clozeTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transcription => $composableBuilder(
    column: $table.transcription,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  Expression<T> wordProgressesRefs<T extends Object>(
    Expression<T> Function($$WordProgressesTableAnnotationComposer a) f,
  ) {
    final $$WordProgressesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordProgresses,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordProgressesTableAnnotationComposer(
            $db: $db,
            $table: $db.wordProgresses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> wordHintsRefs<T extends Object>(
    Expression<T> Function($$WordHintsTableAnnotationComposer a) f,
  ) {
    final $$WordHintsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.wordHints,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordHintsTableAnnotationComposer(
            $db: $db,
            $table: $db.wordHints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> clozeTasksRefs<T extends Object>(
    Expression<T> Function($$ClozeTasksTableAnnotationComposer a) f,
  ) {
    final $$ClozeTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clozeTasks,
      getReferencedColumn: (t) => t.wordId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClozeTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.clozeTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordsTable,
          Word,
          $$WordsTableFilterComposer,
          $$WordsTableOrderingComposer,
          $$WordsTableAnnotationComposer,
          $$WordsTableCreateCompanionBuilder,
          $$WordsTableUpdateCompanionBuilder,
          (Word, $$WordsTableReferences),
          Word,
          PrefetchHooks Function({
            bool wordProgressesRefs,
            bool wordHintsRefs,
            bool clozeTasksRefs,
          })
        > {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<String?> transcription = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> level = const Value.absent(),
              }) => WordsCompanion(
                id: id,
                term: term,
                translation: translation,
                transcription: transcription,
                partOfSpeech: partOfSpeech,
                exampleSentence: exampleSentence,
                category: category,
                level: level,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String term,
                required String translation,
                Value<String?> transcription = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> level = const Value.absent(),
              }) => WordsCompanion.insert(
                id: id,
                term: term,
                translation: translation,
                transcription: transcription,
                partOfSpeech: partOfSpeech,
                exampleSentence: exampleSentence,
                category: category,
                level: level,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordsTable, Word>(table),
                  $$WordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                wordProgressesRefs = false,
                wordHintsRefs = false,
                clozeTasksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (wordProgressesRefs) db.wordProgresses,
                    if (wordHintsRefs) db.wordHints,
                    if (clozeTasksRefs) db.clozeTasks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (wordProgressesRefs)
                        await $_getPrefetchedDataByColumns<
                          Word,
                          $WordsTable,
                          WordProgressRow,
                          $WordProgressesTable
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._wordProgressesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).wordProgressesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'word_id',
                          typedResults: items,
                        ),
                      if (wordHintsRefs)
                        await $_getPrefetchedDataByColumns<
                          Word,
                          $WordsTable,
                          WordHintRow,
                          $WordHintsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._wordHintsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).wordHintsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'word_id',
                          typedResults: items,
                        ),
                      if (clozeTasksRefs)
                        await $_getPrefetchedDataByColumns<
                          Word,
                          $WordsTable,
                          ClozeTaskRow,
                          $ClozeTasksTable
                        >(
                          currentTable: table,
                          referencedTable: $$WordsTableReferences
                              ._clozeTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WordsTableReferences(
                                db,
                                table,
                                p0,
                              ).clozeTasksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'word_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordsTable,
      Word,
      $$WordsTableFilterComposer,
      $$WordsTableOrderingComposer,
      $$WordsTableAnnotationComposer,
      $$WordsTableCreateCompanionBuilder,
      $$WordsTableUpdateCompanionBuilder,
      (Word, $$WordsTableReferences),
      Word,
      PrefetchHooks Function({
        bool wordProgressesRefs,
        bool wordHintsRefs,
        bool clozeTasksRefs,
      })
    >;
typedef $$WordProgressesTableCreateCompanionBuilder =
    WordProgressesCompanion Function({
      Value<int> wordId,
      required int easePermille,
      required int intervalDays,
      required int repetitions,
      required int lapses,
      required int dueAtUtc,
      required String status,
      required int firstSeenAtUtc,
      Value<int?> lastReviewedAtUtc,
    });
typedef $$WordProgressesTableUpdateCompanionBuilder =
    WordProgressesCompanion Function({
      Value<int> wordId,
      Value<int> easePermille,
      Value<int> intervalDays,
      Value<int> repetitions,
      Value<int> lapses,
      Value<int> dueAtUtc,
      Value<String> status,
      Value<int> firstSeenAtUtc,
      Value<int?> lastReviewedAtUtc,
    });

final class $$WordProgressesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WordProgressesTable, WordProgressRow> {
  $$WordProgressesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_progresses__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordProgressesTableFilterComposer
    extends Composer<_$AppDatabase, $WordProgressesTable> {
  $$WordProgressesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get easePermille => $composableBuilder(
    column: $table.easePermille,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueAtUtc => $composableBuilder(
    column: $table.dueAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstSeenAtUtc => $composableBuilder(
    column: $table.firstSeenAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewedAtUtc => $composableBuilder(
    column: $table.lastReviewedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordProgressesTable> {
  $$WordProgressesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get easePermille => $composableBuilder(
    column: $table.easePermille,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueAtUtc => $composableBuilder(
    column: $table.dueAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstSeenAtUtc => $composableBuilder(
    column: $table.firstSeenAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedAtUtc => $composableBuilder(
    column: $table.lastReviewedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordProgressesTable> {
  $$WordProgressesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get easePermille => $composableBuilder(
    column: $table.easePermille,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get dueAtUtc =>
      $composableBuilder(column: $table.dueAtUtc, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get firstSeenAtUtc => $composableBuilder(
    column: $table.firstSeenAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastReviewedAtUtc => $composableBuilder(
    column: $table.lastReviewedAtUtc,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordProgressesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordProgressesTable,
          WordProgressRow,
          $$WordProgressesTableFilterComposer,
          $$WordProgressesTableOrderingComposer,
          $$WordProgressesTableAnnotationComposer,
          $$WordProgressesTableCreateCompanionBuilder,
          $$WordProgressesTableUpdateCompanionBuilder,
          (WordProgressRow, $$WordProgressesTableReferences),
          WordProgressRow,
          PrefetchHooks Function({bool wordId})
        > {
  $$WordProgressesTableTableManager(
    _$AppDatabase db,
    $WordProgressesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordProgressesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordProgressesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordProgressesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<int> easePermille = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> dueAtUtc = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> firstSeenAtUtc = const Value.absent(),
                Value<int?> lastReviewedAtUtc = const Value.absent(),
              }) => WordProgressesCompanion(
                wordId: wordId,
                easePermille: easePermille,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAtUtc: dueAtUtc,
                status: status,
                firstSeenAtUtc: firstSeenAtUtc,
                lastReviewedAtUtc: lastReviewedAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                required int easePermille,
                required int intervalDays,
                required int repetitions,
                required int lapses,
                required int dueAtUtc,
                required String status,
                required int firstSeenAtUtc,
                Value<int?> lastReviewedAtUtc = const Value.absent(),
              }) => WordProgressesCompanion.insert(
                wordId: wordId,
                easePermille: easePermille,
                intervalDays: intervalDays,
                repetitions: repetitions,
                lapses: lapses,
                dueAtUtc: dueAtUtc,
                status: status,
                firstSeenAtUtc: firstSeenAtUtc,
                lastReviewedAtUtc: lastReviewedAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordProgressesTable, WordProgressRow>(table),
                  $$WordProgressesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$WordProgressesTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$WordProgressesTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordProgressesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordProgressesTable,
      WordProgressRow,
      $$WordProgressesTableFilterComposer,
      $$WordProgressesTableOrderingComposer,
      $$WordProgressesTableAnnotationComposer,
      $$WordProgressesTableCreateCompanionBuilder,
      $$WordProgressesTableUpdateCompanionBuilder,
      (WordProgressRow, $$WordProgressesTableReferences),
      WordProgressRow,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  required int wordId,
  required int reviewedAtUtc,
  required String grade,
  required int prevEasePermille,
  required int prevIntervalDays,
  required int prevRepetitions,
  required int prevLapses,
  required int prevDueAtUtc,
  required int newEasePermille,
  required int newIntervalDays,
  required int newRepetitions,
  required int newLapses,
  required int newDueAtUtc,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<int> id,
  Value<int> wordId,
  Value<int> reviewedAtUtc,
  Value<String> grade,
  Value<int> prevEasePermille,
  Value<int> prevIntervalDays,
  Value<int> prevRepetitions,
  Value<int> prevLapses,
  Value<int> prevDueAtUtc,
  Value<int> newEasePermille,
  Value<int> newIntervalDays,
  Value<int> newRepetitions,
  Value<int> newLapses,
  Value<int> newDueAtUtc,
});

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewedAtUtc => $composableBuilder(
    column: $table.reviewedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prevEasePermille => $composableBuilder(
    column: $table.prevEasePermille,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prevIntervalDays => $composableBuilder(
    column: $table.prevIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prevRepetitions => $composableBuilder(
    column: $table.prevRepetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prevLapses => $composableBuilder(
    column: $table.prevLapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prevDueAtUtc => $composableBuilder(
    column: $table.prevDueAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newEasePermille => $composableBuilder(
    column: $table.newEasePermille,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newIntervalDays => $composableBuilder(
    column: $table.newIntervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newRepetitions => $composableBuilder(
    column: $table.newRepetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newLapses => $composableBuilder(
    column: $table.newLapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newDueAtUtc => $composableBuilder(
    column: $table.newDueAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordId => $composableBuilder(
    column: $table.wordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewedAtUtc => $composableBuilder(
    column: $table.reviewedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prevEasePermille => $composableBuilder(
    column: $table.prevEasePermille,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prevIntervalDays => $composableBuilder(
    column: $table.prevIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prevRepetitions => $composableBuilder(
    column: $table.prevRepetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prevLapses => $composableBuilder(
    column: $table.prevLapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prevDueAtUtc => $composableBuilder(
    column: $table.prevDueAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newEasePermille => $composableBuilder(
    column: $table.newEasePermille,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newIntervalDays => $composableBuilder(
    column: $table.newIntervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newRepetitions => $composableBuilder(
    column: $table.newRepetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newLapses => $composableBuilder(
    column: $table.newLapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newDueAtUtc => $composableBuilder(
    column: $table.newDueAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<int> get reviewedAtUtc => $composableBuilder(
    column: $table.reviewedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<int> get prevEasePermille => $composableBuilder(
    column: $table.prevEasePermille,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prevIntervalDays => $composableBuilder(
    column: $table.prevIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prevRepetitions => $composableBuilder(
    column: $table.prevRepetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prevLapses => $composableBuilder(
    column: $table.prevLapses,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prevDueAtUtc => $composableBuilder(
    column: $table.prevDueAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newEasePermille => $composableBuilder(
    column: $table.newEasePermille,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newIntervalDays => $composableBuilder(
    column: $table.newIntervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newRepetitions => $composableBuilder(
    column: $table.newRepetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newLapses =>
      $composableBuilder(column: $table.newLapses, builder: (column) => column);

  GeneratedColumn<int> get newDueAtUtc => $composableBuilder(
    column: $table.newDueAtUtc,
    builder: (column) => column,
  );
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLogRow,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (
            ReviewLogRow,
            BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLogRow>,
          ),
          ReviewLogRow,
          PrefetchHooks Function()
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<int> reviewedAtUtc = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<int> prevEasePermille = const Value.absent(),
                Value<int> prevIntervalDays = const Value.absent(),
                Value<int> prevRepetitions = const Value.absent(),
                Value<int> prevLapses = const Value.absent(),
                Value<int> prevDueAtUtc = const Value.absent(),
                Value<int> newEasePermille = const Value.absent(),
                Value<int> newIntervalDays = const Value.absent(),
                Value<int> newRepetitions = const Value.absent(),
                Value<int> newLapses = const Value.absent(),
                Value<int> newDueAtUtc = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                wordId: wordId,
                reviewedAtUtc: reviewedAtUtc,
                grade: grade,
                prevEasePermille: prevEasePermille,
                prevIntervalDays: prevIntervalDays,
                prevRepetitions: prevRepetitions,
                prevLapses: prevLapses,
                prevDueAtUtc: prevDueAtUtc,
                newEasePermille: newEasePermille,
                newIntervalDays: newIntervalDays,
                newRepetitions: newRepetitions,
                newLapses: newLapses,
                newDueAtUtc: newDueAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordId,
                required int reviewedAtUtc,
                required String grade,
                required int prevEasePermille,
                required int prevIntervalDays,
                required int prevRepetitions,
                required int prevLapses,
                required int prevDueAtUtc,
                required int newEasePermille,
                required int newIntervalDays,
                required int newRepetitions,
                required int newLapses,
                required int newDueAtUtc,
              }) => ReviewLogsCompanion.insert(
                id: id,
                wordId: wordId,
                reviewedAtUtc: reviewedAtUtc,
                grade: grade,
                prevEasePermille: prevEasePermille,
                prevIntervalDays: prevIntervalDays,
                prevRepetitions: prevRepetitions,
                prevLapses: prevLapses,
                prevDueAtUtc: prevDueAtUtc,
                newEasePermille: newEasePermille,
                newIntervalDays: newIntervalDays,
                newRepetitions: newRepetitions,
                newLapses: newLapses,
                newDueAtUtc: newDueAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewLogsTable, ReviewLogRow>(table),
                  BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLogRow,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (
        ReviewLogRow,
        BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLogRow>,
      ),
      ReviewLogRow,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableTableCreateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<int> dailyNewLimit,
      Value<int> dailyReviewLimit,
      Value<bool> remindersEnabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<String> ttsVoice,
      Value<double> ttsSpeed,
      Value<bool> hasSeenOnboarding,
      Value<String> preferredLevel,
      required int updatedAtUtc,
    });
typedef $$UserSettingsTableTableUpdateCompanionBuilder =
    UserSettingsTableCompanion Function({
      Value<int> id,
      Value<int> dailyNewLimit,
      Value<int> dailyReviewLimit,
      Value<bool> remindersEnabled,
      Value<int> reminderHour,
      Value<int> reminderMinute,
      Value<String> ttsVoice,
      Value<double> ttsSpeed,
      Value<bool> hasSeenOnboarding,
      Value<String> preferredLevel,
      Value<int> updatedAtUtc,
    });

class $$UserSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyNewLimit => $composableBuilder(
    column: $table.dailyNewLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyReviewLimit => $composableBuilder(
    column: $table.dailyReviewLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsVoice => $composableBuilder(
    column: $table.ttsVoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ttsSpeed => $composableBuilder(
    column: $table.ttsSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasSeenOnboarding => $composableBuilder(
    column: $table.hasSeenOnboarding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredLevel => $composableBuilder(
    column: $table.preferredLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyNewLimit => $composableBuilder(
    column: $table.dailyNewLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyReviewLimit => $composableBuilder(
    column: $table.dailyReviewLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsVoice => $composableBuilder(
    column: $table.ttsVoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ttsSpeed => $composableBuilder(
    column: $table.ttsSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasSeenOnboarding => $composableBuilder(
    column: $table.hasSeenOnboarding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredLevel => $composableBuilder(
    column: $table.preferredLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTableTable> {
  $$UserSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dailyNewLimit => $composableBuilder(
    column: $table.dailyNewLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyReviewLimit => $composableBuilder(
    column: $table.dailyReviewLimit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remindersEnabled => $composableBuilder(
    column: $table.remindersEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ttsVoice =>
      $composableBuilder(column: $table.ttsVoice, builder: (column) => column);

  GeneratedColumn<double> get ttsSpeed =>
      $composableBuilder(column: $table.ttsSpeed, builder: (column) => column);

  GeneratedColumn<bool> get hasSeenOnboarding => $composableBuilder(
    column: $table.hasSeenOnboarding,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredLevel => $composableBuilder(
    column: $table.preferredLevel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$UserSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTableTable,
          UserSettingsRow,
          $$UserSettingsTableTableFilterComposer,
          $$UserSettingsTableTableOrderingComposer,
          $$UserSettingsTableTableAnnotationComposer,
          $$UserSettingsTableTableCreateCompanionBuilder,
          $$UserSettingsTableTableUpdateCompanionBuilder,
          (
            UserSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $UserSettingsTableTable,
              UserSettingsRow
            >,
          ),
          UserSettingsRow,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableTableManager(
    _$AppDatabase db,
    $UserSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dailyNewLimit = const Value.absent(),
                Value<int> dailyReviewLimit = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<String> ttsVoice = const Value.absent(),
                Value<double> ttsSpeed = const Value.absent(),
                Value<bool> hasSeenOnboarding = const Value.absent(),
                Value<String> preferredLevel = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
              }) => UserSettingsTableCompanion(
                id: id,
                dailyNewLimit: dailyNewLimit,
                dailyReviewLimit: dailyReviewLimit,
                remindersEnabled: remindersEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                ttsVoice: ttsVoice,
                ttsSpeed: ttsSpeed,
                hasSeenOnboarding: hasSeenOnboarding,
                preferredLevel: preferredLevel,
                updatedAtUtc: updatedAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dailyNewLimit = const Value.absent(),
                Value<int> dailyReviewLimit = const Value.absent(),
                Value<bool> remindersEnabled = const Value.absent(),
                Value<int> reminderHour = const Value.absent(),
                Value<int> reminderMinute = const Value.absent(),
                Value<String> ttsVoice = const Value.absent(),
                Value<double> ttsSpeed = const Value.absent(),
                Value<bool> hasSeenOnboarding = const Value.absent(),
                Value<String> preferredLevel = const Value.absent(),
                required int updatedAtUtc,
              }) => UserSettingsTableCompanion.insert(
                id: id,
                dailyNewLimit: dailyNewLimit,
                dailyReviewLimit: dailyReviewLimit,
                remindersEnabled: remindersEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                ttsVoice: ttsVoice,
                ttsSpeed: ttsSpeed,
                hasSeenOnboarding: hasSeenOnboarding,
                preferredLevel: preferredLevel,
                updatedAtUtc: updatedAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserSettingsTableTable, UserSettingsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserSettingsTableTable,
                    UserSettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTableTable,
      UserSettingsRow,
      $$UserSettingsTableTableFilterComposer,
      $$UserSettingsTableTableOrderingComposer,
      $$UserSettingsTableTableAnnotationComposer,
      $$UserSettingsTableTableCreateCompanionBuilder,
      $$UserSettingsTableTableUpdateCompanionBuilder,
      (
        UserSettingsRow,
        BaseReferences<_$AppDatabase, $UserSettingsTableTable, UserSettingsRow>,
      ),
      UserSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$DailyStatsTableTableCreateCompanionBuilder =
    DailyStatsTableCompanion Function({
      Value<int> dateEpochDays,
      Value<int> newWordsStudied,
      Value<int> reviewsCompleted,
      Value<int> xpGained,
      Value<int> correctAnswers,
    });
typedef $$DailyStatsTableTableUpdateCompanionBuilder =
    DailyStatsTableCompanion Function({
      Value<int> dateEpochDays,
      Value<int> newWordsStudied,
      Value<int> reviewsCompleted,
      Value<int> xpGained,
      Value<int> correctAnswers,
    });

class $$DailyStatsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DailyStatsTableTable> {
  $$DailyStatsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newWordsStudied => $composableBuilder(
    column: $table.newWordsStudied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewsCompleted => $composableBuilder(
    column: $table.reviewsCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyStatsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyStatsTableTable> {
  $$DailyStatsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newWordsStudied => $composableBuilder(
    column: $table.newWordsStudied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewsCompleted => $composableBuilder(
    column: $table.reviewsCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyStatsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyStatsTableTable> {
  $$DailyStatsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newWordsStudied => $composableBuilder(
    column: $table.newWordsStudied,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewsCompleted => $composableBuilder(
    column: $table.reviewsCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpGained =>
      $composableBuilder(column: $table.xpGained, builder: (column) => column);

  GeneratedColumn<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => column,
  );
}

class $$DailyStatsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyStatsTableTable,
          DailyStatsRow,
          $$DailyStatsTableTableFilterComposer,
          $$DailyStatsTableTableOrderingComposer,
          $$DailyStatsTableTableAnnotationComposer,
          $$DailyStatsTableTableCreateCompanionBuilder,
          $$DailyStatsTableTableUpdateCompanionBuilder,
          (
            DailyStatsRow,
            BaseReferences<_$AppDatabase, $DailyStatsTableTable, DailyStatsRow>,
          ),
          DailyStatsRow,
          PrefetchHooks Function()
        > {
  $$DailyStatsTableTableTableManager(
    _$AppDatabase db,
    $DailyStatsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyStatsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyStatsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyStatsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> dateEpochDays = const Value.absent(),
                Value<int> newWordsStudied = const Value.absent(),
                Value<int> reviewsCompleted = const Value.absent(),
                Value<int> xpGained = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
              }) => DailyStatsTableCompanion(
                dateEpochDays: dateEpochDays,
                newWordsStudied: newWordsStudied,
                reviewsCompleted: reviewsCompleted,
                xpGained: xpGained,
                correctAnswers: correctAnswers,
              ),
          createCompanionCallback:
              ({
                Value<int> dateEpochDays = const Value.absent(),
                Value<int> newWordsStudied = const Value.absent(),
                Value<int> reviewsCompleted = const Value.absent(),
                Value<int> xpGained = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
              }) => DailyStatsTableCompanion.insert(
                dateEpochDays: dateEpochDays,
                newWordsStudied: newWordsStudied,
                reviewsCompleted: reviewsCompleted,
                xpGained: xpGained,
                correctAnswers: correctAnswers,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyStatsTableTable, DailyStatsRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyStatsTableTable,
                    DailyStatsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStatsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyStatsTableTable,
      DailyStatsRow,
      $$DailyStatsTableTableFilterComposer,
      $$DailyStatsTableTableOrderingComposer,
      $$DailyStatsTableTableAnnotationComposer,
      $$DailyStatsTableTableCreateCompanionBuilder,
      $$DailyStatsTableTableUpdateCompanionBuilder,
      (
        DailyStatsRow,
        BaseReferences<_$AppDatabase, $DailyStatsTableTable, DailyStatsRow>,
      ),
      DailyStatsRow,
      PrefetchHooks Function()
    >;
typedef $$FrozenDaysTableCreateCompanionBuilder = FrozenDaysCompanion Function({
  Value<int> dateEpochDays,
  required int consumedAtUtc,
  required String reason,
});
typedef $$FrozenDaysTableUpdateCompanionBuilder = FrozenDaysCompanion Function({
  Value<int> dateEpochDays,
  Value<int> consumedAtUtc,
  Value<String> reason,
});

class $$FrozenDaysTableFilterComposer
    extends Composer<_$AppDatabase, $FrozenDaysTable> {
  $$FrozenDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consumedAtUtc => $composableBuilder(
    column: $table.consumedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FrozenDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $FrozenDaysTable> {
  $$FrozenDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consumedAtUtc => $composableBuilder(
    column: $table.consumedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FrozenDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $FrozenDaysTable> {
  $$FrozenDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consumedAtUtc => $composableBuilder(
    column: $table.consumedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);
}

class $$FrozenDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FrozenDaysTable,
          FrozenDayRow,
          $$FrozenDaysTableFilterComposer,
          $$FrozenDaysTableOrderingComposer,
          $$FrozenDaysTableAnnotationComposer,
          $$FrozenDaysTableCreateCompanionBuilder,
          $$FrozenDaysTableUpdateCompanionBuilder,
          (
            FrozenDayRow,
            BaseReferences<_$AppDatabase, $FrozenDaysTable, FrozenDayRow>,
          ),
          FrozenDayRow,
          PrefetchHooks Function()
        > {
  $$FrozenDaysTableTableManager(_$AppDatabase db, $FrozenDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FrozenDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FrozenDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FrozenDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> dateEpochDays = const Value.absent(),
                Value<int> consumedAtUtc = const Value.absent(),
                Value<String> reason = const Value.absent(),
              }) => FrozenDaysCompanion(
                dateEpochDays: dateEpochDays,
                consumedAtUtc: consumedAtUtc,
                reason: reason,
              ),
          createCompanionCallback:
              ({
                Value<int> dateEpochDays = const Value.absent(),
                required int consumedAtUtc,
                required String reason,
              }) => FrozenDaysCompanion.insert(
                dateEpochDays: dateEpochDays,
                consumedAtUtc: consumedAtUtc,
                reason: reason,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FrozenDaysTable, FrozenDayRow>(table),
                  BaseReferences<_$AppDatabase, $FrozenDaysTable, FrozenDayRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FrozenDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FrozenDaysTable,
      FrozenDayRow,
      $$FrozenDaysTableFilterComposer,
      $$FrozenDaysTableOrderingComposer,
      $$FrozenDaysTableAnnotationComposer,
      $$FrozenDaysTableCreateCompanionBuilder,
      $$FrozenDaysTableUpdateCompanionBuilder,
      (
        FrozenDayRow,
        BaseReferences<_$AppDatabase, $FrozenDaysTable, FrozenDayRow>,
      ),
      FrozenDayRow,
      PrefetchHooks Function()
    >;
typedef $$WordHintsTableCreateCompanionBuilder = WordHintsCompanion Function({
  Value<int> wordId,
  required String term,
  required String hintText,
  required int createdAtUtc,
});
typedef $$WordHintsTableUpdateCompanionBuilder = WordHintsCompanion Function({
  Value<int> wordId,
  Value<String> term,
  Value<String> hintText,
  Value<int> createdAtUtc,
});

final class $$WordHintsTableReferences
    extends BaseReferences<_$AppDatabase, $WordHintsTable, WordHintRow> {
  $$WordHintsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('word_hints__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordHintsTableFilterComposer
    extends Composer<_$AppDatabase, $WordHintsTable> {
  $$WordHintsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hintText => $composableBuilder(
    column: $table.hintText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordHintsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordHintsTable> {
  $$WordHintsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get term => $composableBuilder(
    column: $table.term,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hintText => $composableBuilder(
    column: $table.hintText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordHintsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordHintsTable> {
  $$WordHintsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get term =>
      $composableBuilder(column: $table.term, builder: (column) => column);

  GeneratedColumn<String> get hintText =>
      $composableBuilder(column: $table.hintText, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordHintsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordHintsTable,
          WordHintRow,
          $$WordHintsTableFilterComposer,
          $$WordHintsTableOrderingComposer,
          $$WordHintsTableAnnotationComposer,
          $$WordHintsTableCreateCompanionBuilder,
          $$WordHintsTableUpdateCompanionBuilder,
          (WordHintRow, $$WordHintsTableReferences),
          WordHintRow,
          PrefetchHooks Function({bool wordId})
        > {
  $$WordHintsTableTableManager(_$AppDatabase db, $WordHintsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordHintsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordHintsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordHintsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<String> term = const Value.absent(),
                Value<String> hintText = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
              }) => WordHintsCompanion(
                wordId: wordId,
                term: term,
                hintText: hintText,
                createdAtUtc: createdAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                required String term,
                required String hintText,
                required int createdAtUtc,
              }) => WordHintsCompanion.insert(
                wordId: wordId,
                term: term,
                hintText: hintText,
                createdAtUtc: createdAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WordHintsTable, WordHintRow>(table),
                  $$WordHintsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$WordHintsTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$WordHintsTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordHintsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordHintsTable,
      WordHintRow,
      $$WordHintsTableFilterComposer,
      $$WordHintsTableOrderingComposer,
      $$WordHintsTableAnnotationComposer,
      $$WordHintsTableCreateCompanionBuilder,
      $$WordHintsTableUpdateCompanionBuilder,
      (WordHintRow, $$WordHintsTableReferences),
      WordHintRow,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$ClozeTasksTableCreateCompanionBuilder = ClozeTasksCompanion Function({
  Value<int> wordId,
  required String sentence,
  required String answer,
  required int createdAtUtc,
});
typedef $$ClozeTasksTableUpdateCompanionBuilder = ClozeTasksCompanion Function({
  Value<int> wordId,
  Value<String> sentence,
  Value<String> answer,
  Value<int> createdAtUtc,
});

final class $$ClozeTasksTableReferences
    extends BaseReferences<_$AppDatabase, $ClozeTasksTable, ClozeTaskRow> {
  $$ClozeTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) =>
      db.words.createAlias('cloze_tasks__word_id__words__id');

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager(
      $_db,
      $_db.words,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClozeTasksTableFilterComposer
    extends Composer<_$AppDatabase, $ClozeTasksTable> {
  $$ClozeTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableFilterComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClozeTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $ClozeTasksTable> {
  $$ClozeTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableOrderingComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClozeTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClozeTasksTable> {
  $$ClozeTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sentence =>
      $composableBuilder(column: $table.sentence, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.wordId,
      referencedTable: $db.words,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordsTableAnnotationComposer(
            $db: $db,
            $table: $db.words,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClozeTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClozeTasksTable,
          ClozeTaskRow,
          $$ClozeTasksTableFilterComposer,
          $$ClozeTasksTableOrderingComposer,
          $$ClozeTasksTableAnnotationComposer,
          $$ClozeTasksTableCreateCompanionBuilder,
          $$ClozeTasksTableUpdateCompanionBuilder,
          (ClozeTaskRow, $$ClozeTasksTableReferences),
          ClozeTaskRow,
          PrefetchHooks Function({bool wordId})
        > {
  $$ClozeTasksTableTableManager(_$AppDatabase db, $ClozeTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClozeTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClozeTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClozeTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                Value<String> sentence = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
              }) => ClozeTasksCompanion(
                wordId: wordId,
                sentence: sentence,
                answer: answer,
                createdAtUtc: createdAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> wordId = const Value.absent(),
                required String sentence,
                required String answer,
                required int createdAtUtc,
              }) => ClozeTasksCompanion.insert(
                wordId: wordId,
                sentence: sentence,
                answer: answer,
                createdAtUtc: createdAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClozeTasksTable, ClozeTaskRow>(table),
                  $$ClozeTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (wordId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.wordId,
                        referencedTable: $$ClozeTasksTableReferences
                            ._wordIdTable(db),
                        referencedColumn: $$ClozeTasksTableReferences
                            ._wordIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ClozeTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClozeTasksTable,
      ClozeTaskRow,
      $$ClozeTasksTableFilterComposer,
      $$ClozeTasksTableOrderingComposer,
      $$ClozeTasksTableAnnotationComposer,
      $$ClozeTasksTableCreateCompanionBuilder,
      $$ClozeTasksTableUpdateCompanionBuilder,
      (ClozeTaskRow, $$ClozeTasksTableReferences),
      ClozeTaskRow,
      PrefetchHooks Function({bool wordId})
    >;
typedef $$DailyChallengesTableCreateCompanionBuilder =
    DailyChallengesCompanion Function({
      Value<int> dateEpochDays,
      required String goalType,
      required int goalValue,
      Value<int> progress,
      Value<int?> completedAtUtc,
      Value<int?> claimedAtUtc,
      required int xpReward,
    });
typedef $$DailyChallengesTableUpdateCompanionBuilder =
    DailyChallengesCompanion Function({
      Value<int> dateEpochDays,
      Value<String> goalType,
      Value<int> goalValue,
      Value<int> progress,
      Value<int?> completedAtUtc,
      Value<int?> claimedAtUtc,
      Value<int> xpReward,
    });

class $$DailyChallengesTableFilterComposer
    extends Composer<_$AppDatabase, $DailyChallengesTable> {
  $$DailyChallengesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalValue => $composableBuilder(
    column: $table.goalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get claimedAtUtc => $composableBuilder(
    column: $table.claimedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyChallengesTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyChallengesTable> {
  $$DailyChallengesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalType => $composableBuilder(
    column: $table.goalType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalValue => $composableBuilder(
    column: $table.goalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get claimedAtUtc => $composableBuilder(
    column: $table.claimedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyChallengesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyChallengesTable> {
  $$DailyChallengesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dateEpochDays => $composableBuilder(
    column: $table.dateEpochDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get goalType =>
      $composableBuilder(column: $table.goalType, builder: (column) => column);

  GeneratedColumn<int> get goalValue =>
      $composableBuilder(column: $table.goalValue, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get claimedAtUtc => $composableBuilder(
    column: $table.claimedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);
}

class $$DailyChallengesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyChallengesTable,
          DailyChallengeRow,
          $$DailyChallengesTableFilterComposer,
          $$DailyChallengesTableOrderingComposer,
          $$DailyChallengesTableAnnotationComposer,
          $$DailyChallengesTableCreateCompanionBuilder,
          $$DailyChallengesTableUpdateCompanionBuilder,
          (
            DailyChallengeRow,
            BaseReferences<
              _$AppDatabase,
              $DailyChallengesTable,
              DailyChallengeRow
            >,
          ),
          DailyChallengeRow,
          PrefetchHooks Function()
        > {
  $$DailyChallengesTableTableManager(
    _$AppDatabase db,
    $DailyChallengesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyChallengesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyChallengesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyChallengesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> dateEpochDays = const Value.absent(),
                Value<String> goalType = const Value.absent(),
                Value<int> goalValue = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<int?> completedAtUtc = const Value.absent(),
                Value<int?> claimedAtUtc = const Value.absent(),
                Value<int> xpReward = const Value.absent(),
              }) => DailyChallengesCompanion(
                dateEpochDays: dateEpochDays,
                goalType: goalType,
                goalValue: goalValue,
                progress: progress,
                completedAtUtc: completedAtUtc,
                claimedAtUtc: claimedAtUtc,
                xpReward: xpReward,
              ),
          createCompanionCallback:
              ({
                Value<int> dateEpochDays = const Value.absent(),
                required String goalType,
                required int goalValue,
                Value<int> progress = const Value.absent(),
                Value<int?> completedAtUtc = const Value.absent(),
                Value<int?> claimedAtUtc = const Value.absent(),
                required int xpReward,
              }) => DailyChallengesCompanion.insert(
                dateEpochDays: dateEpochDays,
                goalType: goalType,
                goalValue: goalValue,
                progress: progress,
                completedAtUtc: completedAtUtc,
                claimedAtUtc: claimedAtUtc,
                xpReward: xpReward,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyChallengesTable, DailyChallengeRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyChallengesTable,
                    DailyChallengeRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyChallengesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyChallengesTable,
      DailyChallengeRow,
      $$DailyChallengesTableFilterComposer,
      $$DailyChallengesTableOrderingComposer,
      $$DailyChallengesTableAnnotationComposer,
      $$DailyChallengesTableCreateCompanionBuilder,
      $$DailyChallengesTableUpdateCompanionBuilder,
      (
        DailyChallengeRow,
        BaseReferences<_$AppDatabase, $DailyChallengesTable, DailyChallengeRow>,
      ),
      DailyChallengeRow,
      PrefetchHooks Function()
    >;
typedef $$ChallengeStreaksTableCreateCompanionBuilder =
    ChallengeStreaksCompanion Function({
      Value<int> id,
      Value<int> currentStreak,
      Value<int> bestStreak,
      Value<int?> lastCompletedDateEpochDays,
      required int updatedAtUtc,
    });
typedef $$ChallengeStreaksTableUpdateCompanionBuilder =
    ChallengeStreaksCompanion Function({
      Value<int> id,
      Value<int> currentStreak,
      Value<int> bestStreak,
      Value<int?> lastCompletedDateEpochDays,
      Value<int> updatedAtUtc,
    });

class $$ChallengeStreaksTableFilterComposer
    extends Composer<_$AppDatabase, $ChallengeStreaksTable> {
  $$ChallengeStreaksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCompletedDateEpochDays => $composableBuilder(
    column: $table.lastCompletedDateEpochDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChallengeStreaksTableOrderingComposer
    extends Composer<_$AppDatabase, $ChallengeStreaksTable> {
  $$ChallengeStreaksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCompletedDateEpochDays => $composableBuilder(
    column: $table.lastCompletedDateEpochDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChallengeStreaksTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChallengeStreaksTable> {
  $$ChallengeStreaksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bestStreak => $composableBuilder(
    column: $table.bestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastCompletedDateEpochDays => $composableBuilder(
    column: $table.lastCompletedDateEpochDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$ChallengeStreaksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChallengeStreaksTable,
          ChallengeStreakRow,
          $$ChallengeStreaksTableFilterComposer,
          $$ChallengeStreaksTableOrderingComposer,
          $$ChallengeStreaksTableAnnotationComposer,
          $$ChallengeStreaksTableCreateCompanionBuilder,
          $$ChallengeStreaksTableUpdateCompanionBuilder,
          (
            ChallengeStreakRow,
            BaseReferences<
              _$AppDatabase,
              $ChallengeStreaksTable,
              ChallengeStreakRow
            >,
          ),
          ChallengeStreakRow,
          PrefetchHooks Function()
        > {
  $$ChallengeStreaksTableTableManager(
    _$AppDatabase db,
    $ChallengeStreaksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChallengeStreaksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChallengeStreaksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChallengeStreaksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> bestStreak = const Value.absent(),
                Value<int?> lastCompletedDateEpochDays = const Value.absent(),
                Value<int> updatedAtUtc = const Value.absent(),
              }) => ChallengeStreaksCompanion(
                id: id,
                currentStreak: currentStreak,
                bestStreak: bestStreak,
                lastCompletedDateEpochDays: lastCompletedDateEpochDays,
                updatedAtUtc: updatedAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> bestStreak = const Value.absent(),
                Value<int?> lastCompletedDateEpochDays = const Value.absent(),
                required int updatedAtUtc,
              }) => ChallengeStreaksCompanion.insert(
                id: id,
                currentStreak: currentStreak,
                bestStreak: bestStreak,
                lastCompletedDateEpochDays: lastCompletedDateEpochDays,
                updatedAtUtc: updatedAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChallengeStreaksTable, ChallengeStreakRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ChallengeStreaksTable,
                    ChallengeStreakRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChallengeStreaksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChallengeStreaksTable,
      ChallengeStreakRow,
      $$ChallengeStreaksTableFilterComposer,
      $$ChallengeStreaksTableOrderingComposer,
      $$ChallengeStreaksTableAnnotationComposer,
      $$ChallengeStreaksTableCreateCompanionBuilder,
      $$ChallengeStreaksTableUpdateCompanionBuilder,
      (
        ChallengeStreakRow,
        BaseReferences<
          _$AppDatabase,
          $ChallengeStreaksTable,
          ChallengeStreakRow
        >,
      ),
      ChallengeStreakRow,
      PrefetchHooks Function()
    >;
typedef $$UserCategoriesTableCreateCompanionBuilder =
    UserCategoriesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> colorHex,
      required int createdAtUtc,
    });
typedef $$UserCategoriesTableUpdateCompanionBuilder =
    UserCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> colorHex,
      Value<int> createdAtUtc,
    });

class $$UserCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $UserCategoriesTable> {
  $$UserCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserCategoriesTable> {
  $$UserCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserCategoriesTable> {
  $$UserCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );
}

class $$UserCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserCategoriesTable,
          UserCategoryRow,
          $$UserCategoriesTableFilterComposer,
          $$UserCategoriesTableOrderingComposer,
          $$UserCategoriesTableAnnotationComposer,
          $$UserCategoriesTableCreateCompanionBuilder,
          $$UserCategoriesTableUpdateCompanionBuilder,
          (
            UserCategoryRow,
            BaseReferences<
              _$AppDatabase,
              $UserCategoriesTable,
              UserCategoryRow
            >,
          ),
          UserCategoryRow,
          PrefetchHooks Function()
        > {
  $$UserCategoriesTableTableManager(
    _$AppDatabase db,
    $UserCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
              }) => UserCategoriesCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                createdAtUtc: createdAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> colorHex = const Value.absent(),
                required int createdAtUtc,
              }) => UserCategoriesCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                createdAtUtc: createdAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserCategoriesTable, UserCategoryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserCategoriesTable,
                    UserCategoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserCategoriesTable,
      UserCategoryRow,
      $$UserCategoriesTableFilterComposer,
      $$UserCategoriesTableOrderingComposer,
      $$UserCategoriesTableAnnotationComposer,
      $$UserCategoriesTableCreateCompanionBuilder,
      $$UserCategoriesTableUpdateCompanionBuilder,
      (
        UserCategoryRow,
        BaseReferences<_$AppDatabase, $UserCategoriesTable, UserCategoryRow>,
      ),
      UserCategoryRow,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      required String id,
      Value<int?> unlockedAtUtc,
      Value<int> progress,
      required int lastUpdatedAtUtc,
      Value<int> rowid,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<String> id,
      Value<int?> unlockedAtUtc,
      Value<int> progress,
      Value<int> lastUpdatedAtUtc,
      Value<int> rowid,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unlockedAtUtc => $composableBuilder(
    column: $table.unlockedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdatedAtUtc => $composableBuilder(
    column: $table.lastUpdatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unlockedAtUtc => $composableBuilder(
    column: $table.unlockedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdatedAtUtc => $composableBuilder(
    column: $table.lastUpdatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get unlockedAtUtc => $composableBuilder(
    column: $table.unlockedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get lastUpdatedAtUtc => $composableBuilder(
    column: $table.lastUpdatedAtUtc,
    builder: (column) => column,
  );
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementsTable,
          AchievementRow,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            AchievementRow,
            BaseReferences<_$AppDatabase, $AchievementsTable, AchievementRow>,
          ),
          AchievementRow,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> unlockedAtUtc = const Value.absent(),
                Value<int> progress = const Value.absent(),
                Value<int> lastUpdatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                unlockedAtUtc: unlockedAtUtc,
                progress: progress,
                lastUpdatedAtUtc: lastUpdatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> unlockedAtUtc = const Value.absent(),
                Value<int> progress = const Value.absent(),
                required int lastUpdatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                unlockedAtUtc: unlockedAtUtc,
                progress: progress,
                lastUpdatedAtUtc: lastUpdatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AchievementsTable, AchievementRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AchievementsTable,
                    AchievementRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementsTable,
      AchievementRow,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        AchievementRow,
        BaseReferences<_$AppDatabase, $AchievementsTable, AchievementRow>,
      ),
      AchievementRow,
      PrefetchHooks Function()
    >;
typedef $$TypingRecordsTableCreateCompanionBuilder =
    TypingRecordsCompanion Function({
      Value<int> id,
      required int wordsCount,
      required int correctCount,
      required int durationSeconds,
      required int wpm,
      required int accuracyPercent,
      required int score,
      required int createdAtUtc,
    });
typedef $$TypingRecordsTableUpdateCompanionBuilder =
    TypingRecordsCompanion Function({
      Value<int> id,
      Value<int> wordsCount,
      Value<int> correctCount,
      Value<int> durationSeconds,
      Value<int> wpm,
      Value<int> accuracyPercent,
      Value<int> score,
      Value<int> createdAtUtc,
    });

class $$TypingRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $TypingRecordsTable> {
  $$TypingRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordsCount => $composableBuilder(
    column: $table.wordsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wpm => $composableBuilder(
    column: $table.wpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accuracyPercent => $composableBuilder(
    column: $table.accuracyPercent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TypingRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $TypingRecordsTable> {
  $$TypingRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordsCount => $composableBuilder(
    column: $table.wordsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wpm => $composableBuilder(
    column: $table.wpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accuracyPercent => $composableBuilder(
    column: $table.accuracyPercent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TypingRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TypingRecordsTable> {
  $$TypingRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordsCount => $composableBuilder(
    column: $table.wordsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wpm =>
      $composableBuilder(column: $table.wpm, builder: (column) => column);

  GeneratedColumn<int> get accuracyPercent => $composableBuilder(
    column: $table.accuracyPercent,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );
}

class $$TypingRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TypingRecordsTable,
          TypingRecordRow,
          $$TypingRecordsTableFilterComposer,
          $$TypingRecordsTableOrderingComposer,
          $$TypingRecordsTableAnnotationComposer,
          $$TypingRecordsTableCreateCompanionBuilder,
          $$TypingRecordsTableUpdateCompanionBuilder,
          (
            TypingRecordRow,
            BaseReferences<_$AppDatabase, $TypingRecordsTable, TypingRecordRow>,
          ),
          TypingRecordRow,
          PrefetchHooks Function()
        > {
  $$TypingRecordsTableTableManager(_$AppDatabase db, $TypingRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TypingRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TypingRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TypingRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> wordsCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> wpm = const Value.absent(),
                Value<int> accuracyPercent = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
              }) => TypingRecordsCompanion(
                id: id,
                wordsCount: wordsCount,
                correctCount: correctCount,
                durationSeconds: durationSeconds,
                wpm: wpm,
                accuracyPercent: accuracyPercent,
                score: score,
                createdAtUtc: createdAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int wordsCount,
                required int correctCount,
                required int durationSeconds,
                required int wpm,
                required int accuracyPercent,
                required int score,
                required int createdAtUtc,
              }) => TypingRecordsCompanion.insert(
                id: id,
                wordsCount: wordsCount,
                correctCount: correctCount,
                durationSeconds: durationSeconds,
                wpm: wpm,
                accuracyPercent: accuracyPercent,
                score: score,
                createdAtUtc: createdAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TypingRecordsTable, TypingRecordRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $TypingRecordsTable,
                    TypingRecordRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TypingRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TypingRecordsTable,
      TypingRecordRow,
      $$TypingRecordsTableFilterComposer,
      $$TypingRecordsTableOrderingComposer,
      $$TypingRecordsTableAnnotationComposer,
      $$TypingRecordsTableCreateCompanionBuilder,
      $$TypingRecordsTableUpdateCompanionBuilder,
      (
        TypingRecordRow,
        BaseReferences<_$AppDatabase, $TypingRecordsTable, TypingRecordRow>,
      ),
      TypingRecordRow,
      PrefetchHooks Function()
    >;
typedef $$PhrasesTableCreateCompanionBuilder = PhrasesCompanion Function({
  Value<int> id,
  required String phrase,
  required String translation,
  required String category,
  required String level,
  required int createdAtUtc,
});
typedef $$PhrasesTableUpdateCompanionBuilder = PhrasesCompanion Function({
  Value<int> id,
  Value<String> phrase,
  Value<String> translation,
  Value<String> category,
  Value<String> level,
  Value<int> createdAtUtc,
});

class $$PhrasesTableFilterComposer
    extends Composer<_$AppDatabase, $PhrasesTable> {
  $$PhrasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phrase => $composableBuilder(
    column: $table.phrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhrasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PhrasesTable> {
  $$PhrasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phrase => $composableBuilder(
    column: $table.phrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhrasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhrasesTable> {
  $$PhrasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phrase =>
      $composableBuilder(column: $table.phrase, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );
}

class $$PhrasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhrasesTable,
          PhraseRow,
          $$PhrasesTableFilterComposer,
          $$PhrasesTableOrderingComposer,
          $$PhrasesTableAnnotationComposer,
          $$PhrasesTableCreateCompanionBuilder,
          $$PhrasesTableUpdateCompanionBuilder,
          (PhraseRow, BaseReferences<_$AppDatabase, $PhrasesTable, PhraseRow>),
          PhraseRow,
          PrefetchHooks Function()
        > {
  $$PhrasesTableTableManager(_$AppDatabase db, $PhrasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhrasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhrasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhrasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> phrase = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
              }) => PhrasesCompanion(
                id: id,
                phrase: phrase,
                translation: translation,
                category: category,
                level: level,
                createdAtUtc: createdAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String phrase,
                required String translation,
                required String category,
                required String level,
                required int createdAtUtc,
              }) => PhrasesCompanion.insert(
                id: id,
                phrase: phrase,
                translation: translation,
                category: category,
                level: level,
                createdAtUtc: createdAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhrasesTable, PhraseRow>(table),
                  BaseReferences<_$AppDatabase, $PhrasesTable, PhraseRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhrasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhrasesTable,
      PhraseRow,
      $$PhrasesTableFilterComposer,
      $$PhrasesTableOrderingComposer,
      $$PhrasesTableAnnotationComposer,
      $$PhrasesTableCreateCompanionBuilder,
      $$PhrasesTableUpdateCompanionBuilder,
      (PhraseRow, BaseReferences<_$AppDatabase, $PhrasesTable, PhraseRow>),
      PhraseRow,
      PrefetchHooks Function()
    >;
typedef $$StoriesTableCreateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  required String title,
  required String content,
  required String translation,
  required String level,
  required int createdAtUtc,
});
typedef $$StoriesTableUpdateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> content,
  Value<String> translation,
  Value<String> level,
  Value<int> createdAtUtc,
});

class $$StoriesTableFilterComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );
}

class $$StoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoriesTable,
          StoryRow,
          $$StoriesTableFilterComposer,
          $$StoriesTableOrderingComposer,
          $$StoriesTableAnnotationComposer,
          $$StoriesTableCreateCompanionBuilder,
          $$StoriesTableUpdateCompanionBuilder,
          (StoryRow, BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>),
          StoryRow,
          PrefetchHooks Function()
        > {
  $$StoriesTableTableManager(_$AppDatabase db, $StoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<int> createdAtUtc = const Value.absent(),
              }) => StoriesCompanion(
                id: id,
                title: title,
                content: content,
                translation: translation,
                level: level,
                createdAtUtc: createdAtUtc,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String content,
                required String translation,
                required String level,
                required int createdAtUtc,
              }) => StoriesCompanion.insert(
                id: id,
                title: title,
                content: content,
                translation: translation,
                level: level,
                createdAtUtc: createdAtUtc,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoriesTable, StoryRow>(table),
                  BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoriesTable,
      StoryRow,
      $$StoriesTableFilterComposer,
      $$StoriesTableOrderingComposer,
      $$StoriesTableAnnotationComposer,
      $$StoriesTableCreateCompanionBuilder,
      $$StoriesTableUpdateCompanionBuilder,
      (StoryRow, BaseReferences<_$AppDatabase, $StoriesTable, StoryRow>),
      StoryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$WordProgressesTableTableManager get wordProgresses =>
      $$WordProgressesTableTableManager(_db, _db.wordProgresses);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$UserSettingsTableTableTableManager get userSettingsTable =>
      $$UserSettingsTableTableTableManager(_db, _db.userSettingsTable);
  $$DailyStatsTableTableTableManager get dailyStatsTable =>
      $$DailyStatsTableTableTableManager(_db, _db.dailyStatsTable);
  $$FrozenDaysTableTableManager get frozenDays =>
      $$FrozenDaysTableTableManager(_db, _db.frozenDays);
  $$WordHintsTableTableManager get wordHints =>
      $$WordHintsTableTableManager(_db, _db.wordHints);
  $$ClozeTasksTableTableManager get clozeTasks =>
      $$ClozeTasksTableTableManager(_db, _db.clozeTasks);
  $$DailyChallengesTableTableManager get dailyChallenges =>
      $$DailyChallengesTableTableManager(_db, _db.dailyChallenges);
  $$ChallengeStreaksTableTableManager get challengeStreaks =>
      $$ChallengeStreaksTableTableManager(_db, _db.challengeStreaks);
  $$UserCategoriesTableTableManager get userCategories =>
      $$UserCategoriesTableTableManager(_db, _db.userCategories);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$TypingRecordsTableTableManager get typingRecords =>
      $$TypingRecordsTableTableManager(_db, _db.typingRecords);
  $$PhrasesTableTableManager get phrases =>
      $$PhrasesTableTableManager(_db, _db.phrases);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
}
