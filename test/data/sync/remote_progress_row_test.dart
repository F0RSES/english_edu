import 'package:english_edu/data/sync/remote_progress_row.dart';
import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:english_edu/domain/value_objects/word_id.dart';
import 'package:english_edu/domain/value_objects/word_status.dart';
import 'package:flutter_test/flutter_test.dart';

final _firstSeen = DateTime.utc(2026);
final DateTime _reviewed = _firstSeen.add(const Duration(days: 4));

RemoteProgressRow _row({DateTime? lastReviewedAt}) => RemoteProgressRow(
  wordId: const WordId(42),
  cardState: CardState(
    easePermille: 2600,
    intervalDays: 6,
    repetitions: 4,
    lapses: 1,
    dueAt: DateTime.utc(2026, 1, 11),
  ),
  status: WordStatus.mastered,
  firstSeenAtUtc: _firstSeen,
  lastReviewedAtUtc: lastReviewedAt,
);

void main() {
  group('toJson', () {
    test('carries the owner id required by row level security', () {
      final json = _row(lastReviewedAt: _reviewed).toJson('user-1');

      expect(json['user_id'], 'user-1');
      expect(json['word_id'], 42);
    });

    test('stores timestamps as UTC epoch milliseconds', () {
      final json = _row(lastReviewedAt: _reviewed).toJson('user-1');

      expect(json['first_seen_at_utc'], _firstSeen.millisecondsSinceEpoch);
      expect(json['last_reviewed_at_utc'], _reviewed.millisecondsSinceEpoch);
      expect(json['updated_at_utc'], _reviewed.millisecondsSinceEpoch);
    });

    test('serialises the status by name', () {
      expect(_row().toJson('user-1')['status'], 'mastered');
    });
  });

  group('fromJson', () {
    test('restores a row written by toJson', () {
      final original = _row(lastReviewedAt: _reviewed);

      final restored = RemoteProgressRow.fromJson(original.toJson('user-1'));

      expect(restored, original);
      expect(restored.firstSeenAtUtc.isUtc, isTrue);
    });

    test('keeps a missing last review as null', () {
      final restored = RemoteProgressRow.fromJson(_row().toJson('user-1'));

      expect(restored.lastReviewedAtUtc, isNull);
      expect(restored.updatedAtUtc, _firstSeen);
    });

    test('rejects an unknown status', () {
      final json = _row().toJson('user-1')..['status'] = 'archived';

      expect(
        () => RemoteProgressRow.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a missing numeric field', () {
      final json = _row().toJson('user-1')..remove('ease_permille');

      expect(
        () => RemoteProgressRow.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('toDomain', () {
    test('maps the row onto the local entity', () {
      final progress = _row(lastReviewedAt: _reviewed).toDomain();

      expect(progress.wordId, const WordId(42));
      expect(progress.status, WordStatus.mastered);
      expect(progress.cardState.repetitions, 4);
      expect(progress.firstSeenAt, _firstSeen);
      expect(progress.lastReviewedAt, _reviewed);
    });
  });
}
