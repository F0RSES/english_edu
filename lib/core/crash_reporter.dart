import 'package:sentry_flutter/sentry_flutter.dart';

/// Ключ контекста, под которым в отчёт уезжает место сбоя.
const _detailContextKey = 'detail';

/// Отправка сбоев во внешний сервис.
///
/// Абстракция отделяет presentation от Sentry: экраны сообщают о сбоях через
/// контракт, а нативная инициализация SDK остаётся в `main`. Так тесты виджетов
/// не поднимают платформенный канал.
abstract interface class CrashReporter {
  /// Отправляет исключение.
  ///
  /// [context] — короткая метка места сбоя (`record_review`, `import`), по ней
  /// проще фильтровать события в панели Sentry.
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  });

  /// Дополняет область (scope) произвольным контекстом.
  ///
  /// Значения должны быть сериализуемыми: персональные данные сюда передавать
  /// нельзя (ADR-016).
  Future<void> setContext(String key, Map<String, dynamic> data);
}

/// Отправка в Sentry.
final class SentryCrashReporter implements CrashReporter {
  /// Создаёт репортёр.
  const SentryCrashReporter();

  @override
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    final label = context;
    if (label == null) {
      await Sentry.captureException(error, stackTrace: stackTrace);
      return;
    }
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (sentryScope) => sentryScope.setContexts(
        _detailContextKey,
        <String, dynamic>{'context': label},
      ),
    );
  }

  @override
  Future<void> setContext(String key, Map<String, dynamic> data) async {
    await Sentry.configureScope((scope) => scope.setContexts(key, data));
  }
}

/// Заглушка: ничего не отправляет.
///
/// Используется в тестах и в сборках без DSN, чтобы код вызова не ветвился.
final class NoOpCrashReporter implements CrashReporter {
  /// Создаёт заглушку.
  const NoOpCrashReporter();

  @override
  Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {}

  @override
  Future<void> setContext(String key, Map<String, dynamic> data) async {}
}
