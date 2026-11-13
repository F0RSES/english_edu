import 'package:english_edu/domain/repositories/settings_repository.dart';
import 'package:english_edu/domain/services/error_explainer.dart';

/// Объясняет ошибку в мини-игре через AI-помощника (ADR-042).
///
/// Уровень пользователя передаётся генератору отдельно и добавляется
/// в контекст, чтобы объяснение было подходящего тона и сложности. Сеть
/// используется только по явному тапу на иконку помощника.
final class ExplainError {
  /// Создаёт use case; все зависимости внедряются.
  const ExplainError({
    required ErrorExplainer explainer,
    required SettingsRepository settings,
  }) : _explainer = explainer,
       _settings = settings;

  final ErrorExplainer _explainer;
  final SettingsRepository _settings;

  /// Возвращает объяснение ошибки для игры [gameType] и контекста [context].
  ///
  /// Ошибки генератора пробрасываются без изменений: решение о показе
  /// принимает UI.
  Future<String> call({
    required String gameType,
    required String context,
  }) async {
    final settings = await _settings.get();
    // Уровень задаёт тон объяснения: A1 и B1 требуют разной глубины.
    final fullContext =
        'Уровень пользователя: ${settings.preferredLevel.label}.\n'
        'Игра: $gameType.\n'
        'Контекст ошибки: $context';
    final explanation = await _explainer.explain(
      gameType: gameType,
      context: fullContext,
      level: settings.preferredLevel.label,
    );
    return explanation;
  }
}
