import 'package:english_edu/domain/value_objects/card_state.dart';
import 'package:test/test.dart';

void main() {
  final dueAt = DateTime.utc(2024);

  group('CardState', () {
    test('initial has ease 2.5, zero counters and the given due date', () {
      final state = CardState.initial(dueAt);
      expect(state.easePermille, 2500);
      expect(state.ease, 2.5);
      expect(state.intervalDays, 0);
      expect(state.repetitions, 0);
      expect(state.lapses, 0);
      expect(state.dueAt, dueAt);
      expect(state.dueAt.isUtc, isTrue);
    });

    test('rejects ease below 1300 permille', () {
      expect(
        () => CardState(
          easePermille: 1299,
          intervalDays: 0,
          repetitions: 0,
          lapses: 0,
          dueAt: dueAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a negative interval', () {
      expect(
        () => CardState(
          easePermille: 2500,
          intervalDays: -1,
          repetitions: 0,
          lapses: 0,
          dueAt: dueAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a negative repetition count', () {
      expect(
        () => CardState(
          easePermille: 2500,
          intervalDays: 0,
          repetitions: -1,
          lapses: 0,
          dueAt: dueAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a negative lapse count', () {
      expect(
        () => CardState(
          easePermille: 2500,
          intervalDays: 0,
          repetitions: 0,
          lapses: -1,
          dueAt: dueAt,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('normalises a local due date to UTC', () {
      final local = DateTime(2024, 1, 1, 12);
      final state = CardState(
        easePermille: 2500,
        intervalDays: 1,
        repetitions: 1,
        lapses: 0,
        dueAt: local,
      );
      expect(state.dueAt.isUtc, isTrue);
      expect(
        state.dueAt.microsecondsSinceEpoch,
        local.toUtc().microsecondsSinceEpoch,
      );
    });

    test('is equal and has the same hash for identical fields', () {
      final a = CardState.initial(dueAt);
      final b = CardState.initial(dueAt);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differs by a single permille of ease', () {
      final a = CardState.initial(dueAt);
      final b = a.copyWith(easePermille: 2499);
      expect(a, isNot(equals(b)));
    });

    test('compares due dates by instant, not by zone object', () {
      final local = DateTime(2024, 1, 1, 12);
      final fromLocal = CardState(
        easePermille: 2500,
        intervalDays: 0,
        repetitions: 0,
        lapses: 0,
        dueAt: local,
      );
      final fromUtc = CardState(
        easePermille: 2500,
        intervalDays: 0,
        repetitions: 0,
        lapses: 0,
        dueAt: local.toUtc(),
      );
      expect(fromLocal, equals(fromUtc));
      expect(fromLocal.hashCode, fromUtc.hashCode);
    });

    test('copyWith replaces only the given fields', () {
      final base = CardState.initial(dueAt);
      final updated = base.copyWith(
        intervalDays: 6,
        repetitions: 2,
        dueAt: DateTime.utc(2024, 1, 7),
      );
      expect(updated.easePermille, 2500);
      expect(updated.intervalDays, 6);
      expect(updated.repetitions, 2);
      expect(updated.lapses, 0);
      expect(updated.dueAt, DateTime.utc(2024, 1, 7));
    });

    test('copyWith without arguments returns an equal state', () {
      final base = CardState.initial(dueAt);
      expect(base.copyWith(), equals(base));
    });

    test('exposes ease as a ratio', () {
      expect(CardState.initial(dueAt).ease, 2.5);
      expect(
        CardState.initial(dueAt).copyWith(easePermille: 1300).ease,
        1.3,
      );
    });
  });
}
