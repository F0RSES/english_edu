import 'package:english_edu/domain/repositories/frozen_days_repository.dart';
import 'package:english_edu/domain/value_objects/local_date.dart';

/// In-memory frozen days repository for use-case tests.
final class FakeFrozenDaysRepository implements FrozenDaysRepository {
  /// Creates a fake seeded with [seed].
  FakeFrozenDaysRepository([Iterable<LocalDate> seed = const []])
    : _dates = {...seed};

  final Set<LocalDate> _dates;

  /// Every `add` call in order, with the reason passed by the use case.
  final List<({LocalDate date, String reason})> added = [];

  @override
  Future<Set<LocalDate>> getAll() async => {..._dates};

  @override
  Future<void> add(LocalDate date, {required String reason}) async {
    added.add((date: date, reason: reason));
    _dates.add(date);
  }

  @override
  Future<void> replaceAll(Iterable<LocalDate> dates) async {
    _dates
      ..clear()
      ..addAll(dates);
  }
}
