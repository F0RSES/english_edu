import 'package:english_edu/core/tts/tts_service.dart';

/// Шпион TTS: запоминает последний вызов, умеет падать по требованию.
final class FakeTtsService implements TtsService {
  /// Текст последнего вызова `speak`.
  String? lastText;

  /// Голос последнего вызова `speak`.
  String? lastVoice;

  /// Скорость последнего вызова `speak`.
  double? lastSpeed;

  /// Если true, `speak` бросает исключение.
  bool speakThrows = false;

  /// Сколько раз вызывали `stop`.
  int stopCalls = 0;

  @override
  Future<void> speak(String text, {String? voice, double? speed}) async {
    if (speakThrows) {
      throw Exception('TTS failure');
    }
    lastText = text;
    lastVoice = voice;
    lastSpeed = speed;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}
