import 'package:english_edu/domain/repositories/typing_record_repository.dart';
import 'package:english_edu/domain/value_objects/typing_record.dart';

/// In-memory typing record repository for tests.
final class FakeTypingRecordRepository implements TypingRecordRepository {
  /// Creates a fake with optional initial records.
  FakeTypingRecordRepository([List<TypingRecord>? initial])
    : _records = [...?initial];

  final List<TypingRecord> _records;

  @override
  Future<TypingRecord?> getBest() async =>
      _records.isEmpty ? null : _records.first;

  @override
  Future<List<TypingRecord>> getTop({int limit = 10}) async =>
      _records.take(limit).toList();

  @override
  Future<TypingRecord> save(TypingRecord record) async {
    _records.add(record);
    return record;
  }
}
