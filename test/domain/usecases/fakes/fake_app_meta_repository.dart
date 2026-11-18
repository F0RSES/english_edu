import 'package:english_edu/domain/repositories/app_meta_repository.dart';

/// In-memory app metadata repository for use-case tests.
final class FakeAppMetaRepository implements AppMetaRepository {
  /// Creates a fake seeded with [values].
  FakeAppMetaRepository([Map<String, String>? values]) : _values = {...?values};

  final Map<String, String> _values;

  @override
  Future<String?> getValue(String key) async => _values[key];

  @override
  Future<void> setValue(String key, String value) async {
    _values[key] = value;
  }
}
