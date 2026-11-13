import 'package:english_edu/core/crash_reporter.dart';

/// Запоминает вызовы вместо отправки во внешний сервис.
final class FakeCrashReporter implements CrashReporter {
  /// Отправленные исключения в порядке вызовов.
  final List<({Object error, StackTrace? stackTrace, String? context})>
  captured = [];

  /// Установленные контексты в порядке вызовов.
  final List<({String key, Map<String, dynamic> data})> contexts = [];

  @override
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    captured.add((error: error, stackTrace: stackTrace, context: context));
  }

  @override
  Future<void> setContext(String key, Map<String, dynamic> data) async {
    contexts.add((key: key, data: data));
  }
}
