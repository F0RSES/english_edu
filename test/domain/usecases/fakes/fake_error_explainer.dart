import 'package:english_edu/data/ai/ai_client.dart';
import 'package:english_edu/domain/services/error_explainer.dart';

/// In-memory error explainer for use-case and widget tests.
final class FakeErrorExplainer implements ErrorExplainer {
  /// Creates a fake returning [explanation].
  FakeErrorExplainer({this.explanation = 'Объяснение'});

  /// Text returned by [explain].
  final String explanation;

  /// When true, [explain] throws [AiException] instead of returning.
  bool throwOnExplain = false;

  /// Number of [explain] calls.
  int calls = 0;

  /// Last game type passed to [explain].
  String? lastGameType;

  /// Last context passed to [explain].
  String? lastContext;

  /// Last level passed to [explain].
  String? lastLevel;

  @override
  Future<String> explain({
    required String gameType,
    required String context,
    required String level,
  }) async {
    calls++;
    lastGameType = gameType;
    lastContext = context;
    lastLevel = level;
    if (throwOnExplain) {
      throw const AiException('fake failure');
    }
    return explanation;
  }
}
