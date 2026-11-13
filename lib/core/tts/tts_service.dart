import 'package:stts/stts.dart';

/// Озвучивание текста.
///
/// Интерфейс нужен, чтобы экраны не зависели от плагина: в тестах
/// подставляется фейк, на устройстве — [SttsTtsService].
abstract interface class TtsService {
  /// Произносит [text].
  ///
  /// [voice] — BCP-47 (`en-US`), [speed] — 0.1..1.0. При ошибке плагина
  /// исключение пробрасывается: решение о UI принимает вызывающий.
  Future<void> speak(String text, {String? voice, double? speed});

  /// Останавливает текущее произношение.
  Future<void> stop();
}

/// Обёртка над `stts.Tts`.
///
/// Голос — BCP-47 (`en-US`). Скорость пересчитывается из шкалы приложения
/// (`0.1..1.0`, как было у `flutter_tts`) в шкалу платформы (`0.1..10.0`):
/// множитель 2.0, то есть 0.5 в настройках = 1.0 (нормальная речь).
final class SttsTtsService implements TtsService {
  /// Создаёт сервис поверх плагина.
  SttsTtsService(this._tts);

  final Tts _tts;

  /// Множитель перевода скорости приложения в rate платформы.
  static const double _rateScale = 2;

  /// Минимальный rate платформы.
  static const double _minRate = 0.1;

  /// Максимальный rate платформы.
  static const double _maxRate = 10;

  @override
  Future<void> speak(String text, {String? voice, double? speed}) async {
    await _tts.setLanguage(voice ?? 'en-US');
    final rate = ((speed ?? 0.5) * _rateScale).clamp(_minRate, _maxRate);
    await _tts.setRate(rate);
    await _tts.start(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
