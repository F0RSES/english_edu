import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:english_edu/data/db/app_database.dart';
import 'package:english_edu/data/repositories/drift_cloze_task_repository.dart';
import 'package:english_edu/domain/value_objects/cloze_task.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2024, 5, 15, 12);

ClozeTask _task() => ClozeTask(
  sentence: 'I ___ apples every day.',
  correctWord: 'eat',
  options: const ['eat', 'eats', 'ate', 'eating', 'eaten'],
);

Future<void> _insertWord(AppDatabase db) => db
    .into(db.words)
    .insert(
      WordsCompanion.insert(
        id: const Value(1),
        term: 'eat',
        translation: 'есть',
      ),
    );

void main() {
  late AppDatabase db;
  late DriftClozeTaskRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftClozeTaskRepository(db);
  });

  tearDown(() => db.close());

  test('round-trips a task with options', () async {
    await _insertWord(db);
    await repo.save(const WordId(1), _task(), _now);

    final loaded = await repo.getByWordId(const WordId(1));

    expect(loaded, _task());
  });

  test('invalidates a pre-v16 row without options', () async {
    await _insertWord(db);
    await db
        .into(db.clozeTasks)
        .insert(
          ClozeTasksCompanion.insert(
            wordId: const Value(1),
            sentence: 'I ___ it.',
            answer: 'eat',
            createdAtUtc: _now.millisecondsSinceEpoch,
          ),
        );

    expect(await repo.getByWordId(const WordId(1)), isNull);
  });

  test('save replaces the previous task', () async {
    await _insertWord(db);
    await repo.save(const WordId(1), _task(), _now);
    final updated = _task().copyWith(
      correctWord: 'eats',
      options: ['eats', 'eat', 'ate', 'eating', 'eaten'],
    );
    await repo.save(const WordId(1), updated, _now);

    expect(await repo.getByWordId(const WordId(1)), updated);
  });
}
