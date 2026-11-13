import 'package:flutter/foundation.dart';

/// Логгер с уровнями.
///
/// Прямые `print`/`debugPrint` вне реализации запрещены правилами проекта:
/// весь код пишет через этот интерфейс. Sentry появится в Phase 6.
abstract interface class Logger {
  /// Отладочное сообщение.
  void debug(String message);

  /// Информационное сообщение.
  void info(String message);

  /// Предупреждение с необязательной ошибкой и стектрейсом.
  void warn(String message, [Object? error, StackTrace? stackTrace]);

  /// Ошибка: сообщение, исключение и стектрейс обязательны.
  void error(String message, Object error, StackTrace stackTrace);
}

/// Реализация по умолчанию: пишет в консоль через `debugPrint`.
final class DebugLogger implements Logger {
  /// Создаёт логгер.
  const DebugLogger();

  @override
  void debug(String message) => debugPrint('[D] $message');

  @override
  void info(String message) => debugPrint('[I] $message');

  @override
  void warn(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[W] $message ${error ?? ''}');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void error(String message, Object error, StackTrace stackTrace) {
    debugPrint('[E] $message $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
