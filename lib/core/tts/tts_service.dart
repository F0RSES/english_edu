import 'package:flutter_tts/flutter_tts.dart';

/// Озвучивание текста.
///
/// Интерфейс нужен, чтобы экраны не зависели от плагина: в тестах
/// подставляется фейк, на устройстве — [FlutterTtsService].
abstract interface class TtsService {
  /// Произносит [text].
  ///
  /// [voice] — BCP-47 (`en-US`), [speed] — 0.1..1.0. При ошибке плагина
  /// исключение пробрасывается: решение о UI принимает вызывающий.
  Future<void> speak(String text, {String? voice, double? speed});

  /// Останавливает текущее произношение.
  Future<void> stop();
}

/// Обёртка над `FlutterTts`.
final class FlutterTtsService implements TtsService {
  /// Создаёт сервис поверх плагина.
  FlutterTtsService(this._tts);

  final FlutterTts _tts;

  @override
  Future<void> speak(String text, {String? voice, double? speed}) async {
    await _tts.setLanguage(voice ?? 'en-US');
    await _tts.setSpeechRate(speed ?? 0.5);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}
