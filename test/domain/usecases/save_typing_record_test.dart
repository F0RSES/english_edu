import 'package:english_edu/domain/repositories/typing_record_repository.dart';
import 'package:english_edu/domain/usecases/save_typing_record.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';
import 'package:test/test.dart';

final class _FakeRecords implements TypingRecordRepository {
  final List<TypingRecord> saved = [];

  @override
  Future<TypingRecord?> getBest() async => null;

  @override
  Future<List<TypingRecord>> getTop({int limit = 10}) async => saved;

  @override
  Future<TypingRecord> save(TypingRecord record) async {
    saved.add(record);
    return record;
  }
}

SaveTypingRecord useCase(TypingRecordRepository records) =>
    SaveTypingRecord(
  records: records,
  clock: () => DateTime.utc(2024, 5, 15, 12),
);

void main() {
  test('should_compute_wpm_and_accuracy', () async {
    final records = _FakeRecords();

    final record = await useCase(records)(
      wordsCount: 10,
      correctCount: 8,
      durationSeconds: 30,
    );

    // 8 верных за 30 с = 16 слов в минуту; точность 80%.
    expect(record.wpm, 16);
    expect(record.accuracyPercent, 80);
    expect(record.score, 12);
    expect(records.saved, hasLength(1));
  });

  test('should_avoid_division_by_zero', () async {
    final records = _FakeRecords();

    final record = await useCase(records)(
      wordsCount: 10,
      correctCount: 10,
      durationSeconds: 0,
    );

    expect(record.durationSeconds, 1);
    expect(record.wpm, 600);
  });
}
